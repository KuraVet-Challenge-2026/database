-- =============================================================================
-- KuraVet - Challenge FIAP 2026 x Clyvo Vet
-- Disciplina: Mastering Relational and Non-Relational Database - Sprint 4
-- Turma 2TDSPO
--   Guilherme Macedo Martins ............ RM562396
--   Pedro Henrique Luiz Alves Duarte .... RM563405
--   Henrique Martins Oliveira ........... RM563620
-- -----------------------------------------------------------------------------
-- Arquivo 03 - Especificacao (SPEC) dos packages
-- Ordem de execucao: 00 -> 01 -> 02 -> 03 -> 04 -> 05 -> 07 -> 90 -> 99
-- Sem comandos SQL*Plus (compativel com Flyway).
--
--   PKG_KV_UTIL      : catalogo de erros, excecoes nomeadas, log de erros e
--                      funcoes utilitarias (JSON, idade e categoria do pet)
--   PKG_KV_AUDITORIA : rotinas de auditoria chamadas pela TRG_AUDITORIA_CONSULTA
--   PKG_KV_CARGA     : insercoes/atualizacoes chamadas pela aplicacao (backend)
--   PKG_KV_RELATORIO : relatorios de console (DBMS_OUTPUT) e relatorios para a
--                      aplicacao (SYS_REFCURSOR)
--   PKG_KV_EXPORT    : geracao do dataset JSON para o MongoDB
--
-- Convencao de erros: as rotinas usadas pela aplicacao registram o erro em
-- LOG_ERRO_CARGA (transacao autonoma) e propagam RAISE_APPLICATION_ERROR com
-- o codigo do catalogo abaixo. As rotinas de console (DBMS_OUTPUT) registram o
-- erro e exibem a mensagem, sem propagar.
-- As rotinas de carga NAO fazem COMMIT: quem chama controla a transacao.
-- =============================================================================

