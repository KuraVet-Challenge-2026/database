-- =============================================================================
-- KuraVet - Challenge FIAP 2026 x Clyvo Vet
-- Disciplina: Mastering Relational and Non-Relational Database - Sprint 4
-- Turma 2TDSPO
--   Guilherme Macedo Martins ............ RM562396
--   Pedro Henrique Luiz Alves Duarte .... RM563405
--   Henrique Martins Oliveira ........... RM563620
-- -----------------------------------------------------------------------------
-- Arquivo 99 - Verificacao do schema (rodar ao final; tudo deve estar VALID
-- e USER_ERRORS deve voltar sem linhas)
-- =============================================================================
SET LINESIZE 200
SET PAGESIZE 100
COLUMN OBJECT_NAME FORMAT A32
COLUMN OBJECT_TYPE FORMAT A14
COLUMN STATUS      FORMAT A8
COLUMN NAME        FORMAT A28
COLUMN TYPE        FORMAT A14
COLUMN TEXT        FORMAT A100

PROMPT === Objetos do projeto ===
SELECT OBJECT_TYPE, OBJECT_NAME, STATUS
  FROM USER_OBJECTS
 WHERE OBJECT_NAME LIKE 'PKG_KV%'
    OR OBJECT_NAME LIKE 'SEQ_KV%'
    OR OBJECT_NAME IN ('TRG_AUDITORIA_CONSULTA', 'TUTOR', 'VETERINARIO', 'PET', 'CONSULTA',
                       'FATO_PAGAMENTO', 'AUDITORIA_LOG', 'LOG_ERRO_CARGA')
 ORDER BY OBJECT_TYPE, OBJECT_NAME;

PROMPT === Objetos INVALIDOS (esperado: nenhuma linha) ===
SELECT OBJECT_TYPE, OBJECT_NAME FROM USER_OBJECTS WHERE STATUS <> 'VALID';

PROMPT === Erros de compilacao (esperado: nenhuma linha) ===
SELECT NAME, TYPE, LINE, POSITION, TEXT FROM USER_ERRORS ORDER BY NAME, TYPE, SEQUENCE;

PROMPT === Functions/procedures avulsas (esperado: nenhuma linha - tudo empacotado) ===
SELECT OBJECT_TYPE, OBJECT_NAME
  FROM USER_OBJECTS
 WHERE OBJECT_TYPE IN ('FUNCTION', 'PROCEDURE');

PROMPT === Quantidade de registros ===
SELECT 'TUTOR' AS TABELA, COUNT(*) AS QTD FROM TUTOR
UNION ALL SELECT 'VETERINARIO',    COUNT(*) FROM VETERINARIO
UNION ALL SELECT 'PET',            COUNT(*) FROM PET
UNION ALL SELECT 'CONSULTA',       COUNT(*) FROM CONSULTA
UNION ALL SELECT 'FATO_PAGAMENTO', COUNT(*) FROM FATO_PAGAMENTO
UNION ALL SELECT 'AUDITORIA_LOG',  COUNT(*) FROM AUDITORIA_LOG
UNION ALL SELECT 'LOG_ERRO_CARGA', COUNT(*) FROM LOG_ERRO_CARGA;

PROMPT === Consultas por status ===
SELECT STATUS, COUNT(*) AS QTD FROM CONSULTA GROUP BY STATUS ORDER BY STATUS;
