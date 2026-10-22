-- =============================================================================
-- KuraVet - Challenge FIAP 2026 x Clyvo Vet
-- Disciplina: Mastering Relational and Non-Relational Database - Sprint 4
-- Turma 2TDSPO
--   Guilherme Macedo Martins ............ RM562396
--   Pedro Henrique Luiz Alves Duarte .... RM563405
--   Henrique Martins Oliveira ........... RM563620
-- -----------------------------------------------------------------------------
-- Arquivo 05 - Trigger de auditoria da CONSULTA
-- Ordem de execucao: 00 -> 01 -> 02 -> 03 -> 04 -> 05 -> 07 -> 90 -> 99
-- Sem comandos SQL*Plus (compativel com Flyway).
--
-- Triggers nao podem ficar dentro de package no Oracle; por isso a trigger e
-- apenas o ponto de disparo e toda a regra fica em PKG_KV_AUDITORIA.
-- Correcao do feedback Sprint 3: VALORES_OLD e VALORES_NEW incluem
-- DIAGNOSTICO (e tambem DATA_SOLICITACAO e MOTIVO_RECUSA).
-- =============================================================================
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_CONSULTA
AFTER INSERT OR UPDATE OR DELETE ON CONSULTA
FOR EACH ROW
DECLARE
    v_operacao VARCHAR2(10);
    v_old      VARCHAR2(4000);
    v_new      VARCHAR2(4000);
BEGIN
    IF INSERTING THEN
        v_operacao := 'INSERT';
    ELSIF UPDATING THEN
        v_operacao := 'UPDATE';
    ELSE
        v_operacao := 'DELETE';
    END IF;

    IF UPDATING OR DELETING THEN
        v_old := PKG_KV_AUDITORIA.FN_SERIALIZAR_CONSULTA(
                     p_id_consulta      => :OLD.ID_CONSULTA,
                     p_id_pet           => :OLD.ID_PET,
                     p_id_veterinario   => :OLD.ID_VETERINARIO,
                     p_data_solicitacao => :OLD.DATA_SOLICITACAO,
                     p_data_consulta    => :OLD.DATA_CONSULTA,
                     p_tipo_consulta    => :OLD.TIPO_CONSULTA,
                     p_status           => :OLD.STATUS,
                     p_diagnostico      => :OLD.DIAGNOSTICO,
                     p_motivo_recusa    => :OLD.MOTIVO_RECUSA);
    END IF;

    IF INSERTING OR UPDATING THEN
        v_new := PKG_KV_AUDITORIA.FN_SERIALIZAR_CONSULTA(
                     p_id_consulta      => :NEW.ID_CONSULTA,
                     p_id_pet           => :NEW.ID_PET,
                     p_id_veterinario   => :NEW.ID_VETERINARIO,
                     p_data_solicitacao => :NEW.DATA_SOLICITACAO,
                     p_data_consulta    => :NEW.DATA_CONSULTA,
                     p_tipo_consulta    => :NEW.TIPO_CONSULTA,
                     p_status           => :NEW.STATUS,
                     p_diagnostico      => :NEW.DIAGNOSTICO,
                     p_motivo_recusa    => :NEW.MOTIVO_RECUSA);
    END IF;

    PKG_KV_AUDITORIA.PRC_REGISTRAR(v_operacao, 'CONSULTA', v_old, v_new);
EXCEPTION
    WHEN OTHERS THEN
        -- Erros de negocio (-20xxx) ja foram registrados pelo package.
        -- Erros inesperados sao registrados aqui (transacao autonoma).
        -- Em ambos os casos a alteracao e bloqueada: sem auditoria, sem DML.
        IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
            PKG_KV_UTIL.PRC_REGISTRAR_ERRO('TRG_AUDITORIA_CONSULTA', SQLCODE, SQLERRM);
        END IF;
        RAISE;
END TRG_AUDITORIA_CONSULTA;
/
