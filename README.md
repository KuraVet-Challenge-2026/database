# Projeto KuraVet — Banco de Dados Relacional e PL/SQL

**Disciplina:** Mastering Relational and Non-Relational Database  
**Turma:** 2TDSPO  

---

## 👥 Integrantes da Equipe
* **Guilherme Macedo Martins** — RM 562396
* **Henrique Martins Oliveira** — RM 563620
* **Pedro Henrique Luiz Alves Duarte** — RM 563405

---

## 📁 Arquivos do Projeto

| Arquivo | Conteúdo |
| :--- | :--- |
| `2TDSPO_2024_CodigoSql_Integrantes.sql` | Script único contendo todo o DDL, carga de dados, procedures, funções, trigger e blocos de demonstração. |
| `2TDSPO_2024_Proj_BD.pdf / .docx` | Documentação técnica completa (capa, modelo descritivo, DER/MER, código comentado e evidências de execução). |

---

## 🐾 Visão Geral do Projeto

O **KuraVet** é uma plataforma de saúde preventiva contínua para pets. O banco de dados centraliza o cadastro de tutores, pets e veterinários, o histórico de consultas e os pagamentos realizados em cada clínica, funcionando como a fonte da verdade (*single source of truth*) para as APIs de consumo (Java/Spring e .NET). O modelo é relacional, normalizado até a 3ª Forma Normal (3FN), e toda a lógica de negócio crítica — validação de dados, geração de relatórios e auditoria — é implementada em PL/SQL no próprio banco.

---

## 🗄️ Estrutura do Banco de Dados (Tabelas)

O modelo relacional é composto pelas seguintes tabelas:

* **TUTOR**: Dados cadastrais dos tutores responsáveis pelos pets (nome, CPF, telefone, e-mail, endereço, data de cadastro). O CPF é `UNIQUE`.
* **VETERINARIO**: Cadastro dos profissionais veterinários (nome, CRMV, especialidade, telefone, e-mail). O CRMV é `UNIQUE`.
* **PET**: Animais cadastrados, cada um vinculado a um único tutor (FK para `TUTOR`). Guarda espécie, raça, data de nascimento e sexo (`CHECK` restrito a `'M'`/`'F'`).
* **CONSULTA**: Histórico clínico: liga um `PET` a um `VETERINARIO`, com data, tipo de consulta, diagnóstico e status (`CHECK` restrito a `AGENDADA`/`REALIZADA`/`CANCELADA`).
* **FATO_PAGAMENTO**: Tabela de fato financeira, vinculada a cada `CONSULTA`. Contém as colunas categóricas `CLINICA` e `TIPO_PAGAMENTO` e a coluna numérica `VALOR`, usadas nos relatórios de sumarização.
* **AUDITORIA_LOG**: Tabela de auditoria alimentada automaticamente pela trigger `TRG_AUDITORIA_CONSULTA`, registrando toda alteração DML em `CONSULTA`.
* **LOG_ERRO_CARGA**: Tabela de log de erros, alimentada pelas procedures de carga sempre que uma regra de negócio ou restrição de integridade é violada.

> Todas as tabelas foram carregadas com **10 registros reais** e coerentes entre si (acima do mínimo de 5 exigido), respeitando rigorosamente as chaves estrangeiras.

---

## ⚙️ Funcionalidades e Regras de Negócio (PL/SQL)

O script principal implementa um conjunto robusto de blocos de PL/SQL. Todos os blocos nomeados e anônimos contam com no mínimo **3 cláusulas `EXCEPTION WHEN` distintas** (sempre incluindo `WHEN OTHERS`).

### Funções
* `FN_MONTA_JSON`: Converte dados relacionais em uma string JSON, montada manualmente por concatenação de texto, sem o uso de funções nativas do Oracle (`TO_JSON`, `JSON_OBJECT`, etc.).
* `FN_CALCULA_IDADE_PET`: Regra de negócio que calcula a idade exata de um pet em anos e meses a partir da data de nascimento.

### Procedures de Consulta e Relatório
* `PROC_LISTAR_CONSULTAS_JSON`: Realiza `JOIN` entre `CONSULTA`, `PET`, `TUTOR` e `VETERINARIO` e exibe cada linha convertida em JSON pela função `FN_MONTA_JSON`.
* `PROC_SUBTOTAIS_PAGAMENTO`: Lê `FATO_PAGAMENTO` e calcula, de forma 100% manual (sem `ROLLUP`/`CUBE`/`GROUPING SETS`), os subtotais por clínica e o total geral.

