# KuraVet — Banco de Dados (Sprint 4)

Challenge FIAP 2026 × Clyvo Vet · Mastering Relational and Non-Relational Database · Turma **2TDSPO**

| Integrante | RM |
|---|---|
| Pedro Henrique Luiz Alves Duarte | 563405 |
| Henrique Martins Oliveira | 563620 |
| Guilherme Macedo Martins | 562396 |

O Oracle é a base relacional do KuraVet e a mesma usada pelo backend Java. A partir dela, o package `PKG_KV_EXPORT` gera o dataset JSON que é importado no MongoDB.

## Para avaliar

Abra **`2TDSPO_2026_CodigoSql_Guilherme_Macedo-Henrique_Martins-Pedro_Henrique_Luiz.sql`** no SQL Developer e execute com **Run Script (F5)**. O script é reexecutável (a Parte 1 recria tudo do zero) e termina com a verificação: todos os objetos `VALID` e nenhum erro de compilação.

## Entregáveis

| # | Entregável | Arquivo |
|---|---|---|
| 1 | Modelos lógico e físico (PDF) + codificação SQL corrigida | `2TDSPO_2026_Modelos_Logico_Fisico_KuraVet.pdf` · `2TDSPO_2026_CodigoSql_...sql` (Partes 1, 2, 3 e 7) |
| 2 | Procedimentos, funções e trigger empacotados, com tratamento de exceções | `2TDSPO_2026_CodigoSql_...sql` (Partes 4, 5 e 6; evidências na Parte 9) |
| 3 | Arquivo JSON gerado a partir do banco relacional | `export/kuravet_pets.json` · `export/kuravet_veterinarios.json` (gerados por `sql/06_export_json.sql`; também visíveis na Parte 8 do script) |
| 4 | Estrutura MongoDB: criação e importação | `mongodb/01_create.js` · `mongodb/02_import.sh` · `mongodb/03_queries.js` |
| 5 | Vídeo narrado | <LINK DO YOUTUBE> |

## Estrutura

```
2TDSPO_2026_CodigoSql_...sql              script único (executar com F5)
2TDSPO_2026_Modelos_Logico_Fisico_KuraVet.pdf
sql/06_export_json.sql                    gera export/*.json (SQLcl)
export/                                   dataset JSON gerado pelo banco
mongodb/01_create.js                      coleções com $jsonSchema e índices
mongodb/02_import.sh                      criação + mongoimport + conferência
mongodb/03_queries.js                     consultas e agregações de demonstração
```

### Partes do script único

| Parte | Conteúdo |
|---|---|
| 1 | Limpeza do schema (torna o script reexecutável) |
| 2 | DDL corrigido: tabelas, constraints, índices, sequences |
| 3 | Carga inicial |
| 4 e 5 | Packages: especificação e corpo |
| 6 | Trigger de auditoria |
| 7 | Blocos anônimos da Sprint 3 corrigidos |
| 8 | JSON gerado a partir do banco relacional |
| 9 | Evidências EV-01 a EV-17: sucesso e exceção tratada de cada função e procedimento |
| 10 | Verificação final |

## Packages

| Package | Rotinas | Uso |
|---|---|---|
| `PKG_KV_UTIL` | `FN_MONTA_JSON`, `FN_CALCULA_IDADE_PET`, `FN_CATEGORIA_ETARIA`, `PRC_REGISTRAR_ERRO`, `PRC_LANCAR_ERRO`, `PRC_TRATAR_INESPERADO` | utilitários, catálogo de erros, log |
| `PKG_KV_AUDITORIA` | `FN_SERIALIZAR_CONSULTA`, `PRC_REGISTRAR` | chamado pela trigger |
| `PKG_KV_CARGA` | `PRC_CARGA_TUTOR`, `PRC_CARGA_VETERINARIO`, `PRC_CARGA_PET`, `PRC_CARGA_CONSULTA`, `PRC_REGISTRAR_DIAGNOSTICO`, `PRC_CARGA_PAGAMENTO` | chamado pelo backend (retornam o ID gerado; não fazem COMMIT) |
| `PKG_KV_RELATORIO` | `PRC_LISTAR_CONSULTAS_JSON`, `PRC_SUBTOTAIS_PAGAMENTO` (console) · `PRC_CONSULTAS_TUTOR`, `PRC_FATURAMENTO_CLINICA_TIPO` (SYS_REFCURSOR) | relatórios |
| `PKG_KV_EXPORT` | `FN_DOC_PET`, `FN_DOC_VETERINARIO`, `FN_EXPORTAR_PETS`, `FN_EXPORTAR_VETERINARIOS` | dataset JSON para o MongoDB |

No Oracle, triggers não podem ser declaradas dentro de packages: a `TRG_AUDITORIA_CONSULTA` apenas dispara e toda a regra fica no `PKG_KV_AUDITORIA`.

### Tratamento de exceções

