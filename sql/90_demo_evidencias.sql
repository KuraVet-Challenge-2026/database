-- =============================================================================
-- KuraVet - Challenge FIAP 2026 x Clyvo Vet
-- Disciplina: Mastering Relational and Non-Relational Database - Sprint 4
-- Turma 2TDSPO
--   Guilherme Macedo Martins ............ RM562396
--   Pedro Henrique Luiz Alves Duarte .... RM563405
--   Henrique Martins Oliveira ........... RM563620
-- -----------------------------------------------------------------------------
-- Arquivo 90 - Demonstracao e EVIDENCIAS (feedback Sprint 3)
-- Ordem de execucao: 00 -> 01 -> 02 -> 03 -> 04 -> 05 -> 07 -> 90 -> 99
--
-- Para CADA funcao e procedimento publico: 1 execucao com sucesso e pelo
-- menos 1 excecao efetivamente tratada. Cada secao EV-xx corresponde a um
-- print no documento de evidencias (docs/ROTEIRO_EVIDENCIAS.md).
--
-- Os blocos que esperam erro capturam a excecao PELO NOME
-- (PKG_KV_UTIL.e_...), o que comprova o codigo do catalogo. Se aparecer
-- outro erro, ele NAO e capturado e fica visivel na saida (sinal de defeito).
--
-- Pre-requisito: base recem-criada (00 a 05). Executar no SQL Developer com
-- "Executar Script" (F5) ou no SQLcl.
-- =============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET VERIFY OFF
SET LINESIZE 250
SET PAGESIZE 100

VARIABLE v_id_tutor    NUMBER
VARIABLE v_id_vet      NUMBER
VARIABLE v_id_pet      NUMBER
VARIABLE v_id_consulta NUMBER
VARIABLE v_id_pag      NUMBER
VARIABLE rc            REFCURSOR

-- =============================================================================
-- EV-01  PKG_KV_UTIL.FN_MONTA_JSON
-- =============================================================================
PROMPT ===== EV-01 FN_MONTA_JSON =====
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-01a] Sucesso com aspas, ponto e virgula, barra e quebra de linha:');
    DBMS_OUTPUT.PUT_LINE(PKG_KV_UTIL.FN_MONTA_JSON(
        p_id_consulta   => 1,
        p_pet           => 'Thor "Thorzinho"',
        p_tutor         => 'Ana Beatriz Souza',
        p_veterinario   => 'Dra. Patricia Gomes',
        p_data_consulta => '10/01/2025',
        p_tipo_consulta => 'Checkup',
        p_status        => 'REALIZADA',
        p_diagnostico   => 'Linha 1; C:\laudos' || CHR(10) || 'Linha 2' || CHR(9) || 'com TAB'));
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-01b] ID nulo:');
    DBMS_OUTPUT.PUT_LINE(PKG_KV_UTIL.FN_MONTA_JSON(NULL, 'Thor', 'Ana', 'Dra. Patricia', '10/01/2025', 'Checkup'));
EXCEPTION
    WHEN PKG_KV_UTIL.e_parametro_invalido THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-01c] JSON excede 4000 caracteres apos escape (2100 aspas viram 4200 caracteres):');
    DBMS_OUTPUT.PUT_LINE(PKG_KV_UTIL.FN_MONTA_JSON(1, 'Thor', 'Ana', 'Dra. Patricia', '10/01/2025', 'Checkup',
                                                   'REALIZADA', RPAD('"', 2100, '"')));
EXCEPTION
    WHEN PKG_KV_UTIL.e_json_excede THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-02  PKG_KV_UTIL.FN_CALCULA_IDADE_PET
-- =============================================================================
PROMPT ===== EV-02 FN_CALCULA_IDADE_PET =====
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-02a] Idade do pet 1 (Thor): ' || PKG_KV_UTIL.FN_CALCULA_IDADE_PET(1));
    DBMS_OUTPUT.PUT_LINE('[EV-02a] Idade do pet 11 (Pipoca): ' || PKG_KV_UTIL.FN_CALCULA_IDADE_PET(11));
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-02b] Pet inexistente (9999):');
    DBMS_OUTPUT.PUT_LINE(PKG_KV_UTIL.FN_CALCULA_IDADE_PET(9999));
