-- =============================================================================
-- KuraVet - Challenge FIAP 2026 x Clyvo Vet
-- Disciplina: Mastering Relational and Non-Relational Database - Sprint 4
-- Turma 2TDSPO
--   Guilherme Macedo Martins ............ RM562396
--   Pedro Henrique Luiz Alves Duarte .... RM563405
--   Henrique Martins Oliveira ........... RM563620
-- -----------------------------------------------------------------------------
-- Arquivo 04 - Corpo (BODY) dos packages
-- Ordem de execucao: 00 -> 01 -> 02 -> 03 -> 04 -> 05 -> 07 -> 90 -> 99
-- Sem comandos SQL*Plus (compativel com Flyway).
--
-- Regra de tratamento de excecoes (feedback Sprint 3): cada handler
-- corresponde a uma situacao que realmente pode ocorrer na rotina; nao ha
-- handlers "decorativos". Cada rotina publica tem ao menos uma excecao de
-- negocio demonstrada em 90_demo_evidencias.sql.
-- =============================================================================

-- =============================================================================
-- PKG_KV_UTIL
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY PKG_KV_UTIL AS

    -- -------------------------------------------------------------------------
    -- Privada: escapa texto para valor string JSON (RFC 8259):
    --   "  -> \"      \  -> \\      quebra de linha -> \n
    --   CR -> \r      TAB -> \t     backspace -> \b     form feed -> \f
    --   demais caracteres de controle (< 32) -> \u00XX
    -- Estouro de tamanho (VALUE_ERROR) e tratado por quem chama (FN_MONTA_JSON).
    -- -------------------------------------------------------------------------
    FUNCTION fn_escape_json (p_texto IN VARCHAR2) RETURN VARCHAR2 IS
        v_saida VARCHAR2(32767);
        v_char  VARCHAR2(4 CHAR);
        v_cod   PLS_INTEGER;
    BEGIN
        IF p_texto IS NULL THEN
            RETURN NULL;
        END IF;

        FOR i IN 1 .. LENGTH(p_texto) LOOP
            v_char := SUBSTR(p_texto, i, 1);
            v_cod  := ASCII(v_char);
            v_saida := v_saida ||
                CASE
                    WHEN v_char = '"' THEN '\"'
                    WHEN v_char = '\' THEN '\\'
                    WHEN v_cod = 8    THEN '\b'
                    WHEN v_cod = 9    THEN '\t'
                    WHEN v_cod = 10   THEN '\n'
                    WHEN v_cod = 12   THEN '\f'
                    WHEN v_cod = 13   THEN '\r'
                    WHEN v_cod < 32   THEN '\u' || LPAD(TRIM(TO_CHAR(v_cod, 'XXXX')), 4, '0')
                    ELSE v_char
                END;
        END LOOP;

        RETURN v_saida;
    END fn_escape_json;

    -- Privada: par "chave":"valor" (ou "chave":null)
    FUNCTION fn_par_json (p_chave IN VARCHAR2, p_valor IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        IF p_valor IS NULL THEN
            RETURN '"' || p_chave || '":null';
        END IF;
        RETURN '"' || p_chave || '":"' || fn_escape_json(p_valor) || '"';
    END fn_par_json;

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_REGISTRAR_ERRO (
        p_origem   IN VARCHAR2,
        p_cd_erro  IN NUMBER,
        p_mensagem IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES (SUBSTR(NVL(p_origem, 'NAO INFORMADA'), 1, 60),
                SUBSTR(NVL(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'), USER), 1, 60),
                TO_CHAR(NVL(p_cd_erro, c_err_inesperado)),
                SUBSTR(NVL(p_mensagem, '(sem mensagem)'), 1, 500));
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- Uma falha ao gravar o log nunca pode esconder o erro original
            -- de quem chamou: desfaz a transacao autonoma e segue.
            ROLLBACK;
    END PRC_REGISTRAR_ERRO;

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_LANCAR_ERRO (
        p_origem   IN VARCHAR2,
        p_cd_erro  IN NUMBER,
        p_mensagem IN VARCHAR2
    ) IS
    BEGIN
        PRC_REGISTRAR_ERRO(p_origem, p_cd_erro, p_mensagem);
        RAISE_APPLICATION_ERROR(p_cd_erro, SUBSTR(p_mensagem, 1, 2000));
    END PRC_LANCAR_ERRO;

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_TRATAR_INESPERADO (
        p_origem  IN VARCHAR2,
        p_sqlcode IN NUMBER,
        p_sqlerrm IN VARCHAR2
    ) IS
    BEGIN
        IF p_sqlcode BETWEEN -20999 AND -20000 THEN
            -- Erro de negocio lancado por rotina interna: ja foi registrado.
            RAISE_APPLICATION_ERROR(p_sqlcode, REGEXP_REPLACE(p_sqlerrm, '^ORA-[0-9]{5}: ', ''));
        END IF;
        PRC_LANCAR_ERRO(p_origem, c_err_inesperado,
                        'Erro inesperado em ' || p_origem || ': ' || p_sqlerrm);
    END PRC_TRATAR_INESPERADO;

    -- -------------------------------------------------------------------------
    -- FN_MONTA_JSON (Sprint 3 - funcao 1, corrigida)
    --   * escapa caracteres especiais de todos os valores textuais;
    --   * valores nulos viram null (JSON valido) em vez de "N/A";
    --   * handlers somente para situacoes possiveis: ID invalido e JSON maior
    --     que 4000 caracteres depois do escape (VALUE_ERROR).
    -- -------------------------------------------------------------------------
    FUNCTION FN_MONTA_JSON (
        p_id_consulta   IN NUMBER,
        p_pet           IN VARCHAR2,
        p_tutor         IN VARCHAR2,
        p_veterinario   IN VARCHAR2,
        p_data_consulta IN VARCHAR2,
        p_tipo_consulta IN VARCHAR2,
        p_status        IN VARCHAR2 DEFAULT NULL,
        p_diagnostico   IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_UTIL.FN_MONTA_JSON';
        v_json   VARCHAR2(4000);
    BEGIN
        IF p_id_consulta IS NULL OR p_id_consulta <= 0 THEN
            RAISE e_parametro_invalido;
        END IF;

        v_json := '{"id_consulta":' || TO_CHAR(p_id_consulta)
               || ',' || fn_par_json('pet',           p_pet)
               || ',' || fn_par_json('tutor',         p_tutor)
               || ',' || fn_par_json('veterinario',   p_veterinario)
               || ',' || fn_par_json('data_consulta', p_data_consulta)
               || ',' || fn_par_json('tipo_consulta', p_tipo_consulta)
               || ',' || fn_par_json('status',        p_status)
               || ',' || fn_par_json('diagnostico',   p_diagnostico)
               || '}';

        RETURN v_json;
    EXCEPTION
        WHEN e_parametro_invalido THEN
            PRC_LANCAR_ERRO(c_origem, c_err_parametro_invalido,
                'ID da consulta deve ser informado e maior que zero (recebido: '
                || NVL(TO_CHAR(p_id_consulta), 'nulo') || ')');
        WHEN VALUE_ERROR THEN
            PRC_LANCAR_ERRO(c_origem, c_err_json_excede,
                'JSON da consulta ' || p_id_consulta
                || ' excede 4000 caracteres apos o escape dos caracteres especiais');
        WHEN OTHERS THEN
            PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END FN_MONTA_JSON;

    -- -------------------------------------------------------------------------
    -- FN_CALCULA_IDADE_PET (Sprint 3 - funcao 2, corrigida)
    --   TOO_MANY_ROWS removido (ID_PET e PK, nao ocorre). Em seu lugar,
    --   validacao pertinente ao calculo: data de nascimento no futuro.
    -- -------------------------------------------------------------------------
    FUNCTION FN_CALCULA_IDADE_PET (
        p_id_pet IN PET.ID_PET%TYPE
    ) RETURN VARCHAR2 IS
        c_origem    CONSTANT VARCHAR2(60) := 'PKG_KV_UTIL.FN_CALCULA_IDADE_PET';
        v_data_nasc PET.DATA_NASCIMENTO%TYPE;
        v_meses     PLS_INTEGER;
    BEGIN
        IF p_id_pet IS NULL THEN
            RAISE e_parametro_invalido;
        END IF;

        SELECT DATA_NASCIMENTO
          INTO v_data_nasc
          FROM PET
         WHERE ID_PET = p_id_pet;

        IF v_data_nasc > SYSDATE THEN
            RAISE e_data_invalida;
        END IF;

        v_meses := TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), v_data_nasc));

        IF v_meses < 1 THEN
            RETURN 'Filhote recem-nascido (menos de 1 mes)';
        END IF;

        RETURN TRUNC(v_meses / 12) || ' ano(s) e ' || MOD(v_meses, 12) || ' mes(es)';
    EXCEPTION
        WHEN e_parametro_invalido THEN
            PRC_LANCAR_ERRO(c_origem, c_err_parametro_invalido, 'ID do pet nao informado');
        WHEN NO_DATA_FOUND THEN
            PRC_LANCAR_ERRO(c_origem, c_err_pet_inexistente,
                'Pet ID ' || p_id_pet || ' nao encontrado');
        WHEN e_data_invalida THEN
            PRC_LANCAR_ERRO(c_origem, c_err_data_invalida,
                'Data de nascimento do pet ' || p_id_pet || ' esta no futuro ('
                || TO_CHAR(v_data_nasc, 'DD/MM/YYYY') || ')');
        WHEN OTHERS THEN
            PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END FN_CALCULA_IDADE_PET;

    -- -------------------------------------------------------------------------
    FUNCTION FN_CATEGORIA_ETARIA (
        p_data_nascimento IN DATE
    ) RETURN VARCHAR2 IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_UTIL.FN_CATEGORIA_ETARIA';
        v_meses  NUMBER;
    BEGIN
        IF p_data_nascimento IS NULL THEN
            RAISE e_parametro_invalido;
        END IF;
        IF p_data_nascimento > SYSDATE THEN
            RAISE e_data_invalida;
        END IF;

        v_meses := MONTHS_BETWEEN(SYSDATE, p_data_nascimento);

        IF v_meses < 12 THEN
            RETURN 'Filhote';
        ELSIF v_meses < 84 THEN
            RETURN 'Adulto';
        END IF;
        RETURN 'Idoso';
    EXCEPTION
        WHEN e_parametro_invalido THEN
            PRC_LANCAR_ERRO(c_origem, c_err_parametro_invalido, 'Data de nascimento nao informada');
        WHEN e_data_invalida THEN
            PRC_LANCAR_ERRO(c_origem, c_err_data_invalida,
                'Data de nascimento no futuro: ' || TO_CHAR(p_data_nascimento, 'DD/MM/YYYY'));
        WHEN OTHERS THEN
            PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END FN_CATEGORIA_ETARIA;

END PKG_KV_UTIL;
/

-- =============================================================================
-- PKG_KV_AUDITORIA
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY PKG_KV_AUDITORIA AS

    -- -------------------------------------------------------------------------
    -- Serializacao unica usada para OLD e NEW (antes a trigger repetia a
    -- concatenacao 3 vezes). Inclui DIAGNOSTICO (feedback Sprint 3).
    -- JSON_OBJECT garante o escape correto de aspas e quebras de linha.
    -- -------------------------------------------------------------------------
    FUNCTION FN_SERIALIZAR_CONSULTA (
        p_id_consulta      IN CONSULTA.ID_CONSULTA%TYPE,
        p_id_pet           IN CONSULTA.ID_PET%TYPE,
        p_id_veterinario   IN CONSULTA.ID_VETERINARIO%TYPE,
        p_data_solicitacao IN CONSULTA.DATA_SOLICITACAO%TYPE,
        p_data_consulta    IN CONSULTA.DATA_CONSULTA%TYPE,
        p_tipo_consulta    IN CONSULTA.TIPO_CONSULTA%TYPE,
        p_status           IN CONSULTA.STATUS%TYPE,
        p_diagnostico      IN CONSULTA.DIAGNOSTICO%TYPE,
        p_motivo_recusa    IN CONSULTA.MOTIVO_RECUSA%TYPE
    ) RETURN VARCHAR2 IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_AUDITORIA.FN_SERIALIZAR_CONSULTA';
        v_json   VARCHAR2(4000);
    BEGIN
        IF p_id_consulta IS NULL THEN
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        SELECT JSON_OBJECT(
                   'id_consulta'      VALUE p_id_consulta,
                   'id_pet'           VALUE p_id_pet,
                   'id_veterinario'   VALUE p_id_veterinario,
                   'data_solicitacao' VALUE TO_CHAR(p_data_solicitacao, 'YYYY-MM-DD"T"HH24:MI:SS'),
                   'data_consulta'    VALUE TO_CHAR(p_data_consulta, 'YYYY-MM-DD"T"HH24:MI:SS'),
                   'tipo_consulta'    VALUE p_tipo_consulta,
                   'status'           VALUE p_status,
                   'diagnostico'      VALUE p_diagnostico,
                   'motivo_recusa'    VALUE p_motivo_recusa)
          INTO v_json
          FROM DUAL;

        RETURN v_json;
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido,
                'ID da consulta obrigatorio para serializar a auditoria');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END FN_SERIALIZAR_CONSULTA;

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_REGISTRAR (
        p_operacao    IN VARCHAR2,
        p_tabela      IN VARCHAR2,
        p_valores_old IN VARCHAR2,
        p_valores_new IN VARCHAR2
    ) IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_AUDITORIA.PRC_REGISTRAR';
    BEGIN
        IF p_operacao IS NULL OR p_operacao NOT IN ('INSERT', 'UPDATE', 'DELETE') THEN
            RAISE PKG_KV_UTIL.e_operacao_invalida;
        END IF;

        IF TRIM(p_tabela) IS NULL
           OR (p_operacao IN ('INSERT', 'UPDATE') AND p_valores_new IS NULL)
           OR (p_operacao IN ('UPDATE', 'DELETE') AND p_valores_old IS NULL) THEN
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        INSERT INTO AUDITORIA_LOG (USUARIO, OPERACAO, TABELA_AFETADA, VALORES_OLD, VALORES_NEW)
        VALUES (SUBSTR(NVL(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'), USER), 1, 60),
                p_operacao, UPPER(TRIM(p_tabela)), p_valores_old, p_valores_new);
    EXCEPTION
        WHEN PKG_KV_UTIL.e_operacao_invalida THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_operacao_invalida,
                'Operacao de auditoria invalida: ' || NVL(p_operacao, 'nula')
                || ' (esperado INSERT, UPDATE ou DELETE)');
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido,
                'Tabela e valores OLD/NEW obrigatorios para a operacao ' || p_operacao);
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END PRC_REGISTRAR;

END PKG_KV_AUDITORIA;
/

-- =============================================================================
-- PKG_KV_CARGA  (procedures chamadas pelo backend; sem COMMIT, com OUT id)
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY PKG_KV_CARGA AS

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_CARGA_TUTOR (
        p_nome     IN  TUTOR.NOME%TYPE,
        p_cpf      IN  TUTOR.CPF%TYPE,
        p_telefone IN  TUTOR.TELEFONE%TYPE,
        p_email    IN  TUTOR.EMAIL%TYPE,
        p_endereco IN  TUTOR.ENDERECO%TYPE,
        p_id_tutor OUT TUTOR.ID_TUTOR%TYPE
    ) IS
        c_origem      CONSTANT VARCHAR2(60) := 'PKG_KV_CARGA.PRC_CARGA_TUTOR';
        v_cpf_digitos VARCHAR2(30);
        v_cpf         TUTOR.CPF%TYPE;
        v_motivo      VARCHAR2(200);
    BEGIN
        IF TRIM(p_nome) IS NULL THEN
            v_motivo := 'Nome do tutor e obrigatorio';
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        v_cpf_digitos := REGEXP_REPLACE(p_cpf, '[^0-9]', '');
        IF v_cpf_digitos IS NULL OR LENGTH(v_cpf_digitos) <> 11 THEN
            RAISE PKG_KV_UTIL.e_cpf_invalido;
        END IF;

        IF p_email IS NOT NULL
           AND NOT REGEXP_LIKE(p_email, '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$') THEN
            v_motivo := 'E-mail em formato invalido: ' || p_email;
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        -- CPF sempre gravado no mesmo formato (000.000.000-00)
        v_cpf := REGEXP_REPLACE(v_cpf_digitos,
                                '^([0-9]{3})([0-9]{3})([0-9]{3})([0-9]{2})$',
                                '\1.\2.\3-\4');

        p_id_tutor := SEQ_KV_TUTOR.NEXTVAL;

        INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO)
        VALUES (p_id_tutor, TRIM(p_nome), v_cpf, p_telefone, p_email, p_endereco, SYSDATE);
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido, v_motivo);
        WHEN PKG_KV_UTIL.e_cpf_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_cpf_invalido,
                'CPF invalido (deve conter 11 digitos): ' || NVL(p_cpf, 'nulo'));
        WHEN DUP_VAL_ON_INDEX THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_registro_duplicado,
                'CPF ja cadastrado: ' || v_cpf);
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END PRC_CARGA_TUTOR;

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_CARGA_VETERINARIO (
        p_nome           IN  VETERINARIO.NOME%TYPE,
        p_crmv           IN  VETERINARIO.CRMV%TYPE,
        p_especialidade  IN  VETERINARIO.ESPECIALIDADE%TYPE,
        p_telefone       IN  VETERINARIO.TELEFONE%TYPE,
        p_email          IN  VETERINARIO.EMAIL%TYPE,
        p_id_veterinario OUT VETERINARIO.ID_VETERINARIO%TYPE
    ) IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_CARGA.PRC_CARGA_VETERINARIO';
        v_motivo VARCHAR2(200);
    BEGIN
        IF TRIM(p_nome) IS NULL THEN
            v_motivo := 'Nome do veterinario e obrigatorio';
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        IF p_crmv IS NULL OR LENGTH(TRIM(p_crmv)) < 5 THEN
            RAISE PKG_KV_UTIL.e_crmv_invalido;
        END IF;

        IF p_email IS NOT NULL
           AND NOT REGEXP_LIKE(p_email, '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$') THEN
            v_motivo := 'E-mail em formato invalido: ' || p_email;
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        p_id_veterinario := SEQ_KV_VETERINARIO.NEXTVAL;

        INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL)
        VALUES (p_id_veterinario, TRIM(p_nome), UPPER(TRIM(p_crmv)), p_especialidade, p_telefone, p_email);
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido, v_motivo);
        WHEN PKG_KV_UTIL.e_crmv_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_crmv_invalido,
                'CRMV invalido ou nao informado: ' || NVL(p_crmv, 'nulo'));
        WHEN DUP_VAL_ON_INDEX THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_registro_duplicado,
                'CRMV ja cadastrado: ' || UPPER(TRIM(p_crmv)));
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END PRC_CARGA_VETERINARIO;

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_CARGA_PET (
        p_nome            IN  PET.NOME%TYPE,
        p_especie         IN  PET.ESPECIE%TYPE,
        p_raca            IN  PET.RACA%TYPE,
        p_data_nascimento IN  PET.DATA_NASCIMENTO%TYPE,
        p_sexo            IN  VARCHAR2,
        p_id_tutor        IN  PET.ID_TUTOR%TYPE,
        p_id_pet          OUT PET.ID_PET%TYPE
    ) IS
        c_origem  CONSTANT VARCHAR2(60) := 'PKG_KV_CARGA.PRC_CARGA_PET';
        v_sexo    VARCHAR2(4000) := UPPER(TRIM(p_sexo));   -- largo: valor invalido cai na validacao, nao em ORA-06502
        v_qtd     PLS_INTEGER;
        v_motivo  VARCHAR2(200);
    BEGIN
        IF TRIM(p_nome) IS NULL OR TRIM(p_especie) IS NULL THEN
            v_motivo := 'Nome e especie do pet sao obrigatorios';
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        IF v_sexo IS NULL OR v_sexo NOT IN ('M', 'F') THEN
            v_motivo := 'Sexo do pet deve ser M ou F (recebido: ' || NVL(p_sexo, 'nulo') || ')';
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        IF p_data_nascimento IS NULL OR p_data_nascimento > SYSDATE THEN
            RAISE PKG_KV_UTIL.e_data_invalida;
        END IF;

        SELECT COUNT(*) INTO v_qtd FROM TUTOR WHERE ID_TUTOR = p_id_tutor;
        IF v_qtd = 0 THEN
            RAISE PKG_KV_UTIL.e_tutor_inexistente;
        END IF;

        p_id_pet := SEQ_KV_PET.NEXTVAL;

        INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR)
        VALUES (p_id_pet, TRIM(p_nome), TRIM(p_especie), p_raca, p_data_nascimento, v_sexo, p_id_tutor);
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido, v_motivo);
        WHEN PKG_KV_UTIL.e_data_invalida THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_data_invalida,
                'Data de nascimento nula ou no futuro para o pet ' || p_nome);
        WHEN PKG_KV_UTIL.e_tutor_inexistente THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_tutor_inexistente,
                'Tutor ID ' || NVL(TO_CHAR(p_id_tutor), 'nulo') || ' nao existe (pet ' || p_nome || ')');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END PRC_CARGA_PET;

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_CARGA_CONSULTA (
        p_id_pet         IN  CONSULTA.ID_PET%TYPE,
        p_id_veterinario IN  CONSULTA.ID_VETERINARIO%TYPE,
        p_data_consulta  IN  CONSULTA.DATA_CONSULTA%TYPE,
        p_tipo_consulta  IN  CONSULTA.TIPO_CONSULTA%TYPE,
        p_status         IN  CONSULTA.STATUS%TYPE,
        p_diagnostico    IN  CONSULTA.DIAGNOSTICO%TYPE,
        p_motivo_recusa  IN  CONSULTA.MOTIVO_RECUSA%TYPE,
        p_id_consulta    OUT CONSULTA.ID_CONSULTA%TYPE
    ) IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_CARGA.PRC_CARGA_CONSULTA';
        v_status VARCHAR2(4000) := UPPER(TRIM(p_status));  -- largo: valor invalido cai na validacao, nao em ORA-06502
        v_qtd    PLS_INTEGER;
        v_motivo VARCHAR2(200);
    BEGIN
        IF p_data_consulta IS NULL OR TRIM(p_tipo_consulta) IS NULL THEN
            v_motivo := 'Data e tipo da consulta sao obrigatorios';
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        IF v_status IS NULL
           OR v_status NOT IN ('SOLICITADA', 'AGENDADA', 'REALIZADA', 'CANCELADA', 'RECUSADA') THEN
            RAISE PKG_KV_UTIL.e_status_invalido;
        END IF;

        IF v_status = 'RECUSADA' AND TRIM(p_motivo_recusa) IS NULL THEN
            v_motivo := 'Consulta RECUSADA exige motivo da recusa';
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        IF v_status = 'REALIZADA' AND TRIM(p_diagnostico) IS NULL THEN
            v_motivo := 'Consulta REALIZADA exige diagnostico';
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        SELECT COUNT(*) INTO v_qtd FROM PET WHERE ID_PET = p_id_pet;
        IF v_qtd = 0 THEN
            RAISE PKG_KV_UTIL.e_pet_inexistente;
        END IF;

        SELECT COUNT(*) INTO v_qtd FROM VETERINARIO WHERE ID_VETERINARIO = p_id_veterinario;
        IF v_qtd = 0 THEN
            RAISE PKG_KV_UTIL.e_vet_inexistente;
        END IF;

        p_id_consulta := SEQ_KV_CONSULTA.NEXTVAL;

        INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA,
                              TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA)
        VALUES (p_id_consulta, p_id_pet, p_id_veterinario, SYSDATE, p_data_consulta,
                TRIM(p_tipo_consulta), v_status, p_diagnostico, p_motivo_recusa);
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido, v_motivo);
        WHEN PKG_KV_UTIL.e_status_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_status_invalido,
                'Status invalido: ' || NVL(p_status, 'nulo')
                || ' (validos: SOLICITADA, AGENDADA, REALIZADA, CANCELADA, RECUSADA)');
        WHEN PKG_KV_UTIL.e_pet_inexistente THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_pet_inexistente,
                'Pet ID ' || NVL(TO_CHAR(p_id_pet), 'nulo') || ' nao existe');
        WHEN PKG_KV_UTIL.e_vet_inexistente THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_vet_inexistente,
                'Veterinario ID ' || NVL(TO_CHAR(p_id_veterinario), 'nulo') || ' nao existe');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END PRC_CARGA_CONSULTA;

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_REGISTRAR_DIAGNOSTICO (
        p_id_consulta IN CONSULTA.ID_CONSULTA%TYPE,
        p_diagnostico IN CONSULTA.DIAGNOSTICO%TYPE
    ) IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_CARGA.PRC_REGISTRAR_DIAGNOSTICO';
        v_status CONSULTA.STATUS%TYPE;
    BEGIN
        IF p_id_consulta IS NULL OR TRIM(p_diagnostico) IS NULL THEN
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        SELECT STATUS
          INTO v_status
          FROM CONSULTA
         WHERE ID_CONSULTA = p_id_consulta
           FOR UPDATE;

        IF v_status <> 'AGENDADA' THEN
            RAISE PKG_KV_UTIL.e_transicao_invalida;
        END IF;

        UPDATE CONSULTA
           SET STATUS      = 'REALIZADA',
               DIAGNOSTICO = p_diagnostico
         WHERE ID_CONSULTA = p_id_consulta;
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido,
                'ID da consulta e diagnostico sao obrigatorios');
        WHEN NO_DATA_FOUND THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_consulta_inexistente,
                'Consulta ID ' || p_id_consulta || ' nao existe');
        WHEN PKG_KV_UTIL.e_transicao_invalida THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_transicao_invalida,
                'Diagnostico so pode ser registrado em consulta AGENDADA (consulta '
                || p_id_consulta || ' esta ' || v_status || ')');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END PRC_REGISTRAR_DIAGNOSTICO;

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_CARGA_PAGAMENTO (
        p_id_consulta    IN  FATO_PAGAMENTO.ID_CONSULTA%TYPE,
        p_clinica        IN  FATO_PAGAMENTO.CLINICA%TYPE,
        p_tipo_pagamento IN  FATO_PAGAMENTO.TIPO_PAGAMENTO%TYPE,
        p_valor          IN  FATO_PAGAMENTO.VALOR%TYPE,
        p_data_pagamento IN  FATO_PAGAMENTO.DATA_PAGAMENTO%TYPE,
        p_id_pagamento   OUT FATO_PAGAMENTO.ID_PAGAMENTO%TYPE
    ) IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_CARGA.PRC_CARGA_PAGAMENTO';
        v_status CONSULTA.STATUS%TYPE;
        v_motivo VARCHAR2(200);
    BEGIN
        IF TRIM(p_clinica) IS NULL THEN
            v_motivo := 'Clinica do pagamento e obrigatoria';
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        IF p_tipo_pagamento IS NULL
           OR p_tipo_pagamento NOT IN ('Pix', 'Cartao de Credito', 'Cartao de Debito', 'Dinheiro') THEN
            v_motivo := 'Tipo de pagamento invalido: ' || NVL(p_tipo_pagamento, 'nulo')
                     || ' (validos: Pix, Cartao de Credito, Cartao de Debito, Dinheiro)';
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        IF p_valor IS NULL OR p_valor <= 0 THEN
            RAISE PKG_KV_UTIL.e_valor_invalido;
        END IF;

        SELECT STATUS
          INTO v_status
          FROM CONSULTA
         WHERE ID_CONSULTA = p_id_consulta;

        IF v_status <> 'REALIZADA' THEN
            RAISE PKG_KV_UTIL.e_consulta_nao_realizada;
        END IF;

        p_id_pagamento := SEQ_KV_PAGAMENTO.NEXTVAL;

        INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO)
        VALUES (p_id_pagamento, p_id_consulta, TRIM(p_clinica), p_tipo_pagamento, p_valor,
                NVL(p_data_pagamento, SYSDATE));
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido, v_motivo);
        WHEN PKG_KV_UTIL.e_valor_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_valor_invalido,
                'Valor deve ser maior que zero (recebido: ' || NVL(TO_CHAR(p_valor), 'nulo') || ')');
        WHEN NO_DATA_FOUND THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_consulta_inexistente,
                'Consulta ID ' || NVL(TO_CHAR(p_id_consulta), 'nulo') || ' nao existe');
        WHEN PKG_KV_UTIL.e_consulta_nao_realizada THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_consulta_nao_realizada,
                'Pagamento so e aceito para consulta REALIZADA (consulta '
                || p_id_consulta || ' esta ' || v_status || ')');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END PRC_CARGA_PAGAMENTO;

