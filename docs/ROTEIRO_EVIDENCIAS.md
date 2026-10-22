# Roteiro de evidências — Sprint 4 (Banco)

Rodar `sql/90_demo_evidencias.sql` em base recém-criada (00 → 05) e tirar **um print por linha** desta tabela. No PDF de evidências, cada print vai com: nome da rotina, cenário, comando executado e saída. Não deixar nenhum espaço "pendente".

| EV | Rotina | Cenário | Saída esperada |
|---|---|---|---|
| 01a | `PKG_KV_UTIL.FN_MONTA_JSON` | sucesso com aspas, `\`, quebra de linha e TAB | JSON com `\"`, `\\`, `\n`, `\t` |
| 01b | idem | ID nulo | `ORA-20010` |
| 01c | idem | JSON > 4000 após escape | `ORA-20016` |
| 02a | `PKG_KV_UTIL.FN_CALCULA_IDADE_PET` | pets 1 e 11 | "x ano(s) e y mes(es)" |
| 02b | idem | pet 9999 | `ORA-20005` |
| 02c | idem | nascimento no futuro (substitui TOO_MANY_ROWS) | `ORA-20004` |
| 03a | `PKG_KV_UTIL.FN_CATEGORIA_ETARIA` | 3 datas | Filhote / Adulto / Idoso |
| 03b/c | idem | data futura / nula | `ORA-20004` / `ORA-20010` |
| 04a/b | `PKG_KV_RELATORIO.PRC_LISTAR_CONSULTAS_JSON` | todas / tutor 1 | JSONs; consultas 10 e 12 escapadas |
| 04c | idem | tutor 9999 | AVISO tutor não encontrado |
| 04d | idem | tutor 11 (sem consultas) | AVISO nenhuma consulta |
| 05a | `PKG_KV_RELATORIO.PRC_SUBTOTAIS_PAGAMENTO` | todas as clínicas | Alphaville 825,00 · Moema 770,00 · Pinheiros 805,00 · Total Geral 2.400,00 |
| 05b | idem | só KuraVet Moema | Sub Total 770,00 |
| 05c | idem | KuraVet Centro | AVISO nenhum pagamento |
| 06a | `PKG_KV_RELATORIO.PRC_CONSULTAS_TUTOR` | tutor 1 (PRINT rc) | 3 consultas com idade e valor pago |
| 06b/c | idem | tutor 9999 / NULL | `ORA-20003` / `ORA-20010` |
| 07a | `PKG_KV_RELATORIO.PRC_FATURAMENTO_CLINICA_TIPO` | 2025–2026 | detalhe, SUBTOTAL e TOTAL GERAL |
| 07b/c | idem | período invertido / 2020 | `ORA-20004` / `ORA-20013` |
| 08a | `PKG_KV_CARGA.PRC_CARGA_TUTOR` | sucesso | ID ≥ 100, CPF normalizado |
| 08b/c | idem | CPF "123" / CPF duplicado | `ORA-20001` / `ORA-20014` |
| 09a | `PKG_KV_CARGA.PRC_CARGA_VETERINARIO` | sucesso | ID ≥ 100 |
| 09b/c | idem | CRMV inválido / duplicado | `ORA-20002` / `ORA-20014` |
| 10a | `PKG_KV_CARGA.PRC_CARGA_PET` | sucesso | ID ≥ 100 |
| 10b/c | idem | tutor 9999 / nascimento futuro | `ORA-20003` / `ORA-20004` |
| 11a | `PKG_KV_CARGA.PRC_CARGA_CONSULTA` | AGENDADA | ID ≥ 100 |
| 11b/c/d | idem | status EM_ANDAMENTO / vet 9999 / RECUSADA sem motivo | `ORA-20006` / `ORA-20009` / `ORA-20010` |
| 12a | `PKG_KV_CARGA.PRC_REGISTRAR_DIAGNOSTICO` | AGENDADA → REALIZADA | sucesso |
| 12b/c | idem | já REALIZADA / consulta 99999 | `ORA-20012` / `ORA-20007` |
| 13a | `PKG_KV_CARGA.PRC_CARGA_PAGAMENTO` | sucesso | ID ≥ 100 |
| 13b/c | idem | consulta AGENDADA / valor -50 | `ORA-20011` / `ORA-20008` |
| 13d | SELECT | registros inseridos pelas procedures | tutor → pet → consulta → pagamento |
| 14a/b | `PKG_KV_AUDITORIA.FN_SERIALIZAR_CONSULTA` | sucesso / ID nulo | JSON com diagnostico / `ORA-20010` |
| 14c/d | `PKG_KV_AUDITORIA.PRC_REGISTRAR` | MERGE / UPDATE sem OLD | `ORA-20015` / `ORA-20010` |
| 14e | `TRG_AUDITORIA_CONSULTA` | INSERT, UPDATE, UPDATE, DELETE | DIAG_OLD e DIAG_NEW preenchidos |
| 15a/b | `PKG_KV_EXPORT.FN_DOC_PET` / `FN_DOC_VETERINARIO` | pet 1 / vet 3 | documentos JSON |
| 15c/d | idem | pet 999 / vet 999 | `ORA-20005` / `ORA-20009` |
| 15e/f | `PKG_KV_EXPORT.FN_EXPORTAR_PETS` | todos / Papagaio | tamanho gerado / `ORA-20013` |
| 15g/h | `PKG_KV_EXPORT.FN_EXPORTAR_VETERINARIOS` | todos / Astrologia | tamanho gerado / `ORA-20013` |
| 17 | `PKG_KV_UTIL.PRC_TRATAR_INESPERADO` → `PRC_LANCAR_ERRO` → `PRC_REGISTRAR_ERRO` | nome do tutor com 150 caracteres (ORA-12899 não previsto) | `ORA-20099` com a mensagem original |
| 16 | `LOG_ERRO_CARGA` | SELECT final (roda por último) | uma linha por exceção acima, inclusive a ORA-12899 original |

`PRC_REGISTRAR_ERRO`, `PRC_LANCAR_ERRO` e `PRC_TRATAR_INESPERADO` têm evidência própria na EV-17 (erro inesperado convertido em -20099 e registrado) e na EV-16 (todas as exceções gravadas no log mesmo após ROLLBACK).

A trigger `TRG_AUDITORIA_CONSULTA` só tem o handler `OTHERS` (registra e bloqueia o DML); a evidência dela é o funcionamento normal na EV-14e.

## Roteiro do vídeo narrado (até ~10 min)

1. Apresentação rápida do modelo (PDF lógico/físico) e dos 5 packages.
2. **Backend Java chamando as procedures**: cadastrar tutor/pet/consulta pelo app ou Swagger → mostrar no SQL Developer o `SELECT` com a linha nova e a linha em `AUDITORIA_LOG`.
3. Uma exceção pela aplicação (ex.: CPF duplicado) → resposta HTTP de erro + linha em `LOG_ERRO_CARGA`.
4. Relatórios: `PRC_SUBTOTAIS_PAGAMENTO` e `PRC_CONSULTAS_TUTOR`.
5. Export JSON: rodar `06_export_json.sql` (ou endpoint do backend) e abrir `export/kuravet_pets.json`.
6. MongoDB: `02_import.sh` (criação + import), `03_queries.js` (Q3 com o mesmo total do Oracle, Q7 validador rejeitando documento).