EXCEPTION
    WHEN PKG_KV_UTIL.e_pet_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-02c] Data de nascimento no futuro (validacao que substituiu TOO_MANY_ROWS):');
    SAVEPOINT sp_ev02;
    UPDATE PET SET DATA_NASCIMENTO = TRUNC(SYSDATE) + 30 WHERE ID_PET = 10;
    DBMS_OUTPUT.PUT_LINE(PKG_KV_UTIL.FN_CALCULA_IDADE_PET(10));
    ROLLBACK TO sp_ev02;
EXCEPTION
    WHEN PKG_KV_UTIL.e_data_invalida THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
        ROLLBACK TO sp_ev02;
END;
/

-- =============================================================================
-- EV-03  PKG_KV_UTIL.FN_CATEGORIA_ETARIA
-- =============================================================================
PROMPT ===== EV-03 FN_CATEGORIA_ETARIA =====
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-03a] 2026-03-10 -> ' || PKG_KV_UTIL.FN_CATEGORIA_ETARIA(DATE '2026-03-10'));
    DBMS_OUTPUT.PUT_LINE('[EV-03a] 2022-03-15 -> ' || PKG_KV_UTIL.FN_CATEGORIA_ETARIA(DATE '2022-03-15'));
    DBMS_OUTPUT.PUT_LINE('[EV-03a] 2012-08-20 -> ' || PKG_KV_UTIL.FN_CATEGORIA_ETARIA(DATE '2012-08-20'));
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-03b] Data no futuro:');
    DBMS_OUTPUT.PUT_LINE(PKG_KV_UTIL.FN_CATEGORIA_ETARIA(TRUNC(SYSDATE) + 365));
EXCEPTION
    WHEN PKG_KV_UTIL.e_data_invalida THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-03c] Data nula:');
    DBMS_OUTPUT.PUT_LINE(PKG_KV_UTIL.FN_CATEGORIA_ETARIA(NULL));
EXCEPTION
    WHEN PKG_KV_UTIL.e_parametro_invalido THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-04  PKG_KV_RELATORIO.PRC_LISTAR_CONSULTAS_JSON  (procedimento 1)
--        Relatorio de console: trata, registra e exibe o aviso.
-- =============================================================================
PROMPT ===== EV-04 PRC_LISTAR_CONSULTAS_JSON =====
PROMPT [EV-04a] Sucesso - todas as consultas (consultas 10 e 12 com caracteres especiais escapados)
EXEC PKG_KV_RELATORIO.PRC_LISTAR_CONSULTAS_JSON;
PROMPT [EV-04b] Sucesso - filtro por tutor 1
EXEC PKG_KV_RELATORIO.PRC_LISTAR_CONSULTAS_JSON(p_id_tutor => 1);
PROMPT [EV-04c] Excecao tratada - tutor inexistente (9999)
EXEC PKG_KV_RELATORIO.PRC_LISTAR_CONSULTAS_JSON(p_id_tutor => 9999);
PROMPT [EV-04d] Excecao tratada - ausencia de resultados (tutor 11 nao tem consultas)
EXEC PKG_KV_RELATORIO.PRC_LISTAR_CONSULTAS_JSON(p_id_tutor => 11);

-- =============================================================================
-- EV-05  PKG_KV_RELATORIO.PRC_SUBTOTAIS_PAGAMENTO  (procedimento 2)
--        Esperado: Alphaville 825,00 | Moema 770,00 | Pinheiros 805,00
--                  Total Geral 2.400,00
-- =============================================================================
PROMPT ===== EV-05 PRC_SUBTOTAIS_PAGAMENTO =====
PROMPT [EV-05a] Sucesso - todas as clinicas (valores consolidados por clinica + tipo)
EXEC PKG_KV_RELATORIO.PRC_SUBTOTAIS_PAGAMENTO;
PROMPT [EV-05b] Sucesso - filtro por clinica
EXEC PKG_KV_RELATORIO.PRC_SUBTOTAIS_PAGAMENTO(p_clinica => 'KuraVet Moema');
PROMPT [EV-05c] Excecao tratada - clinica sem pagamentos
EXEC PKG_KV_RELATORIO.PRC_SUBTOTAIS_PAGAMENTO(p_clinica => 'KuraVet Centro');

-- =============================================================================
-- EV-06  PKG_KV_RELATORIO.PRC_CONSULTAS_TUTOR  (SYS_REFCURSOR p/ aplicacao)
-- =============================================================================
PROMPT ===== EV-06 PRC_CONSULTAS_TUTOR =====
PROMPT [EV-06a] Sucesso - historico do tutor 1
EXEC PKG_KV_RELATORIO.PRC_CONSULTAS_TUTOR(p_id_tutor => 1, p_cursor => :rc);
PRINT rc
DECLARE
    v_cursor SYS_REFCURSOR;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-06b] Tutor inexistente (9999):');
    PKG_KV_RELATORIO.PRC_CONSULTAS_TUTOR(9999, v_cursor);