### Procedures de Carga de Dados (Parametrizadas)
Uma procedure por tabela, recebendo os dados exclusivamente por parâmetros (sem *hard-code*). Cada uma valida regras de negócio antes do `INSERT` e registra eventuais falhas na tabela `LOG_ERRO_CARGA`:

| Procedure | Regra de Negócio Validada | Exceção Customizada |
| :--- | :--- | :--- |
| `PRC_CARGA_TUTOR` | CPF obrigatório, mínimo 11 dígitos | `e_cpf_invalido` |
| `PRC_CARGA_VETERINARIO` | CRMV obrigatório, mínimo 5 caracteres | `e_crmv_invalido` |
| `PRC_CARGA_PET` | Tutor referenciado deve existir; data de nascimento não pode ser futura | `e_tutor_inexistente`, `e_data_nasc_futura` |
| `PRC_CARGA_CONSULTA` | Pet referenciado deve existir; status deve pertencer ao domínio válido | `e_pet_inexistente`, `e_status_invalido` |
| `PRC_CARGA_PAGAMENTO` | Consulta referenciada deve existir; valor deve ser positivo | `e_consulta_inexiste`, `e_valor_invalido` |

*As chaves primárias dessas cargas são geradas por sequences dedicadas (`SEQ_KV_TUTOR`, `SEQ_KV_VETERINARIO`, `SEQ_KV_PET`, `SEQ_KV_CONSULTA`, `SEQ_KV_PAGAMENTO`), iniciando em 100 para evitar conflitos com a carga inicial.*

### Trigger de Auditoria
* `TRG_AUDITORIA_CONSULTA`: Disparada `AFTER INSERT OR UPDATE OR DELETE` em `CONSULTA`, `FOR EACH ROW`. Grava em `AUDITORIA_LOG` o usuário (`USER`), a operação, a data/hora (`SYSDATE`) e os valores `:OLD` e `:NEW` concatenados. Conta com tratamento de exceção defensivo (`VALUE_ERROR`, `DUP_VAL_ON_INDEX`, `OTHERS`) que relança o erro (`RAISE`) para nunca mascarar falhas de auditoria.

---

## 📊 Relatórios e Consultas Analíticas

* **Bloco Anônimo 1:** Junta `TUTOR`, `PET`, `CONSULTA` e `VETERINARIO` para contar consultas por tutor/veterinário, e junta `PET`, `CONSULTA` e `FATO_PAGAMENTO` para somar o faturamento por espécie e clínica (`JOIN` + `GROUP BY` + `ORDER BY`).
* **Bloco Anônimo 2:** Junta `VETERINARIO`, `CONSULTA`, `PET` e `TUTOR` para contar diagnósticos por veterinário e tipo de consulta.
* **Bloco Valor Atual/Anterior/Próximo:** Lê `FATO_PAGAMENTO` e exibe, para cada linha, o valor atual, o valor da linha anterior e o valor da próxima linha (`'Vazio'` quando inexistente), utilizando coleções PL/SQL em memória.
* **Relatório 1 (Classificação Etária dos Pets):** Cursor explícito + estrutura condicional (`IF/ELSIF`) que classifica cada pet como *Filhote*, *Adulto* ou *Idoso*.
* **Relatório 2 (Triagem por Status da Consulta):** Cursor explícito + decisão que recomenda uma ação operacional (*lembrete*, *verificação de cancelamento*, *arquivamento*) conforme o status.
* **Relatório 3 (Classificação de Fidelidade do Tutor):** Cursor explícito + decisão que categoriza tutores em *Cliente Ouro* (2+ pets), *Cliente Prata* (1 pet) ou *Sem pets*.
* **Relatório 4 (Sumarização de Pagamentos):** Cursor explícito que lista todos os pagamentos, sumariza os subtotais por clínica e apresenta o total geral com controle manual de quebra de grupo.

---

## 🚀 Como Executar

1. Utilize um ambiente Oracle Database compatível (SQL Developer, SQL*Plus ou Oracle Live SQL).
2. Ative a exibição de saída no terminal antes de rodar o script:
   ```sql
   SET SERVEROUTPUT ON;
   SET LINESIZE 200;
