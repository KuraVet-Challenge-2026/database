-- =============================================================================
-- KuraVet - Challenge FIAP 2026 x Clyvo Vet
-- Disciplina: Mastering Relational and Non-Relational Database - Sprint 4
-- Turma 2TDSPO
--   Guilherme Macedo Martins ............ RM562396
--   Pedro Henrique Luiz Alves Duarte .... RM563405
--   Henrique Martins Oliveira ........... RM563620
-- -----------------------------------------------------------------------------
-- Arquivo 00 - Limpeza do schema (SOMENTE schema de testes/sandbox)
-- Ordem de execucao: 00 -> 01 -> 02 -> 03 -> 04 -> 05 -> 07 -> 90 -> 99
-- ATENCAO: NAO executar no schema usado pelo backend Java (Flyway).
--
-- Remove tambem as functions/procedures "soltas" da Sprint 3, para que no
-- schema fiquem apenas os objetos empacotados.
-- Ignora somente o erro "objeto nao existe"; qualquer outro erro e propagado.
-- =============================================================================
DECLARE
    PROCEDURE drop_obj (p_comando IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_comando;
    EXCEPTION
        WHEN OTHERS THEN
            -- -942 tabela | -2289 sequence | -4043 objeto | -4080 trigger
            IF SQLCODE NOT IN (-942, -2289, -4043, -4080) THEN
                RAISE;
            END IF;
    END drop_obj;
BEGIN
    drop_obj('DROP TRIGGER TRG_AUDITORIA_CONSULTA');

    drop_obj('DROP PACKAGE PKG_KV_EXPORT');
    drop_obj('DROP PACKAGE PKG_KV_RELATORIO');
    drop_obj('DROP PACKAGE PKG_KV_CARGA');
    drop_obj('DROP PACKAGE PKG_KV_AUDITORIA');
    drop_obj('DROP PACKAGE PKG_KV_UTIL');

    -- Objetos avulsos da Sprint 3 (agora empacotados)
    drop_obj('DROP FUNCTION FN_MONTA_JSON');
    drop_obj('DROP FUNCTION FN_CALCULA_IDADE_PET');
    drop_obj('DROP PROCEDURE PROC_LISTAR_CONSULTAS_JSON');
    drop_obj('DROP PROCEDURE PROC_SUBTOTAIS_PAGAMENTO');
    drop_obj('DROP PROCEDURE PRC_CARGA_TUTOR');
    drop_obj('DROP PROCEDURE PRC_CARGA_VETERINARIO');
    drop_obj('DROP PROCEDURE PRC_CARGA_PET');
    drop_obj('DROP PROCEDURE PRC_CARGA_CONSULTA');
    drop_obj('DROP PROCEDURE PRC_CARGA_PAGAMENTO');

    drop_obj('DROP TABLE AUDITORIA_LOG CASCADE CONSTRAINTS PURGE');
    drop_obj('DROP TABLE LOG_ERRO_CARGA CASCADE CONSTRAINTS PURGE');
    drop_obj('DROP TABLE FATO_PAGAMENTO CASCADE CONSTRAINTS PURGE');
    drop_obj('DROP TABLE CONSULTA CASCADE CONSTRAINTS PURGE');
    drop_obj('DROP TABLE PET CASCADE CONSTRAINTS PURGE');
    drop_obj('DROP TABLE VETERINARIO CASCADE CONSTRAINTS PURGE');
    drop_obj('DROP TABLE TUTOR CASCADE CONSTRAINTS PURGE');

    drop_obj('DROP SEQUENCE SEQ_KV_TUTOR');
    drop_obj('DROP SEQUENCE SEQ_KV_VETERINARIO');
    drop_obj('DROP SEQUENCE SEQ_KV_PET');
    drop_obj('DROP SEQUENCE SEQ_KV_CONSULTA');
    drop_obj('DROP SEQUENCE SEQ_KV_PAGAMENTO');
END;
/