EXCEPTION
    WHEN PKG_KV_UTIL.e_tutor_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_cursor SYS_REFCURSOR;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-06c] Tutor nao informado (NULL):');
    PKG_KV_RELATORIO.PRC_CONSULTAS_TUTOR(NULL, v_cursor);
EXCEPTION
    WHEN PKG_KV_UTIL.e_parametro_invalido THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-07  PKG_KV_RELATORIO.PRC_FATURAMENTO_CLINICA_TIPO  (SYS_REFCURSOR)
-- =============================================================================
PROMPT ===== EV-07 PRC_FATURAMENTO_CLINICA_TIPO =====
PROMPT [EV-07a] Sucesso - 2025 a 2026 (NIVEL 0 = detalhe, 1 = subtotal, 3 = total geral)
EXEC PKG_KV_RELATORIO.PRC_FATURAMENTO_CLINICA_TIPO(DATE '2025-01-01', DATE '2026-12-31', :rc);
PRINT rc
DECLARE
    v_cursor SYS_REFCURSOR;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-07b] Periodo invertido:');
    PKG_KV_RELATORIO.PRC_FATURAMENTO_CLINICA_TIPO(DATE '2026-12-31', DATE '2025-01-01', v_cursor);
EXCEPTION
    WHEN PKG_KV_UTIL.e_data_invalida THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_cursor SYS_REFCURSOR;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-07c] Periodo sem pagamentos (2020):');
    PKG_KV_RELATORIO.PRC_FATURAMENTO_CLINICA_TIPO(DATE '2020-01-01', DATE '2020-12-31', v_cursor);
EXCEPTION
    WHEN PKG_KV_UTIL.e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-08  PKG_KV_CARGA.PRC_CARGA_TUTOR