CREATE OR REPLACE PACKAGE PKG_KV_UTIL AS

    -- -------------------------------------------------------------------------
    -- Catalogo de erros de negocio
    -- -------------------------------------------------------------------------
    c_err_cpf_invalido           CONSTANT PLS_INTEGER := -20001;
    c_err_crmv_invalido          CONSTANT PLS_INTEGER := -20002;
    c_err_tutor_inexistente      CONSTANT PLS_INTEGER := -20003;
    c_err_data_invalida          CONSTANT PLS_INTEGER := -20004;
    c_err_pet_inexistente        CONSTANT PLS_INTEGER := -20005;
    c_err_status_invalido        CONSTANT PLS_INTEGER := -20006;
    c_err_consulta_inexistente   CONSTANT PLS_INTEGER := -20007;
    c_err_valor_invalido         CONSTANT PLS_INTEGER := -20008;
    c_err_vet_inexistente        CONSTANT PLS_INTEGER := -20009;
    c_err_parametro_invalido     CONSTANT PLS_INTEGER := -20010;
    c_err_consulta_nao_realizada CONSTANT PLS_INTEGER := -20011;
    c_err_transicao_invalida     CONSTANT PLS_INTEGER := -20012;
    c_err_sem_dados              CONSTANT PLS_INTEGER := -20013;
    c_err_registro_duplicado     CONSTANT PLS_INTEGER := -20014;
    c_err_operacao_invalida      CONSTANT PLS_INTEGER := -20015;
    c_err_json_excede            CONSTANT PLS_INTEGER := -20016;
    c_err_inesperado             CONSTANT PLS_INTEGER := -20099;

    -- -------------------------------------------------------------------------
    -- Excecoes nomeadas ligadas ao catalogo (capturaveis pelo nome em
    -- qualquer bloco PL/SQL, inclusive depois de propagadas)
    -- -------------------------------------------------------------------------
    e_cpf_invalido           EXCEPTION;  PRAGMA EXCEPTION_INIT(e_cpf_invalido,           -20001);
    e_crmv_invalido          EXCEPTION;  PRAGMA EXCEPTION_INIT(e_crmv_invalido,          -20002);
    e_tutor_inexistente      EXCEPTION;  PRAGMA EXCEPTION_INIT(e_tutor_inexistente,      -20003);
    e_data_invalida          EXCEPTION;  PRAGMA EXCEPTION_INIT(e_data_invalida,          -20004);
    e_pet_inexistente        EXCEPTION;  PRAGMA EXCEPTION_INIT(e_pet_inexistente,        -20005);
    e_status_invalido        EXCEPTION;  PRAGMA EXCEPTION_INIT(e_status_invalido,        -20006);
    e_consulta_inexistente   EXCEPTION;  PRAGMA EXCEPTION_INIT(e_consulta_inexistente,   -20007);
    e_valor_invalido         EXCEPTION;  PRAGMA EXCEPTION_INIT(e_valor_invalido,         -20008);
    e_vet_inexistente        EXCEPTION;  PRAGMA EXCEPTION_INIT(e_vet_inexistente,        -20009);
    e_parametro_invalido     EXCEPTION;  PRAGMA EXCEPTION_INIT(e_parametro_invalido,     -20010);
    e_consulta_nao_realizada EXCEPTION;  PRAGMA EXCEPTION_INIT(e_consulta_nao_realizada, -20011);
    e_transicao_invalida     EXCEPTION;  PRAGMA EXCEPTION_INIT(e_transicao_invalida,     -20012);
    e_sem_dados              EXCEPTION;  PRAGMA EXCEPTION_INIT(e_sem_dados,              -20013);
    e_registro_duplicado     EXCEPTION;  PRAGMA EXCEPTION_INIT(e_registro_duplicado,     -20014);
    e_operacao_invalida      EXCEPTION;  PRAGMA EXCEPTION_INIT(e_operacao_invalida,      -20015);
    e_json_excede            EXCEPTION;  PRAGMA EXCEPTION_INIT(e_json_excede,            -20016);
    e_inesperado             EXCEPTION;  PRAGMA EXCEPTION_INIT(e_inesperado,             -20099);

    -- -------------------------------------------------------------------------
    -- Infraestrutura de erros
    -- -------------------------------------------------------------------------
    -- Grava em LOG_ERRO_CARGA em transacao autonoma (sobrevive a ROLLBACK).
    PROCEDURE PRC_REGISTRAR_ERRO (
        p_origem   IN VARCHAR2,
        p_cd_erro  IN NUMBER,
        p_mensagem IN VARCHAR2
    );

    -- Registra o erro e propaga RAISE_APPLICATION_ERROR(p_cd_erro, p_mensagem).
    PROCEDURE PRC_LANCAR_ERRO (
        p_origem   IN VARCHAR2,
        p_cd_erro  IN NUMBER,
        p_mensagem IN VARCHAR2
    );

    -- Uso nos handlers WHEN OTHERS: erro de negocio (-20000..-20999) ja
    -- registrado e apenas repropagado; qualquer outro vira -20099 e e registrado.
    PROCEDURE PRC_TRATAR_INESPERADO (
        p_origem  IN VARCHAR2,
        p_sqlcode IN NUMBER,
        p_sqlerrm IN VARCHAR2
    );

    -- -------------------------------------------------------------------------
    -- Funcoes utilitarias
    -- -------------------------------------------------------------------------
    -- Monta o JSON de uma consulta, escapando caracteres especiais (aspas,
    -- barra invertida e caracteres de controle como quebra de linha e TAB).
    FUNCTION FN_MONTA_JSON (
        p_id_consulta   IN NUMBER,
        p_pet           IN VARCHAR2,
        p_tutor         IN VARCHAR2,
        p_veterinario   IN VARCHAR2,
        p_data_consulta IN VARCHAR2,
        p_tipo_consulta IN VARCHAR2,
        p_status        IN VARCHAR2 DEFAULT NULL,
        p_diagnostico   IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    -- Idade exata do pet em anos e meses.
    FUNCTION FN_CALCULA_IDADE_PET (
        p_id_pet IN PET.ID_PET%TYPE
    ) RETURN VARCHAR2;

    -- Categoria etaria: Filhote (< 12 meses), Adulto (< 84 meses) ou Idoso.
    FUNCTION FN_CATEGORIA_ETARIA (
        p_data_nascimento IN DATE
    ) RETURN VARCHAR2;

END PKG_KV_UTIL;
/

CREATE OR REPLACE PACKAGE PKG_KV_AUDITORIA AS

    -- Serializa uma linha de CONSULTA em JSON (inclui DIAGNOSTICO).
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
    ) RETURN VARCHAR2;

    -- Grava a trilha em AUDITORIA_LOG (na mesma transacao da alteracao).
    PROCEDURE PRC_REGISTRAR (
        p_operacao    IN VARCHAR2,
        p_tabela      IN VARCHAR2,
        p_valores_old IN VARCHAR2,
        p_valores_new IN VARCHAR2
    );

END PKG_KV_AUDITORIA;
/