END PKG_KV_CARGA;
/

-- =============================================================================
-- PKG_KV_RELATORIO
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY PKG_KV_RELATORIO AS

    -- Layout do relatorio de subtotais (centralizado para facilitar ajuste)
    c_rotulo_subtotal CONSTANT VARCHAR2(30) := 'Sub Total';
    c_rotulo_total    CONSTANT VARCHAR2(30) := 'Total Geral';
    c_larg_clinica    CONSTANT PLS_INTEGER  := 25;
    c_larg_tipo       CONSTANT PLS_INTEGER  := 20;
    c_larg_valor      CONSTANT PLS_INTEGER  := 14;

    -- Privada: valor monetario no formato brasileiro (1.234,56), alinhado a direita
    FUNCTION fn_moeda (p_valor IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN LPAD(TO_CHAR(NVL(p_valor, 0), 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'''),
                    c_larg_valor);
    END fn_moeda;

    -- Privada: linha do relatorio com colunas de largura fixa
    FUNCTION fn_linha (p_col1 IN VARCHAR2, p_col2 IN VARCHAR2, p_valor IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN RPAD(NVL(p_col1, ' '), c_larg_clinica) || ' | '
            || RPAD(NVL(p_col2, ' '), c_larg_tipo)    || ' | '
            || p_valor;
    END fn_linha;

    -- Privada: linha separadora
    FUNCTION fn_separador (p_char IN VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN RPAD(p_char, c_larg_clinica + c_larg_tipo + c_larg_valor + 6, p_char);
    END fn_separador;

    -- -------------------------------------------------------------------------
    -- PRC_LISTAR_CONSULTAS_JSON (Sprint 3 - procedimento 1, corrigido)
    --   * ausencia de resultados verificada pelas linhas efetivamente
    --     percorridas no cursor (antes: COUNT(*) separado da consulta);
    --   * filtro por tutor torna "sem resultados" um caso real;
    --   * handlers somente para situacoes possiveis (TOO_MANY_ROWS removido).
    -- -------------------------------------------------------------------------
    PROCEDURE PRC_LISTAR_CONSULTAS_JSON (
        p_id_tutor IN TUTOR.ID_TUTOR%TYPE DEFAULT NULL
    ) IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_RELATORIO.PRC_LISTAR_CONSULTAS_JSON';
        v_qtd    PLS_INTEGER := 0;
    BEGIN
        IF p_id_tutor IS NOT NULL THEN
            SELECT COUNT(*) INTO v_qtd FROM TUTOR WHERE ID_TUTOR = p_id_tutor;
            IF v_qtd = 0 THEN
                RAISE PKG_KV_UTIL.e_tutor_inexistente;
            END IF;
            v_qtd := 0;
        END IF;

        FOR r IN (SELECT c.ID_CONSULTA,
                         p.NOME                                   AS NOME_PET,
                         t.NOME                                   AS NOME_TUTOR,
                         v.NOME                                   AS NOME_VET,
                         TO_CHAR(c.DATA_CONSULTA, 'DD/MM/YYYY')   AS DATA_FMT,
                         c.TIPO_CONSULTA,
                         c.STATUS,
                         c.DIAGNOSTICO
                    FROM CONSULTA c
                    JOIN PET p         ON p.ID_PET = c.ID_PET
                    JOIN TUTOR t       ON t.ID_TUTOR = p.ID_TUTOR
                    JOIN VETERINARIO v ON v.ID_VETERINARIO = c.ID_VETERINARIO
                   WHERE p_id_tutor IS NULL OR t.ID_TUTOR = p_id_tutor
                   ORDER BY c.ID_CONSULTA)
        LOOP
            IF v_qtd = 0 THEN
                DBMS_OUTPUT.PUT_LINE('=== LISTAGEM DE CONSULTAS (JSON) ===');
            END IF;
            v_qtd := v_qtd + 1;

            DBMS_OUTPUT.PUT_LINE(PKG_KV_UTIL.FN_MONTA_JSON(
                p_id_consulta   => r.ID_CONSULTA,
                p_pet           => r.NOME_PET,
                p_tutor         => r.NOME_TUTOR,
                p_veterinario   => r.NOME_VET,
                p_data_consulta => r.DATA_FMT,
                p_tipo_consulta => r.TIPO_CONSULTA,
                p_status        => r.STATUS,
                p_diagnostico   => r.DIAGNOSTICO));
        END LOOP;

        IF v_qtd = 0 THEN
            RAISE PKG_KV_UTIL.e_sem_dados;
        END IF;

        DBMS_OUTPUT.PUT_LINE('Total de consultas listadas: ' || v_qtd);
    EXCEPTION
        WHEN PKG_KV_UTIL.e_tutor_inexistente THEN
            PKG_KV_UTIL.PRC_REGISTRAR_ERRO(c_origem, PKG_KV_UTIL.c_err_tutor_inexistente,
                'Tutor ID ' || p_id_tutor || ' nao encontrado');
            DBMS_OUTPUT.PUT_LINE('AVISO: tutor ID ' || p_id_tutor || ' nao encontrado.');
        WHEN PKG_KV_UTIL.e_sem_dados THEN
            PKG_KV_UTIL.PRC_REGISTRAR_ERRO(c_origem, PKG_KV_UTIL.c_err_sem_dados,
                'Nenhuma consulta para o filtro tutor=' || NVL(TO_CHAR(p_id_tutor), 'todos'));
            DBMS_OUTPUT.PUT_LINE('AVISO: nenhuma consulta encontrada para '
                || CASE WHEN p_id_tutor IS NULL THEN 'o sistema'
                        ELSE 'o tutor ID ' || p_id_tutor END || '.');
        WHEN OTHERS THEN
            IF SQLCODE NOT BETWEEN -20999 AND -20000 THEN
                PKG_KV_UTIL.PRC_REGISTRAR_ERRO(c_origem, SQLCODE, SQLERRM);
            END IF;
            DBMS_OUTPUT.PUT_LINE('ERRO ao listar consultas: ' || SQLERRM);
    END PRC_LISTAR_CONSULTAS_JSON;

    -- -------------------------------------------------------------------------
    -- PRC_SUBTOTAIS_PAGAMENTO (Sprint 3 - procedimento 2, corrigido)
    --   Quebra manual em dois niveis (sem GROUP BY):
    --   * v_subtotal_tipo consolida cada combinacao CLINICA + TIPO_PAGAMENTO
    --     (uma linha por combinacao, nao uma linha por pagamento);
    --   * v_subtotal_clinica gera a linha "Sub Total" de cada clinica;
    --   * v_total_geral gera a linha "Total Geral".
    --   Handler ZERO_DIVIDE removido (nao ha divisao).
    -- -------------------------------------------------------------------------
    PROCEDURE PRC_SUBTOTAIS_PAGAMENTO (
        p_clinica IN FATO_PAGAMENTO.CLINICA%TYPE DEFAULT NULL
    ) IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_RELATORIO.PRC_SUBTOTAIS_PAGAMENTO';

        CURSOR c_pag IS
            SELECT CLINICA, TIPO_PAGAMENTO, VALOR
              FROM FATO_PAGAMENTO
             WHERE p_clinica IS NULL OR UPPER(CLINICA) = UPPER(TRIM(p_clinica))
             ORDER BY CLINICA, TIPO_PAGAMENTO, ID_PAGAMENTO;

        v_clinica_ant      FATO_PAGAMENTO.CLINICA%TYPE;
        v_tipo_ant         FATO_PAGAMENTO.TIPO_PAGAMENTO%TYPE;
        v_subtotal_tipo    NUMBER := 0;
        v_subtotal_clinica NUMBER := 0;
        v_total_geral      NUMBER := 0;
        v_qtd_linhas       PLS_INTEGER := 0;
    BEGIN
        FOR r IN c_pag LOOP
            IF v_qtd_linhas = 0 THEN
                DBMS_OUTPUT.PUT_LINE('RELATORIO DE PAGAMENTOS POR CLINICA E TIPO DE PAGAMENTO');
                DBMS_OUTPUT.PUT_LINE(fn_linha('CLINICA', 'TIPO PAGAMENTO', LPAD('VALOR (R$)', c_larg_valor)));
                DBMS_OUTPUT.PUT_LINE(fn_separador('-'));
            ELSE
                -- Mudou a combinacao clinica + tipo: imprime o valor consolidado
                IF r.CLINICA <> v_clinica_ant OR r.TIPO_PAGAMENTO <> v_tipo_ant THEN
                    DBMS_OUTPUT.PUT_LINE(fn_linha(v_clinica_ant, v_tipo_ant, fn_moeda(v_subtotal_tipo)));
                    v_subtotal_tipo := 0;
                END IF;
                -- Mudou a clinica: imprime o subtotal da clinica anterior
                IF r.CLINICA <> v_clinica_ant THEN
                    DBMS_OUTPUT.PUT_LINE(fn_linha(c_rotulo_subtotal, NULL, fn_moeda(v_subtotal_clinica)));
                    DBMS_OUTPUT.PUT_LINE(fn_separador('-'));
                    v_subtotal_clinica := 0;
                END IF;
            END IF;

            v_qtd_linhas       := v_qtd_linhas + 1;
            v_subtotal_tipo    := v_subtotal_tipo + r.VALOR;
            v_subtotal_clinica := v_subtotal_clinica + r.VALOR;
            v_total_geral      := v_total_geral + r.VALOR;
            v_clinica_ant      := r.CLINICA;
            v_tipo_ant         := r.TIPO_PAGAMENTO;
        END LOOP;

        IF v_qtd_linhas = 0 THEN
            RAISE PKG_KV_UTIL.e_sem_dados;
        END IF;

        -- Fecha a ultima combinacao, a ultima clinica e o total geral
        DBMS_OUTPUT.PUT_LINE(fn_linha(v_clinica_ant, v_tipo_ant, fn_moeda(v_subtotal_tipo)));
        DBMS_OUTPUT.PUT_LINE(fn_linha(c_rotulo_subtotal, NULL, fn_moeda(v_subtotal_clinica)));
        DBMS_OUTPUT.PUT_LINE(fn_separador('='));
        DBMS_OUTPUT.PUT_LINE(fn_linha(c_rotulo_total, NULL, fn_moeda(v_total_geral)));
    EXCEPTION
        WHEN PKG_KV_UTIL.e_sem_dados THEN
            PKG_KV_UTIL.PRC_REGISTRAR_ERRO(c_origem, PKG_KV_UTIL.c_err_sem_dados,
                'Nenhum pagamento para a clinica ' || NVL(p_clinica, '(todas)'));
            DBMS_OUTPUT.PUT_LINE('AVISO: nenhum pagamento encontrado'
                || CASE WHEN p_clinica IS NOT NULL THEN ' para a clinica "' || p_clinica || '"' END || '.');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_REGISTRAR_ERRO(c_origem, SQLCODE, SQLERRM);
            DBMS_OUTPUT.PUT_LINE('ERRO ao gerar relatorio de pagamentos: ' || SQLERRM);
    END PRC_SUBTOTAIS_PAGAMENTO;

    -- -------------------------------------------------------------------------
    -- Para a aplicacao: cursor vazio (tutor sem consultas) NAO e erro;
    -- tutor inexistente e parametro nulo sao.
    -- -------------------------------------------------------------------------
    PROCEDURE PRC_CONSULTAS_TUTOR (
        p_id_tutor IN  TUTOR.ID_TUTOR%TYPE,
        p_cursor   OUT SYS_REFCURSOR
    ) IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_RELATORIO.PRC_CONSULTAS_TUTOR';
        v_qtd    PLS_INTEGER;
    BEGIN
        IF p_id_tutor IS NULL THEN
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        SELECT COUNT(*) INTO v_qtd FROM TUTOR WHERE ID_TUTOR = p_id_tutor;
        IF v_qtd = 0 THEN
            RAISE PKG_KV_UTIL.e_tutor_inexistente;
        END IF;

        OPEN p_cursor FOR
            SELECT c.ID_CONSULTA,
                   p.ID_PET,
                   p.NOME                                        AS NOME_PET,
                   p.ESPECIE,
                   PKG_KV_UTIL.FN_CALCULA_IDADE_PET(p.ID_PET)    AS IDADE_PET,
                   v.NOME                                        AS NOME_VETERINARIO,
                   v.ESPECIALIDADE,
                   c.DATA_SOLICITACAO,
                   c.DATA_CONSULTA,
                   c.TIPO_CONSULTA,
                   c.STATUS,
                   c.DIAGNOSTICO,
                   c.MOTIVO_RECUSA,
                   NVL((SELECT SUM(f.VALOR)
                          FROM FATO_PAGAMENTO f
                         WHERE f.ID_CONSULTA = c.ID_CONSULTA), 0) AS VALOR_PAGO
              FROM CONSULTA c
              JOIN PET p         ON p.ID_PET = c.ID_PET
              JOIN VETERINARIO v ON v.ID_VETERINARIO = c.ID_VETERINARIO
             WHERE p.ID_TUTOR = p_id_tutor
             ORDER BY c.DATA_CONSULTA DESC, c.ID_CONSULTA DESC;
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido,
                'ID do tutor nao informado');
        WHEN PKG_KV_UTIL.e_tutor_inexistente THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_tutor_inexistente,
                'Tutor ID ' || p_id_tutor || ' nao encontrado');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END PRC_CONSULTAS_TUTOR;

    -- -------------------------------------------------------------------------
    PROCEDURE PRC_FATURAMENTO_CLINICA_TIPO (
        p_data_inicio IN  DATE,
        p_data_fim    IN  DATE,
        p_cursor      OUT SYS_REFCURSOR
    ) IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_RELATORIO.PRC_FATURAMENTO_CLINICA_TIPO';
        v_qtd    PLS_INTEGER;
    BEGIN
        IF p_data_inicio IS NULL OR p_data_fim IS NULL THEN
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        IF TRUNC(p_data_inicio) > TRUNC(p_data_fim) THEN
            RAISE PKG_KV_UTIL.e_data_invalida;
        END IF;

        SELECT COUNT(*)
          INTO v_qtd
          FROM FATO_PAGAMENTO
         WHERE DATA_PAGAMENTO >= TRUNC(p_data_inicio)
           AND DATA_PAGAMENTO <  TRUNC(p_data_fim) + 1;

        IF v_qtd = 0 THEN
            RAISE PKG_KV_UTIL.e_sem_dados;
        END IF;

        OPEN p_cursor FOR
            -- Colunas qualificadas com o alias "f" para nao confundir com os
            -- aliases CLINICA/TIPO_PAGAMENTO do SELECT no ORDER BY.
            SELECT CASE WHEN GROUPING(f.CLINICA) = 1 THEN 'TOTAL GERAL' ELSE f.CLINICA END AS CLINICA,
                   CASE WHEN GROUPING(f.CLINICA) = 0 AND GROUPING(f.TIPO_PAGAMENTO) = 1
                        THEN 'SUBTOTAL' ELSE f.TIPO_PAGAMENTO END                      AS TIPO_PAGAMENTO,
                   COUNT(*)                                                             AS QTD_PAGAMENTOS,
                   SUM(f.VALOR)                                                         AS VALOR_TOTAL,
                   GROUPING_ID(f.CLINICA, f.TIPO_PAGAMENTO)                             AS NIVEL
              FROM FATO_PAGAMENTO f
             WHERE f.DATA_PAGAMENTO >= TRUNC(p_data_inicio)
               AND f.DATA_PAGAMENTO <  TRUNC(p_data_fim) + 1
             GROUP BY ROLLUP (f.CLINICA, f.TIPO_PAGAMENTO)
             ORDER BY GROUPING(f.CLINICA), f.CLINICA, GROUPING(f.TIPO_PAGAMENTO), f.TIPO_PAGAMENTO;
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido,
                'Data inicial e data final sao obrigatorias');
        WHEN PKG_KV_UTIL.e_data_invalida THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_data_invalida,
                'Periodo invalido: inicio ' || TO_CHAR(p_data_inicio, 'DD/MM/YYYY')
                || ' maior que fim ' || TO_CHAR(p_data_fim, 'DD/MM/YYYY'));
        WHEN PKG_KV_UTIL.e_sem_dados THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_sem_dados,
                'Nenhum pagamento entre ' || TO_CHAR(p_data_inicio, 'DD/MM/YYYY')
                || ' e ' || TO_CHAR(p_data_fim, 'DD/MM/YYYY'));
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END PRC_FATURAMENTO_CLINICA_TIPO;

END PKG_KV_RELATORIO;
/

-- =============================================================================
-- PKG_KV_EXPORT  (dataset JSON para o MongoDB)
--   Datas no formato Extended JSON {"$date": "..."} para o mongoimport
--   gravar como tipo Date (permite filtros e agregacoes por data).
-- =============================================================================
CREATE OR REPLACE PACKAGE BODY PKG_KV_EXPORT AS

    c_fmt_data CONSTANT VARCHAR2(40) := 'YYYY-MM-DD"T"HH24:MI:SS"Z"';

    -- -------------------------------------------------------------------------
    FUNCTION FN_DOC_PET (
        p_id_pet IN PET.ID_PET%TYPE
    ) RETURN CLOB IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_EXPORT.FN_DOC_PET';
        v_doc    CLOB;
    BEGIN
        IF p_id_pet IS NULL THEN
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        SELECT JSON_OBJECT(
                   '_id'              VALUE p.ID_PET,
                   'nome'             VALUE p.NOME,
                   'especie'          VALUE p.ESPECIE,
                   'raca'             VALUE p.RACA,
                   'sexo'             VALUE p.SEXO,
                   'data_nascimento'  VALUE JSON_OBJECT('$date' VALUE TO_CHAR(p.DATA_NASCIMENTO, c_fmt_data)),
                   'categoria_etaria' VALUE PKG_KV_UTIL.FN_CATEGORIA_ETARIA(p.DATA_NASCIMENTO),
                   'tutor'            VALUE JSON_OBJECT(
                                                'id_tutor' VALUE t.ID_TUTOR,
                                                'nome'     VALUE t.NOME,
                                                'cpf'      VALUE t.CPF,
                                                'telefone' VALUE t.TELEFONE,
                                                'email'    VALUE t.EMAIL),
                   'consultas'        VALUE NVL((
                       SELECT JSON_ARRAYAGG(
                                  JSON_OBJECT(
                                      'id_consulta'      VALUE c.ID_CONSULTA,
                                      'data_solicitacao' VALUE JSON_OBJECT('$date' VALUE TO_CHAR(c.DATA_SOLICITACAO, c_fmt_data)),
                                      'data_consulta'    VALUE JSON_OBJECT('$date' VALUE TO_CHAR(c.DATA_CONSULTA, c_fmt_data)),
                                      'tipo'             VALUE c.TIPO_CONSULTA,
                                      'status'           VALUE c.STATUS,
                                      'diagnostico'      VALUE c.DIAGNOSTICO,
                                      'motivo_recusa'    VALUE c.MOTIVO_RECUSA,
                                      'veterinario'      VALUE JSON_OBJECT(
                                                                   'id_veterinario' VALUE v.ID_VETERINARIO,
                                                                   'nome'           VALUE v.NOME,
                                                                   'crmv'           VALUE v.CRMV,
                                                                   'especialidade'  VALUE v.ESPECIALIDADE),
                                      'pagamentos'       VALUE NVL(pg.PAGAMENTOS, '[]') FORMAT JSON)
                                  ORDER BY c.DATA_CONSULTA, c.ID_CONSULTA
                                  RETURNING CLOB)
                         FROM CONSULTA c
                         JOIN VETERINARIO v ON v.ID_VETERINARIO = c.ID_VETERINARIO
                         LEFT JOIN (SELECT f.ID_CONSULTA,
                                           JSON_ARRAYAGG(
                                               JSON_OBJECT(
                                                   'id_pagamento'   VALUE f.ID_PAGAMENTO,
                                                   'clinica'        VALUE f.CLINICA,
                                                   'tipo'           VALUE f.TIPO_PAGAMENTO,
                                                   'valor'          VALUE f.VALOR,
                                                   'data_pagamento' VALUE JSON_OBJECT('$date' VALUE TO_CHAR(f.DATA_PAGAMENTO, c_fmt_data)))
                                               ORDER BY f.ID_PAGAMENTO) AS PAGAMENTOS
                                      FROM FATO_PAGAMENTO f
                                     GROUP BY f.ID_CONSULTA) pg
                                ON pg.ID_CONSULTA = c.ID_CONSULTA
                        WHERE c.ID_PET = p.ID_PET), TO_CLOB('[]')) FORMAT JSON
                   RETURNING CLOB)
          INTO v_doc
          FROM PET p
          JOIN TUTOR t ON t.ID_TUTOR = p.ID_TUTOR
         WHERE p.ID_PET = p_id_pet;

        RETURN v_doc;
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido,
                'ID do pet nao informado para exportacao');
        WHEN NO_DATA_FOUND THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_pet_inexistente,
                'Pet ID ' || p_id_pet || ' nao encontrado para exportacao');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END FN_DOC_PET;

    -- -------------------------------------------------------------------------
    FUNCTION FN_DOC_VETERINARIO (
        p_id_veterinario IN VETERINARIO.ID_VETERINARIO%TYPE
    ) RETURN CLOB IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_EXPORT.FN_DOC_VETERINARIO';
        v_doc    CLOB;
    BEGIN
        IF p_id_veterinario IS NULL THEN
            RAISE PKG_KV_UTIL.e_parametro_invalido;
        END IF;

        SELECT JSON_OBJECT(
                   '_id'           VALUE v.ID_VETERINARIO,
                   'nome'          VALUE v.NOME,
                   'crmv'          VALUE v.CRMV,
                   'especialidade' VALUE v.ESPECIALIDADE,
                   'contato'       VALUE JSON_OBJECT(
                                             'telefone' VALUE v.TELEFONE,
                                             'email'    VALUE v.EMAIL),
                   'estatisticas'  VALUE JSON_OBJECT(
                                             'total_consultas'      VALUE (SELECT COUNT(*)
                                                                             FROM CONSULTA c
                                                                            WHERE c.ID_VETERINARIO = v.ID_VETERINARIO),
                                             'consultas_realizadas' VALUE (SELECT COUNT(*)
                                                                             FROM CONSULTA c
                                                                            WHERE c.ID_VETERINARIO = v.ID_VETERINARIO
                                                                              AND c.STATUS = 'REALIZADA'))
                   RETURNING CLOB)
          INTO v_doc
          FROM VETERINARIO v
         WHERE v.ID_VETERINARIO = p_id_veterinario;

        RETURN v_doc;
    EXCEPTION
        WHEN PKG_KV_UTIL.e_parametro_invalido THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_parametro_invalido,
                'ID do veterinario nao informado para exportacao');
        WHEN NO_DATA_FOUND THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_vet_inexistente,
                'Veterinario ID ' || p_id_veterinario || ' nao encontrado para exportacao');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END FN_DOC_VETERINARIO;

    -- -------------------------------------------------------------------------
    FUNCTION FN_EXPORTAR_PETS (
        p_especie IN PET.ESPECIE%TYPE DEFAULT NULL
    ) RETURN CLOB IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_EXPORT.FN_EXPORTAR_PETS';
        v_saida  CLOB;
        v_qtd    PLS_INTEGER := 0;
    BEGIN
        FOR r IN (SELECT ID_PET
                    FROM PET
                   WHERE p_especie IS NULL OR UPPER(ESPECIE) = UPPER(TRIM(p_especie))
                   ORDER BY ID_PET)
        LOOP
            IF v_qtd > 0 THEN
                v_saida := v_saida || ',' || CHR(10);
            END IF;
            v_saida := v_saida || FN_DOC_PET(r.ID_PET);
            v_qtd   := v_qtd + 1;
        END LOOP;

        IF v_qtd = 0 THEN
            RAISE PKG_KV_UTIL.e_sem_dados;
        END IF;

        RETURN '[' || CHR(10) || v_saida || CHR(10) || ']';
    EXCEPTION
        WHEN PKG_KV_UTIL.e_sem_dados THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_sem_dados,
                'Nenhum pet para exportar (especie: ' || NVL(p_especie, 'todas') || ')');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END FN_EXPORTAR_PETS;

    -- -------------------------------------------------------------------------
    FUNCTION FN_EXPORTAR_VETERINARIOS (
        p_especialidade IN VETERINARIO.ESPECIALIDADE%TYPE DEFAULT NULL
    ) RETURN CLOB IS
        c_origem CONSTANT VARCHAR2(60) := 'PKG_KV_EXPORT.FN_EXPORTAR_VETERINARIOS';
        v_saida  CLOB;
        v_qtd    PLS_INTEGER := 0;
    BEGIN
        FOR r IN (SELECT ID_VETERINARIO
                    FROM VETERINARIO
                   WHERE p_especialidade IS NULL
                      OR UPPER(ESPECIALIDADE) = UPPER(TRIM(p_especialidade))
                   ORDER BY ID_VETERINARIO)
        LOOP
            IF v_qtd > 0 THEN
                v_saida := v_saida || ',' || CHR(10);
            END IF;
            v_saida := v_saida || FN_DOC_VETERINARIO(r.ID_VETERINARIO);
            v_qtd   := v_qtd + 1;
        END LOOP;

        IF v_qtd = 0 THEN
            RAISE PKG_KV_UTIL.e_sem_dados;
        END IF;

        RETURN '[' || CHR(10) || v_saida || CHR(10) || ']';
    EXCEPTION
        WHEN PKG_KV_UTIL.e_sem_dados THEN
            PKG_KV_UTIL.PRC_LANCAR_ERRO(c_origem, PKG_KV_UTIL.c_err_sem_dados,
                'Nenhum veterinario para exportar (especialidade: ' || NVL(p_especialidade, 'todas') || ')');
        WHEN OTHERS THEN
            PKG_KV_UTIL.PRC_TRATAR_INESPERADO(c_origem, SQLCODE, SQLERRM);
    END FN_EXPORTAR_VETERINARIOS;

END PKG_KV_EXPORT;
/
