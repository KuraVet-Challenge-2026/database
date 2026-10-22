# KuraVet — Banco de Dados (Sprint 4)

Challenge FIAP 2026 × Clyvo Vet · Mastering Relational and Non-Relational Database · Turma **2TDSPO**

| Integrante | RM |
|---|---|
| Guilherme Macedo Martins | 562396 |
| Pedro Henrique Luiz Alves Duarte | 563405 |
| Henrique Martins Oliveira | 563620 |

Oracle (relacional) é a base transacional do KuraVet e a mesma usada pelo backend Java. A partir dela, o package `PKG_KV_EXPORT` gera um dataset JSON orientado a documentos que é importado no MongoDB.

## Arquivos de entrega (padrão da disciplina)

| Arquivo | Conteúdo |
|---|---|
| `2TDSPO_2024_CodigoSql_Guilherme_Macedo-Henrique_Martins-Pedro_Henrique_Luiz.sql` | Script único da Sprint 4 (mesmo conteúdo de `sql/00` a `05`, `07`, `90` e `99`, nessa ordem) |
| `2TDSPO_2024_Proj_BD_KuraVet.pdf` | Documentação: capa, modelos lógico e físico, código e evidências de execução |
| `export/kuravet_pets.json`, `export/kuravet_veterinarios.json` | Dataset JSON gerado a partir do banco relacional |
| `mongodb/` | Criação das coleções e importação no MongoDB |

O script único e a pasta `sql/` têm o mesmo código: o script único é para execução em uma vez (F5); a pasta `sql/` separa as etapas e é a base das migrations do backend.

## Estrutura

```
sql/
  00_drop.sql              limpeza (somente schema de testes)
  01_ddl.sql               tabelas, constraints, índices, sequences
  02_carga.sql             dados iniciais
  03_packages_spec.sql     especificação dos 5 packages
  04_packages_body.sql     corpo dos 5 packages
  05_triggers.sql          TRG_AUDITORIA_CONSULTA
  06_export_json.sql       gera export/*.json (SQLcl / SQL*Plus)
  07_blocos_anonimos.sql   blocos anônimos da Sprint 3 corrigidos
  90_demo_evidencias.sql   sucesso + exceção tratada de cada rotina (EV-01..EV-17)
  99_verificacao.sql       objetos, erros de compilação, contagens
mongodb/
  01_create.js             coleções com $jsonSchema e índices
  02_import.sh             mongoimport dos arquivos exportados
  03_queries.js            consultas e agregações de demonstração
export/                    JSONs gerados pelo banco (commitados após rodar o 06)
docs/
  2TDSPO_KuraVet_Modelos_Logico_Fisico.pdf   modelos lógico e físico (entra no PDF principal)
  modelo/                  imagens exportadas do Data Modeler
  ROTEIRO_EVIDENCIAS.md    roteiro das evidências e do vídeo
```

## Como executar

Oracle (SQL Developer → "Executar Script" F5, ou SQLcl), em um **schema de testes**:

```
00_drop → 01_ddl → 02_carga → 03_packages_spec → 04_packages_body → 05_triggers
→ 07_blocos_anonimos → 90_demo_evidencias → 99_verificacao
```

`99_verificacao.sql` deve mostrar todos os objetos `VALID` e nenhuma linha em `USER_ERRORS`.

Exportação JSON — pelo **SQLcl**, na raiz do repositório (o F5 do SQL Developer grava o comando dentro do arquivo):

```
sql RMxxxxxx/senha@//oracle.fiap.com.br:1521/ORCL @sql/06_export_json.sql
```

MongoDB (Atlas ou local):

```
export MONGO_URI="mongodb+srv://usuario:senha@cluster.xxxxx.mongodb.net"
bash mongodb/02_import.sh
mongosh "$MONGO_URI" --file mongodb/03_queries.js
```

## Packages

| Package | Rotinas | Uso |
|---|---|---|
| `PKG_KV_UTIL` | `FN_MONTA_JSON`, `FN_CALCULA_IDADE_PET`, `FN_CATEGORIA_ETARIA`, `PRC_REGISTRAR_ERRO`, `PRC_LANCAR_ERRO`, `PRC_TRATAR_INESPERADO` | utilitários, catálogo de erros, log |
| `PKG_KV_AUDITORIA` | `FN_SERIALIZAR_CONSULTA`, `PRC_REGISTRAR` | chamado pela trigger |
| `PKG_KV_CARGA` | `PRC_CARGA_TUTOR`, `PRC_CARGA_VETERINARIO`, `PRC_CARGA_PET`, `PRC_CARGA_CONSULTA`, `PRC_REGISTRAR_DIAGNOSTICO`, `PRC_CARGA_PAGAMENTO` | chamado pelo backend (retornam o ID gerado; não fazem COMMIT) |
| `PKG_KV_RELATORIO` | `PRC_LISTAR_CONSULTAS_JSON`, `PRC_SUBTOTAIS_PAGAMENTO` (console) · `PRC_CONSULTAS_TUTOR`, `PRC_FATURAMENTO_CLINICA_TIPO` (SYS_REFCURSOR) | relatórios |
| `PKG_KV_EXPORT` | `FN_DOC_PET`, `FN_DOC_VETERINARIO`, `FN_EXPORTAR_PETS`, `FN_EXPORTAR_VETERINARIOS` | dataset JSON para o MongoDB |