CREATE OR REPLACE PACKAGE PKG_KV_CARGA AS

    PROCEDURE PRC_CARGA_TUTOR (
        p_nome     IN  TUTOR.NOME%TYPE,
        p_cpf      IN  TUTOR.CPF%TYPE,
        p_telefone IN  TUTOR.TELEFONE%TYPE,
        p_email    IN  TUTOR.EMAIL%TYPE,
        p_endereco IN  TUTOR.ENDERECO%TYPE,
        p_id_tutor OUT TUTOR.ID_TUTOR%TYPE
    );

    PROCEDURE PRC_CARGA_VETERINARIO (
        p_nome           IN  VETERINARIO.NOME%TYPE,
        p_crmv           IN  VETERINARIO.CRMV%TYPE,
        p_especialidade  IN  VETERINARIO.ESPECIALIDADE%TYPE,
        p_telefone       IN  VETERINARIO.TELEFONE%TYPE,
        p_email          IN  VETERINARIO.EMAIL%TYPE,
        p_id_veterinario OUT VETERINARIO.ID_VETERINARIO%TYPE
    );

    PROCEDURE PRC_CARGA_PET (
        p_nome            IN  PET.NOME%TYPE,
        p_especie         IN  PET.ESPECIE%TYPE,
        p_raca            IN  PET.RACA%TYPE,
        p_data_nascimento IN  PET.DATA_NASCIMENTO%TYPE,
        p_sexo            IN  VARCHAR2,
        p_id_tutor        IN  PET.ID_TUTOR%TYPE,
        p_id_pet          OUT PET.ID_PET%TYPE
    );

    PROCEDURE PRC_CARGA_CONSULTA (
        p_id_pet         IN  CONSULTA.ID_PET%TYPE,
        p_id_veterinario IN  CONSULTA.ID_VETERINARIO%TYPE,
        p_data_consulta  IN  CONSULTA.DATA_CONSULTA%TYPE,
        p_tipo_consulta  IN  CONSULTA.TIPO_CONSULTA%TYPE,
        p_status         IN  CONSULTA.STATUS%TYPE,
        p_diagnostico    IN  CONSULTA.DIAGNOSTICO%TYPE,
        p_motivo_recusa  IN  CONSULTA.MOTIVO_RECUSA%TYPE,
        p_id_consulta    OUT CONSULTA.ID_CONSULTA%TYPE
    );

    -- Clinica registra o diagnostico: AGENDADA -> REALIZADA.
    PROCEDURE PRC_REGISTRAR_DIAGNOSTICO (
        p_id_consulta IN CONSULTA.ID_CONSULTA%TYPE,
        p_diagnostico IN CONSULTA.DIAGNOSTICO%TYPE
    );

    PROCEDURE PRC_CARGA_PAGAMENTO (
        p_id_consulta    IN  FATO_PAGAMENTO.ID_CONSULTA%TYPE,
        p_clinica        IN  FATO_PAGAMENTO.CLINICA%TYPE,
        p_tipo_pagamento IN  FATO_PAGAMENTO.TIPO_PAGAMENTO%TYPE,
        p_valor          IN  FATO_PAGAMENTO.VALOR%TYPE,
        p_data_pagamento IN  FATO_PAGAMENTO.DATA_PAGAMENTO%TYPE,
        p_id_pagamento   OUT FATO_PAGAMENTO.ID_PAGAMENTO%TYPE
    );

END PKG_KV_CARGA;
/

CREATE OR REPLACE PACKAGE PKG_KV_RELATORIO AS

    -- Console (Sprint 3, procedimento 1): consultas em JSON via FN_MONTA_JSON.
    -- p_id_tutor NULL = todas as consultas.
    PROCEDURE PRC_LISTAR_CONSULTAS_JSON (
        p_id_tutor IN TUTOR.ID_TUTOR%TYPE DEFAULT NULL
    );

    -- Console (Sprint 3, procedimento 2): valores consolidados por clinica e
    -- tipo de pagamento, subtotal por clinica e total geral (quebra manual).
    -- p_clinica NULL = todas as clinicas.
    PROCEDURE PRC_SUBTOTAIS_PAGAMENTO (
        p_clinica IN FATO_PAGAMENTO.CLINICA%TYPE DEFAULT NULL
    );

    -- Aplicacao: historico de consultas de um tutor (tela do app / portal).
    PROCEDURE PRC_CONSULTAS_TUTOR (
        p_id_tutor IN  TUTOR.ID_TUTOR%TYPE,
        p_cursor   OUT SYS_REFCURSOR
    );

    -- Aplicacao: faturamento por clinica e tipo, com subtotais e total geral
    -- (linhas com NIVEL 0 = detalhe, 1 = subtotal da clinica, 3 = total geral).
    PROCEDURE PRC_FATURAMENTO_CLINICA_TIPO (
        p_data_inicio IN  DATE,
        p_data_fim    IN  DATE,
        p_cursor      OUT SYS_REFCURSOR
    );

END PKG_KV_RELATORIO;
/

CREATE OR REPLACE PACKAGE PKG_KV_EXPORT AS

    -- Documento de um pet (colecao "pets"): tutor resumido embutido e array
    -- de consultas com veterinario resumido e pagamentos embutidos.
    FUNCTION FN_DOC_PET (
        p_id_pet IN PET.ID_PET%TYPE
    ) RETURN CLOB;

    -- Documento de um veterinario (colecao "veterinarios").
    FUNCTION FN_DOC_VETERINARIO (
        p_id_veterinario IN VETERINARIO.ID_VETERINARIO%TYPE
    ) RETURN CLOB;

    -- Array JSON pronto para "mongoimport --jsonArray". Filtro opcional.
    FUNCTION FN_EXPORTAR_PETS (
        p_especie IN PET.ESPECIE%TYPE DEFAULT NULL
    ) RETURN CLOB;

    FUNCTION FN_EXPORTAR_VETERINARIOS (
        p_especialidade IN VETERINARIO.ESPECIALIDADE%TYPE DEFAULT NULL
    ) RETURN CLOB;

END PKG_KV_EXPORT;
/