Cada handler corresponde a uma situação possível na rotina. As rotinas usadas pela aplicação gravam o erro em `LOG_ERRO_CARGA` (transação autônoma, sobrevive ao rollback) e propagam `RAISE_APPLICATION_ERROR` com o código do catálogo. Os relatórios de console registram e exibem o aviso sem propagar.

| Código | Exceção (`PKG_KV_UTIL`) | Situação |
|---|---|---|
| -20001 | `e_cpf_invalido` | CPF sem 11 dígitos |
| -20002 | `e_crmv_invalido` | CRMV nulo ou curto |
| -20003 | `e_tutor_inexistente` | tutor não existe |
| -20004 | `e_data_invalida` | data futura / período invertido |
| -20005 | `e_pet_inexistente` | pet não existe |
| -20006 | `e_status_invalido` | status fora do fluxo |
| -20007 | `e_consulta_inexistente` | consulta não existe |
| -20008 | `e_valor_invalido` | valor ≤ 0 |
| -20009 | `e_vet_inexistente` | veterinário não existe |
| -20010 | `e_parametro_invalido` | parâmetro obrigatório nulo ou inválido |
| -20011 | `e_consulta_nao_realizada` | pagamento de consulta não realizada |
| -20012 | `e_transicao_invalida` | diagnóstico fora de consulta AGENDADA |
| -20013 | `e_sem_dados` | filtro sem resultados |
| -20014 | `e_registro_duplicado` | CPF/CRMV já cadastrado |
| -20015 | `e_operacao_invalida` | operação de auditoria inválida |
| -20016 | `e_json_excede` | JSON maior que 4000 caracteres |
| -20099 | `e_inesperado` | erro não previsto (mensagem original registrada) |

## Correções do feedback da Sprint 3

| Feedback | Correção | Evidência |
|---|---|---|
| Procedimento 1: verificação de ausência de resultados e exceções possíveis | `PRC_LISTAR_CONSULTAS_JSON` conta as linhas do próprio cursor, aceita filtro por tutor e trata tutor inexistente e tutor sem consultas; `TOO_MANY_ROWS` removido | EV-04 |
| Procedimento 2: consolidar por clínica + tipo com o acumulador declarado | `v_subtotal_tipo` acumula cada combinação clínica + tipo (uma linha por combinação), com "Sub Total" por clínica e "Total Geral" | EV-05 |
| `FN_MONTA_JSON`: caracteres especiais | Escape de `"`, `\`, quebra de linha, CR, TAB e demais caracteres de controle | EV-01 |
| `FN_CALCULA_IDADE_PET`: trocar `TOO_MANY_ROWS` | Validação de data de nascimento no futuro | EV-02c |
| Trigger: incluir DIAGNOSTICO em OLD/NEW | OLD/NEW em JSON com todos os campos, inclusive DIAGNOSTICO | EV-14e |
| Documentação: uma exceção tratada por função/procedimento | Parte 9 do script: sucesso e exceção de cada rotina | EV-01 a EV-17 |

## Exportação JSON

Pelo **SQLcl** (vem com o SQL Developer, em `sqldeveloper/bin/sql`), na raiz do repositório:

```
sql USUARIO/SENHA@//oracle.fiap.com.br:1521/ORCL @sql/06_export_json.sql
```

O F5 do SQL Developer grava o texto do comando dentro do arquivo e o JSON fica inválido; por isso o export usa o SQLcl.

## MongoDB

```
export MONGO_URI="mongodb+srv://usuario:senha@cluster.xxxxx.mongodb.net"
bash mongodb/02_import.sh
mongosh "$MONGO_URI" --file mongodb/03_queries.js
```

Coleção **`pets`**: um documento por pet com o tutor resumido embutido e o histórico de consultas embutido (cada consulta com o veterinário resumido e os pagamentos). É a leitura principal do app ("meu pet e seu histórico"), feita em uma única consulta, sem joins.

Coleção **`veterinarios`**: cadastro completo com contato e estatísticas. Os pets guardam só um resumo do veterinário (padrão *extended reference*); o `$lookup` da consulta Q6 liga as duas coleções.

Datas são exportadas como Extended JSON (`{"$date": ...}`) e chegam ao MongoDB como `Date`. O `$jsonSchema` valida campos obrigatórios, enums de status, sexo e tipo de pagamento e valores positivos.

## Integração com o backend Java

O backend (`java-advanced`) usa o schema **RM563620**, criado pelo Flyway. As tabelas de apoio, os packages e a trigger deste repositório entram nesse schema como migrations do Java (V8 e V9), e o backend chama as procedures do `PKG_KV_CARGA` e os cursores do `PKG_KV_RELATORIO`. O script único deste repositório roda em um schema separado (RM562396), porque a Parte 1 recria as tabelas.

Erros `ORA-200xx` são mapeados para HTTP: -20003/-20005/-20007/-20009 → 404, -20014 → 409, demais de negócio → 422, -20099 → 500.
