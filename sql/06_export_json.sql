-- =============================================================================
-- KuraVet - Challenge FIAP 2026 x Clyvo Vet
-- Disciplina: Mastering Relational and Non-Relational Database - Sprint 4
-- Turma 2TDSPO
--   Guilherme Macedo Martins ............ RM562396
--   Pedro Henrique Luiz Alves Duarte .... RM563405
--   Henrique Martins Oliveira ........... RM563620
-- -----------------------------------------------------------------------------
-- Arquivo 06 - Geracao dos arquivos JSON a partir do banco (PKG_KV_EXPORT)
--
-- Executar com SQLcl (vem junto com o SQL Developer: sqldeveloper/sqldeveloper/bin/sql)
-- ou SQL*Plus, A PARTIR DA RAIZ DO REPOSITORIO:
--     sql RM562396/senha@//oracle.fiap.com.br:1521/ORCL @sql/06_export_json.sql
--
-- Use o SQLcl, nao o F5 do SQL Developer: o SQL Developer grava o texto do
-- SELECT dentro do arquivo e o JSON fica invalido.
-- A pasta export/ precisa existir (ela ja vem no repositorio com .gitkeep).
-- Conferir o JSON depois:  node -e "JSON.parse(require('fs').readFileSync('export/kuravet_pets.json','utf8'))"
--
-- Saida (array JSON, um documento por linha -> mongoimport --jsonArray):
--     export/kuravet_pets.json
--     export/kuravet_veterinarios.json
--
-- Alternativa para o video: endpoint do backend Java chamando
-- PKG_KV_EXPORT.FN_EXPORTAR_PETS / FN_EXPORTAR_VETERINARIOS (retornam CLOB).
-- =============================================================================
SET ECHO OFF
SET FEEDBACK OFF
SET HEADING OFF
SET PAGESIZE 0
SET VERIFY OFF
SET TERMOUT OFF
SET TRIMSPOOL ON
SET TRIMOUT ON
SET LINESIZE 32767
SET LONG 100000000
SET LONGCHUNKSIZE 32767

SPOOL export/kuravet_pets.json
SELECT CASE WHEN rn = 1 THEN '[' END
       || PKG_KV_EXPORT.FN_DOC_PET(ID_PET)
       || CASE WHEN rn = total THEN ']' ELSE ',' END AS DOC
  FROM (SELECT ID_PET,
               ROW_NUMBER() OVER (ORDER BY ID_PET) AS rn,
               COUNT(*) OVER ()                    AS total
          FROM PET)
 ORDER BY rn;
SPOOL OFF

SPOOL export/kuravet_veterinarios.json
SELECT CASE WHEN rn = 1 THEN '[' END
       || PKG_KV_EXPORT.FN_DOC_VETERINARIO(ID_VETERINARIO)
       || CASE WHEN rn = total THEN ']' ELSE ',' END AS DOC
  FROM (SELECT ID_VETERINARIO,
               ROW_NUMBER() OVER (ORDER BY ID_VETERINARIO) AS rn,
               COUNT(*) OVER ()                            AS total
          FROM VETERINARIO)
 ORDER BY rn;
SPOOL OFF

SET TERMOUT ON
SET FEEDBACK ON
SET HEADING ON
SET PAGESIZE 50
PROMPT Arquivos gerados: export/kuravet_pets.json e export/kuravet_veterinarios.json
