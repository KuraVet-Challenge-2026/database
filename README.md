# Global Solution: Projeto KuraVet - Banco de Dados

## Disciplina
**Mastering Relational and Non-Relational Database**

## Integrantes da Equipe
- Guilherme Macedo Martins - RM 562396
- Henrique Martins Oliveira - RM 563620
- Pedro Henrique Luiz Alves Duarte - RM 563405
- Turma: 2TDSPO

## Visão Geral do Projeto
O banco de dados **KuraVet** foi desenhado e implementado para suportar as operações de uma clínica veterinária moderna. O sistema gerencia informações vitais de tutores, pets, prontuários clínicos (eventos e consultas) e um histórico de check-in (CareBridge) focado na vitalidade e acompanhamento contínuo dos animais. Além disso, o banco possui um sistema nativo de logs para rastreabilidade de erros sistêmicos.

## Estrutura do Banco de Dados (Tabelas)
O modelo relacional é composto pelas seguintes tabelas principais:
1. **`tbl_tutor`**: Armazena os dados dos clientes (nome, CPF, e-mail, telefone e data de cadastro). Possui restrições de unicidade para CPF e e-mail.
2. **`tbl_pet`**: Registra os pacientes (pets) com vínculo direto ao seu tutor. Guarda informações como espécie, raça, data de nascimento e o importante **Score de Vitalidade** (0 a 100).
3. **`tbl_evento_consulta`**: Histórico clínico do pet. Registra vacinas, cirurgias, exames e check-ups, vinculando o evento ao veterinário responsável.
4. **`tbl_checkin_historico`**: Módulo CareBridge que armazena os check-ins diários ou periódicos dos pets, contendo o status de vitalidade reportado, observações do tutor e link para foto.
5. **`tbl_registro_logs`**: Tabela de auditoria utilizada pelos blocos PL/SQL para registrar qualquer falha, violação de integridade ou erro de regra de negócio (Exceptions) durante operações de DML.

## Funcionalidades e Regras de Negócio (PL/SQL)
O script SQL fornecido (`KuraVet.sql`) não apenas cria a estrutura DDL, mas implementa regras de negócio robustas usando **blocos anônimos PL/SQL** com tratamento avançado de exceções:

- **Validação de Tutor (`e_cpf_curto`)**: Impede a inserção de tutores com CPF contendo menos de 11 dígitos.
- **Validação de Pet (`e_score_inv`)**: Garante que o score de vitalidade inicial esteja estritamente entre 0 e 100.
- **Validação de Consultas (`e_dt_futura`)**: Bloqueia o registro de eventos/consultas com datas projetadas no futuro.
- **Validação de Check-in (`e_status_nulo`)**: Obriga o preenchimento do status de vitalidade durante o check-in.
*Observação: Qualquer falha nestas validações gera uma inserção automática na `tbl_registro_logs`.*

## Relatórios e Consultas Analíticas
O sistema conta com rotinas de extração de dados para apoio à tomada de decisão:

1. **Engajamento Cruzado**: Relaciona tutores, pets e contabiliza o engajamento através da quantidade de eventos e check-ins realizados.
2. **Análise de Status Pós-Evento**: Agrupa a volumetria de pets por espécie, tipo de evento e o status de vitalidade atual.
3. **Alerta de Score de Vitalidade**: Avalia o score de cada pet e gera alertas dinâmicos (Ex: "Excelente", "Bom" ou "ALERTA - Agendar Consulta!").
4. **Triagem de Urgência (CareBridge)**: Analisa o texto do status do check-in e recomenda ações clínicas imediatas caso o pet apresente "Apatia" ou "Com dor".
5. **Classificação de Fidelidade**: Categoriza os tutores em "Cliente OURO" ou "Cliente PRATA" com base na quantidade de pets vinculados.

## Como Executar
1. Certifique-se de estar utilizando um ambiente **Oracle Database** (SQL*Plus, SQL Developer ou Oracle Live SQL).
2. O script deve ser rodado com `SET SERVEROUTPUT ON` ativado para visualização dos relatórios.
3. Execute o script `KuraVet.sql`. Ele fará o provisionamento completo (DDL) e permitirá a inserção e teste das regras de negócio (PL/SQL).