-- =============================================================================
PROMPT ===== EV-08 PRC_CARGA_TUTOR =====
BEGIN
    PKG_KV_CARGA.PRC_CARGA_TUTOR(
        p_nome     => 'Roberta Nascimento',
        p_cpf      => '12345678901',
        p_telefone => '(11) 98888-7777',
        p_email    => 'roberta.nascimento@email.com',
        p_endereco => 'Rua Vergueiro, 3000 - Sao Paulo/SP',
        p_id_tutor => :v_id_tutor);
    DBMS_OUTPUT.PUT_LINE('[EV-08a] Tutor inserido com ID ' || :v_id_tutor || ' (CPF normalizado para 123.456.789-01)');
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-08b] CPF invalido (3 digitos):');
    PKG_KV_CARGA.PRC_CARGA_TUTOR('Tutor Teste', '123', NULL, NULL, NULL, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_cpf_invalido THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-08c] CPF duplicado (mesmo CPF com mascara):');
    PKG_KV_CARGA.PRC_CARGA_TUTOR('Roberta Duplicada', '123.456.789-01', NULL, NULL, NULL, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_registro_duplicado THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-09  PKG_KV_CARGA.PRC_CARGA_VETERINARIO
-- =============================================================================
PROMPT ===== EV-09 PRC_CARGA_VETERINARIO =====
BEGIN
    PKG_KV_CARGA.PRC_CARGA_VETERINARIO(
        p_nome           => 'Dr. Tiago Ramos',
        p_crmv           => 'crmv-sp 99999',
        p_especialidade  => 'Odontologia',
        p_telefone       => '(11) 3222-1099',
        p_email          => 'tiago.ramos@kuravet.com',
        p_id_veterinario => :v_id_vet);
    DBMS_OUTPUT.PUT_LINE('[EV-09a] Veterinario inserido com ID ' || :v_id_vet);
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-09b] CRMV invalido:');
    PKG_KV_CARGA.PRC_CARGA_VETERINARIO('Dr. Sem CRMV', 'SP1', 'Clinica Geral', NULL, NULL, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_crmv_invalido THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-09c] CRMV duplicado:');
    PKG_KV_CARGA.PRC_CARGA_VETERINARIO('Dr. Duplicado', 'CRMV-SP 99999', 'Clinica Geral', NULL, NULL, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_registro_duplicado THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-10  PKG_KV_CARGA.PRC_CARGA_PET
-- =============================================================================
PROMPT ===== EV-10 PRC_CARGA_PET =====
BEGIN
    PKG_KV_CARGA.PRC_CARGA_PET(
        p_nome            => 'Amora',
        p_especie         => 'Gato',
        p_raca            => 'Maine Coon',
        p_data_nascimento => DATE '2023-04-10',
        p_sexo            => 'f',
        p_id_tutor        => :v_id_tutor,
        p_id_pet          => :v_id_pet);
    DBMS_OUTPUT.PUT_LINE('[EV-10a] Pet inserido com ID ' || :v_id_pet || ' para o tutor ' || :v_id_tutor);
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-10b] Tutor inexistente (9999):');
    PKG_KV_CARGA.PRC_CARGA_PET('Bolinha', 'Cachorro', 'Poodle', DATE '2021-01-01', 'M', 9999, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_tutor_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-10c] Data de nascimento no futuro:');
    PKG_KV_CARGA.PRC_CARGA_PET('Futuro', 'Cachorro', 'SRD', TRUNC(SYSDATE) + 10, 'M', 1, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_data_invalida THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-11  PKG_KV_CARGA.PRC_CARGA_CONSULTA  (INSERT dispara a auditoria)
-- =============================================================================
PROMPT ===== EV-11 PRC_CARGA_CONSULTA =====
BEGIN
    PKG_KV_CARGA.PRC_CARGA_CONSULTA(
        p_id_pet         => :v_id_pet,
        p_id_veterinario => 1,
        p_data_consulta  => TRUNC(SYSDATE) + 7,
        p_tipo_consulta  => 'Checkup',
        p_status         => 'AGENDADA',
        p_diagnostico    => NULL,
        p_motivo_recusa  => NULL,
        p_id_consulta    => :v_id_consulta);
    DBMS_OUTPUT.PUT_LINE('[EV-11a] Consulta AGENDADA inserida com ID ' || :v_id_consulta);
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-11b] Status fora do fluxo (EM_ANDAMENTO):');
    PKG_KV_CARGA.PRC_CARGA_CONSULTA(1, 1, TRUNC(SYSDATE) + 3, 'Checkup', 'EM_ANDAMENTO', NULL, NULL, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_status_invalido THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-11c] Veterinario inexistente (9999):');
    PKG_KV_CARGA.PRC_CARGA_CONSULTA(1, 9999, TRUNC(SYSDATE) + 3, 'Checkup', 'SOLICITADA', NULL, NULL, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_vet_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-11d] Consulta RECUSADA sem motivo:');
    PKG_KV_CARGA.PRC_CARGA_CONSULTA(1, 1, TRUNC(SYSDATE) + 3, 'Checkup', 'RECUSADA', NULL, NULL, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_parametro_invalido THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-12  PKG_KV_CARGA.PRC_REGISTRAR_DIAGNOSTICO  (UPDATE com DIAGNOSTICO)
-- =============================================================================
PROMPT ===== EV-12 PRC_REGISTRAR_DIAGNOSTICO =====
BEGIN
    PKG_KV_CARGA.PRC_REGISTRAR_DIAGNOSTICO(:v_id_consulta, 'Animal saudavel; peso "ideal" para a raca');
    DBMS_OUTPUT.PUT_LINE('[EV-12a] Diagnostico registrado; consulta ' || :v_id_consulta || ' agora REALIZADA');
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-12b] Transicao invalida (consulta ja REALIZADA):');
    PKG_KV_CARGA.PRC_REGISTRAR_DIAGNOSTICO(:v_id_consulta, 'Tentativa duplicada');
EXCEPTION
    WHEN PKG_KV_UTIL.e_transicao_invalida THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-12c] Consulta inexistente (99999):');
    PKG_KV_CARGA.PRC_REGISTRAR_DIAGNOSTICO(99999, 'Qualquer diagnostico');
EXCEPTION
    WHEN PKG_KV_UTIL.e_consulta_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-13  PKG_KV_CARGA.PRC_CARGA_PAGAMENTO