Triggers não podem ficar dentro de packages no Oracle; `TRG_AUDITORIA_CONSULTA` apenas dispara e delega a regra para `PKG_KV_AUDITORIA`.

### Tratamento de exceções

Cada handler corresponde a uma situação possível na rotina. As rotinas usadas pela aplicação gravam o erro em `LOG_ERRO_CARGA` (transação autônoma, sobrevive ao rollback) e propagam `RAISE_APPLICATION_ERROR` com código do catálogo. Os relatórios de console registram e exibem o aviso sem propagar.

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

| Feedback | Correção |
|---|---|
| Procedimento 1: melhorar verificação de ausência de resultados | `PRC_LISTAR_CONSULTAS_JSON` conta as linhas percorridas no próprio cursor e aceita filtro por tutor; tutor inexistente e tutor sem consultas são tratados (EV-04). |
| Procedimento 1: exceções só para situações possíveis | Removidos `TOO_MANY_ROWS` e handlers sem causa; restaram tutor inexistente, sem dados e inesperado. |
| Procedimento 2: consolidar por clínica + tipo com o acumulador declarado | `v_subtotal_tipo` agora acumula cada combinação clínica + tipo (uma linha por combinação), com quebra manual em dois níveis (EV-05). |
| Procedimento 2: formato das linhas Sub Total / Total Geral | Colunas de largura fixa, valores alinhados em formato brasileiro, "Sub Total" por clínica e "Total Geral" ao final. |
| `FN_MONTA_JSON`: caracteres especiais | Escape de `"`, `\`, quebra de linha, CR, TAB e demais caracteres de controle; nulos viram `null` (EV-01). |
| `FN_CALCULA_IDADE_PET`: trocar `TOO_MANY_ROWS` | Substituído pela validação de data de nascimento no futuro (EV-02c). |
| Trigger: incluir DIAGNOSTICO em OLD/NEW | OLD/NEW em JSON com todos os campos, inclusive DIAGNOSTICO (EV-14e). |
| Documentação: 1 exceção tratada por função/procedimento | `90_demo_evidencias.sql` e `docs/ROTEIRO_EVIDENCIAS.md`: cada rotina com sucesso e exceção. |

## Modelagem MongoDB

Coleção **`pets`**: um documento por pet com o tutor resumido embutido e o histórico de consultas embutido (cada consulta com o veterinário resumido e os pagamentos). É a leitura principal do app ("meu pet e seu histórico"), feita em uma única consulta, sem joins. O histórico de um pet é limitado, então o array não cresce sem controle.

Coleção **`veterinarios`**: cadastro completo com contato e estatísticas. Os pets guardam só um resumo do veterinário (padrão *extended reference*); o `$lookup` da Q6 liga as duas coleções.

Datas são exportadas como Extended JSON (`{"$date": ...}`) e chegam ao MongoDB como `Date`. O `$jsonSchema` valida campos obrigatórios, enums de status/sexo/tipo de pagamento e valores positivos.

## Integração com o backend Java

O backend (`java-advanced`) usa o schema **RM562396**, criado pelo Flyway. Por isso:

- `00_drop`, `01_ddl` e `02_carga` deste repositório rodam **somente em outro schema** (testes/correção). Rodar `01_ddl` no RM562396 cria tabelas com o mesmo nome das do Flyway e quebra o `validate`.
- No RM562396 entram, como migrations do Java: **V8** = tabelas de apoio (`FATO_PAGAMENTO`, `AUDITORIA_LOG`, `LOG_ERRO_CARGA`, sequences e colunas que faltarem) e **V9** = packages + trigger (`03`, `04`, `05`, ajustados aos nomes e tipos reais das tabelas do Java).
- O backend chama as procedures de `PKG_KV_CARGA`, lê os cursores de `PKG_KV_RELATORIO` e pode expor `PKG_KV_EXPORT.FN_EXPORTAR_PETS` em um endpoint de exportação.
- Erros `ORA-200xx` são mapeados para HTTP: -20003/-20005/-20007/-20009 → 404, -20014 → 409, demais de negócio → 422, -20099 → 500.