-- =============================================================================
PROMPT ===== EV-13 PRC_CARGA_PAGAMENTO =====
BEGIN
    PKG_KV_CARGA.PRC_CARGA_PAGAMENTO(
        p_id_consulta    => :v_id_consulta,
        p_clinica        => 'KuraVet Pinheiros',
        p_tipo_pagamento => 'Pix',
        p_valor          => 175,
        p_data_pagamento => NULL,
        p_id_pagamento   => :v_id_pag);
    DBMS_OUTPUT.PUT_LINE('[EV-13a] Pagamento inserido com ID ' || :v_id_pag);
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-13b] Pagamento de consulta nao realizada (consulta 13 AGENDADA):');
    PKG_KV_CARGA.PRC_CARGA_PAGAMENTO(13, 'KuraVet Moema', 'Pix', 120, NULL, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_consulta_nao_realizada THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-13c] Valor negativo:');
    PKG_KV_CARGA.PRC_CARGA_PAGAMENTO(1, 'KuraVet Pinheiros', 'Pix', -50, NULL, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_valor_invalido THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- Confirma a transacao das insercoes bem-sucedidas (as procedures nao fazem COMMIT)
COMMIT;

PROMPT [EV-13d] Registros inseridos pelas procedures
SELECT t.ID_TUTOR, t.NOME AS TUTOR, t.CPF, p.ID_PET, p.NOME AS PET,
       c.ID_CONSULTA, c.STATUS, c.DIAGNOSTICO, f.ID_PAGAMENTO, f.VALOR
  FROM TUTOR t
  JOIN PET p            ON p.ID_TUTOR = t.ID_TUTOR
  JOIN CONSULTA c       ON c.ID_PET = p.ID_PET
  LEFT JOIN FATO_PAGAMENTO f ON f.ID_CONSULTA = c.ID_CONSULTA
 WHERE t.ID_TUTOR = :v_id_tutor;

-- =============================================================================
-- EV-14  PKG_KV_AUDITORIA + TRG_AUDITORIA_CONSULTA
-- =============================================================================
PROMPT ===== EV-14 AUDITORIA =====
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-14a] FN_SERIALIZAR_CONSULTA (sucesso, com diagnostico):');
    DBMS_OUTPUT.PUT_LINE(PKG_KV_AUDITORIA.FN_SERIALIZAR_CONSULTA(
        1, 1, 1, DATE '2025-01-05', DATE '2025-01-10', 'Checkup', 'REALIZADA',
        'Texto com "aspas"' || CHR(10) || 'e quebra de linha', NULL));
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-14b] FN_SERIALIZAR_CONSULTA com ID nulo:');
    DBMS_OUTPUT.PUT_LINE(PKG_KV_AUDITORIA.FN_SERIALIZAR_CONSULTA(
        NULL, 1, 1, SYSDATE, SYSDATE, 'Checkup', 'AGENDADA', NULL, NULL));
EXCEPTION
    WHEN PKG_KV_UTIL.e_parametro_invalido THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-14c] PRC_REGISTRAR com operacao invalida (MERGE):');
    PKG_KV_AUDITORIA.PRC_REGISTRAR('MERGE', 'CONSULTA', NULL, '{"id_consulta":1}');
EXCEPTION
    WHEN PKG_KV_UTIL.e_operacao_invalida THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-14d] PRC_REGISTRAR de UPDATE sem valores OLD:');
    PKG_KV_AUDITORIA.PRC_REGISTRAR('UPDATE', 'CONSULTA', NULL, '{"id_consulta":1}');
EXCEPTION
    WHEN PKG_KV_UTIL.e_parametro_invalido THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

PROMPT [EV-14e] Trigger: INSERT, UPDATE (diagnostico alterado) e DELETE na consulta 900
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, STATUS)
VALUES (900, 2, 2, TRUNC(SYSDATE) + 5, 'Dermatologia', 'AGENDADA');
UPDATE CONSULTA
   SET STATUS = 'REALIZADA', DIAGNOSTICO = 'Dermatite controlada'
 WHERE ID_CONSULTA = 900;
UPDATE CONSULTA
   SET DIAGNOSTICO = 'Dermatite controlada; retorno em 30 dias'
 WHERE ID_CONSULTA = 900;
DELETE FROM CONSULTA WHERE ID_CONSULTA = 900;
COMMIT;

COLUMN OPERACAO     FORMAT A8
COLUMN STATUS_OLD   FORMAT A10
COLUMN STATUS_NEW   FORMAT A10
COLUMN DIAG_OLD     FORMAT A45
COLUMN DIAG_NEW     FORMAT A45
SELECT ID_LOG,
       OPERACAO,
       TO_CHAR(DATA_HORA, 'DD/MM/YYYY HH24:MI:SS')   AS DATA_HORA,
       JSON_VALUE(VALORES_OLD, '$.status')           AS STATUS_OLD,
       JSON_VALUE(VALORES_NEW, '$.status')           AS STATUS_NEW,
       JSON_VALUE(VALORES_OLD, '$.diagnostico')      AS DIAG_OLD,
       JSON_VALUE(VALORES_NEW, '$.diagnostico')      AS DIAG_NEW
  FROM AUDITORIA_LOG
 WHERE NVL(JSON_VALUE(VALORES_NEW, '$.id_consulta'), JSON_VALUE(VALORES_OLD, '$.id_consulta')) IN ('900', TO_CHAR(:v_id_consulta))
 ORDER BY ID_LOG;

-- =============================================================================
-- EV-15  PKG_KV_EXPORT
-- =============================================================================
PROMPT ===== EV-15 EXPORT JSON =====
SET LONG 100000
SET LONGCHUNKSIZE 100000
PROMPT [EV-15a] Documento do pet 1 (consulta 10 com aspas escapadas)
SELECT PKG_KV_EXPORT.FN_DOC_PET(1) AS DOC_PET FROM DUAL;
PROMPT [EV-15b] Documento do veterinario 3
SELECT PKG_KV_EXPORT.FN_DOC_VETERINARIO(3) AS DOC_VET FROM DUAL;
DECLARE
    v_doc CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-15c] FN_DOC_PET com pet inexistente (999):');
    v_doc := PKG_KV_EXPORT.FN_DOC_PET(999);
EXCEPTION
    WHEN PKG_KV_UTIL.e_pet_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_doc CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-15d] FN_DOC_VETERINARIO com veterinario inexistente (999):');
    v_doc := PKG_KV_EXPORT.FN_DOC_VETERINARIO(999);
EXCEPTION
    WHEN PKG_KV_UTIL.e_vet_inexistente THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_doc CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-15e] FN_EXPORTAR_PETS (sucesso): ' ||
        DBMS_LOB.GETLENGTH(PKG_KV_EXPORT.FN_EXPORTAR_PETS) || ' caracteres gerados');
    DBMS_OUTPUT.PUT_LINE('[EV-15f] FN_EXPORTAR_PETS com especie sem pets (Papagaio):');
    v_doc := PKG_KV_EXPORT.FN_EXPORTAR_PETS('Papagaio');
EXCEPTION
    WHEN PKG_KV_UTIL.e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/
DECLARE
    v_doc CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-15g] FN_EXPORTAR_VETERINARIOS (sucesso): ' ||
        DBMS_LOB.GETLENGTH(PKG_KV_EXPORT.FN_EXPORTAR_VETERINARIOS) || ' caracteres gerados');
    DBMS_OUTPUT.PUT_LINE('[EV-15h] FN_EXPORTAR_VETERINARIOS com especialidade inexistente:');
    v_doc := PKG_KV_EXPORT.FN_EXPORTAR_VETERINARIOS('Astrologia');
EXCEPTION
    WHEN PKG_KV_UTIL.e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-17  Infraestrutura de erros: PRC_TRATAR_INESPERADO / PRC_LANCAR_ERRO /
--        PRC_REGISTRAR_ERRO. Erro NAO previsto pelas validacoes (nome com
--        150 caracteres -> ORA-12899 no INSERT) e convertido em -20099,
--        com a mensagem original do Oracle registrada no log.
-- =============================================================================
PROMPT ===== EV-17 ERRO INESPERADO =====
DECLARE
    v_id NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('[EV-17] Nome do tutor com 150 caracteres (coluna aceita 100):');
    PKG_KV_CARGA.PRC_CARGA_TUTOR(RPAD('Nome muito longo', 150, 'x'), '98765432100', NULL, NULL, NULL, v_id);
EXCEPTION
    WHEN PKG_KV_UTIL.e_inesperado THEN
        DBMS_OUTPUT.PUT_LINE('   EXCECAO TRATADA -> ' || SQLERRM);
END;
/

-- =============================================================================
-- EV-16  LOG_ERRO_CARGA: todas as excecoes acima registradas (transacao
--        autonoma, sobreviveram aos ROLLBACKs). Rodar por ultimo.
-- =============================================================================
PROMPT ===== EV-16 LOG_ERRO_CARGA =====
COLUMN NM_PROCEDURE     FORMAT A45
COLUMN CD_ERRO          FORMAT A8
COLUMN DS_MENSAGEM_ERRO FORMAT A90
SELECT ID_LOG_ERRO, NM_PROCEDURE, CD_ERRO, DS_MENSAGEM_ERRO
  FROM LOG_ERRO_CARGA
 ORDER BY ID_LOG_ERRO;
