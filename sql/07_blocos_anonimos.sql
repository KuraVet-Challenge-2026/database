-- =============================================================================
-- KuraVet - Challenge FIAP 2026 x Clyvo Vet
-- Disciplina: Mastering Relational and Non-Relational Database - Sprint 4
-- Turma 2TDSPO
--   Guilherme Macedo Martins ............ RM562396
--   Pedro Henrique Luiz Alves Duarte .... RM563405
--   Henrique Martins Oliveira ........... RM563620
-- -----------------------------------------------------------------------------
-- Arquivo 07 - Blocos anonimos da Sprint 3 (corrigidos)
-- Ordem de execucao: 00 -> 01 -> 02 -> 03 -> 04 -> 05 -> 07 -> 90 -> 99
--
-- Correcoes:
--   * ausencia de resultados verificada pelo numero de linhas percorridas
--     (PKG_KV_UTIL.e_sem_dados) em todos os blocos;
--   * status novos (SOLICITADA/RECUSADA) na tomada de decisao;
--   * categoria etaria reaproveita PKG_KV_UTIL.FN_CATEGORIA_ETARIA;
--   * valores monetarios em formato brasileiro;
--   * o bloco "relatorio completo de pagamentos" foi removido por duplicar
--     PKG_KV_RELATORIO.PRC_SUBTOTAIS_PAGAMENTO.
-- =============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET VERIFY OFF
SET LINESIZE 200

-- -----------------------------------------------------------------------------
-- B1 - Juncoes e agrupamento: consultas por tutor x veterinario e
--      faturamento por especie x clinica
-- -----------------------------------------------------------------------------
DECLARE
    v_qtd PLS_INTEGER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== B1.1 Quantidade de consultas por Tutor e Veterinario ===');
    FOR r IN (SELECT t.NOME AS TUTOR, v.NOME AS VETERINARIO, COUNT(c.ID_CONSULTA) AS QTD_CONSULTAS
                FROM TUTOR t
                JOIN PET p         ON p.ID_TUTOR = t.ID_TUTOR
                JOIN CONSULTA c    ON c.ID_PET = p.ID_PET
                JOIN VETERINARIO v ON v.ID_VETERINARIO = c.ID_VETERINARIO
               GROUP BY t.NOME, v.NOME
               ORDER BY QTD_CONSULTAS DESC, t.NOME)
    LOOP
        v_qtd := v_qtd + 1;
        DBMS_OUTPUT.PUT_LINE(RPAD(r.TUTOR, 28) || RPAD(r.VETERINARIO, 26) || r.QTD_CONSULTAS);
    END LOOP;
    IF v_qtd = 0 THEN
        RAISE PKG_KV_UTIL.e_sem_dados;
    END IF;

    v_qtd := 0;
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('=== B1.2 Faturamento por Especie do Pet e Clinica ===');
    FOR r IN (SELECT p.ESPECIE, f.CLINICA, SUM(f.VALOR) AS TOTAL_FATURADO
                FROM PET p
                JOIN CONSULTA c       ON c.ID_PET = p.ID_PET
                JOIN FATO_PAGAMENTO f ON f.ID_CONSULTA = c.ID_CONSULTA
               GROUP BY p.ESPECIE, f.CLINICA
               ORDER BY TOTAL_FATURADO DESC)
    LOOP
        v_qtd := v_qtd + 1;
        DBMS_OUTPUT.PUT_LINE(RPAD(r.ESPECIE, 12) || RPAD(r.CLINICA, 22) || 'R$ '
            || TO_CHAR(r.TOTAL_FATURADO, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.'''));
    END LOOP;
    IF v_qtd = 0 THEN
        RAISE PKG_KV_UTIL.e_sem_dados;
    END IF;
EXCEPTION
    WHEN PKG_KV_UTIL.e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('Aviso (B1): nao ha consultas/pagamentos para agrupar.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado no bloco B1: ' || SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- B2 - Consultas por veterinario e tipo de consulta
-- -----------------------------------------------------------------------------
DECLARE
    v_qtd PLS_INTEGER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== B2 Quantidade de consultas por Veterinario e Tipo de Consulta ===');
    FOR r IN (SELECT v.NOME AS VETERINARIO, c.TIPO_CONSULTA, COUNT(*) AS QTD
                FROM VETERINARIO v
                JOIN CONSULTA c ON c.ID_VETERINARIO = v.ID_VETERINARIO
                JOIN PET p      ON p.ID_PET = c.ID_PET
                JOIN TUTOR t    ON t.ID_TUTOR = p.ID_TUTOR
               GROUP BY v.NOME, c.TIPO_CONSULTA
               ORDER BY v.NOME, QTD DESC)
    LOOP
        v_qtd := v_qtd + 1;
        DBMS_OUTPUT.PUT_LINE(RPAD(r.VETERINARIO, 26) || RPAD(r.TIPO_CONSULTA, 18) || r.QTD);
    END LOOP;
    IF v_qtd = 0 THEN
        RAISE PKG_KV_UTIL.e_sem_dados;
    END IF;
EXCEPTION
    WHEN PKG_KV_UTIL.e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('Aviso (B2): nao ha consultas cadastradas.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado no bloco B2: ' || SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- B3 - Valor anterior, atual e proximo dos pagamentos
-- -----------------------------------------------------------------------------
DECLARE
    TYPE t_valores IS TABLE OF FATO_PAGAMENTO.VALOR%TYPE INDEX BY PLS_INTEGER;
    v_valores  t_valores;
    v_qtd      PLS_INTEGER := 0;
    v_anterior VARCHAR2(20);
    v_proximo  VARCHAR2(20);

    FUNCTION fmt (p_valor IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
        RETURN TO_CHAR(p_valor, 'FM999G999G990D00', 'NLS_NUMERIC_CHARACTERS='',.''');
    END fmt;
BEGIN
    FOR r IN (SELECT VALOR FROM FATO_PAGAMENTO ORDER BY ID_PAGAMENTO) LOOP
        v_qtd := v_qtd + 1;
        v_valores(v_qtd) := r.VALOR;
    END LOOP;

    IF v_qtd = 0 THEN
        RAISE PKG_KV_UTIL.e_sem_dados;
    END IF;

    DBMS_OUTPUT.PUT_LINE('=== B3 Pagamentos: anterior, atual e proximo ===');
    DBMS_OUTPUT.PUT_LINE(RPAD('LINHA', 8) || RPAD('ANTERIOR', 15) || RPAD('ATUAL', 15) || 'PROXIMO');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 50, '-'));

    FOR i IN 1 .. v_qtd LOOP
        IF i = 1 THEN
            v_anterior := 'Vazio';
        ELSE
            v_anterior := fmt(v_valores(i - 1));
        END IF;

        IF i = v_qtd THEN
            v_proximo := 'Vazio';
        ELSE
            v_proximo := fmt(v_valores(i + 1));
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(i, 8) || RPAD(v_anterior, 15) || RPAD(fmt(v_valores(i)), 15) || v_proximo);
    END LOOP;
EXCEPTION
    WHEN PKG_KV_UTIL.e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('Aviso (B3): a tabela FATO_PAGAMENTO nao possui registros.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado no bloco B3: ' || SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- B4 - Cursor explicito + tomada de decisao: categoria etaria e recomendacao
-- -----------------------------------------------------------------------------
DECLARE
    CURSOR c_pet IS
        SELECT NOME, ESPECIE, DATA_NASCIMENTO FROM PET ORDER BY DATA_NASCIMENTO;
    v_pet          c_pet%ROWTYPE;
    v_categoria    VARCHAR2(20);
    v_recomendacao VARCHAR2(60);
BEGIN
    OPEN c_pet;
    LOOP
        FETCH c_pet INTO v_pet;
        EXIT WHEN c_pet%NOTFOUND;

        IF c_pet%ROWCOUNT = 1 THEN
            DBMS_OUTPUT.PUT_LINE('=== B4 Categoria etaria e recomendacao de acompanhamento ===');
            DBMS_OUTPUT.PUT_LINE(RPAD('PET', 15) || RPAD('ESPECIE', 12) || RPAD('CATEGORIA', 12) || 'RECOMENDACAO');
            DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));
        END IF;

        v_categoria := PKG_KV_UTIL.FN_CATEGORIA_ETARIA(v_pet.DATA_NASCIMENTO);

        IF v_categoria = 'Filhote' THEN
            v_recomendacao := 'Completar protocolo de vacinas e vermifugacao';
        ELSIF v_categoria = 'Adulto' THEN
            v_recomendacao := 'Check-up anual e reforco de vacinas';
        ELSE
            v_recomendacao := 'Check-up semestral com exames cardiologicos';
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(v_pet.NOME, 15) || RPAD(v_pet.ESPECIE, 12) || RPAD(v_categoria, 12) || v_recomendacao);
    END LOOP;

    IF c_pet%ROWCOUNT = 0 THEN
        CLOSE c_pet;
        RAISE PKG_KV_UTIL.e_sem_dados;
    END IF;
    CLOSE c_pet;
EXCEPTION
    WHEN PKG_KV_UTIL.e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('Aviso (B4): nao ha pets cadastrados.');
    WHEN PKG_KV_UTIL.e_data_invalida THEN
        -- FN_CATEGORIA_ETARIA rejeita data de nascimento futura
        IF c_pet%ISOPEN THEN CLOSE c_pet; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro (B4): pet com data de nascimento invalida -> ' || SQLERRM);
    WHEN OTHERS THEN
        IF c_pet%ISOPEN THEN CLOSE c_pet; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro inesperado no bloco B4: ' || SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- B5 - Cursor explicito + tomada de decisao: acao por status da consulta
-- -----------------------------------------------------------------------------
DECLARE
    CURSOR c_cons IS
        SELECT ID_CONSULTA, TIPO_CONSULTA, STATUS FROM CONSULTA ORDER BY STATUS, ID_CONSULTA;
    v_c    c_cons%ROWTYPE;
    v_acao VARCHAR2(50);
BEGIN
    OPEN c_cons;
    LOOP
        FETCH c_cons INTO v_c;
        EXIT WHEN c_cons%NOTFOUND;

        IF c_cons%ROWCOUNT = 1 THEN
            DBMS_OUTPUT.PUT_LINE('=== B5 Acao recomendada por status da consulta ===');
            DBMS_OUTPUT.PUT_LINE(RPAD('ID', 6) || RPAD('TIPO DE CONSULTA', 20) || RPAD('STATUS', 14) || 'ACAO RECOMENDADA');
            DBMS_OUTPUT.PUT_LINE(RPAD('-', 80, '-'));
        END IF;

        CASE v_c.STATUS
            WHEN 'SOLICITADA' THEN v_acao := 'Clinica deve aprovar ou recusar';
            WHEN 'AGENDADA'   THEN v_acao := 'Enviar lembrete ao tutor';
            WHEN 'REALIZADA'  THEN v_acao := 'Arquivar prontuario e agendar retorno';
            WHEN 'CANCELADA'  THEN v_acao := 'Oferecer novo horario ao tutor';
            WHEN 'RECUSADA'   THEN v_acao := 'Informar motivo e sugerir outra clinica';
            ELSE                   v_acao := 'Status desconhecido - verificar';
        END CASE;

        DBMS_OUTPUT.PUT_LINE(RPAD(v_c.ID_CONSULTA, 6) || RPAD(v_c.TIPO_CONSULTA, 20) || RPAD(v_c.STATUS, 14) || v_acao);
    END LOOP;

    IF c_cons%ROWCOUNT = 0 THEN
        CLOSE c_cons;
        RAISE PKG_KV_UTIL.e_sem_dados;
    END IF;
    CLOSE c_cons;
EXCEPTION
    WHEN PKG_KV_UTIL.e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('Aviso (B5): nao ha consultas cadastradas.');
    WHEN OTHERS THEN
        IF c_cons%ISOPEN THEN CLOSE c_cons; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro inesperado no bloco B5: ' || SQLERRM);
END;
/

-- -----------------------------------------------------------------------------
-- B6 - Cursor explicito + tomada de decisao: categoria do tutor
-- -----------------------------------------------------------------------------
DECLARE
    CURSOR c_tutor IS
        SELECT t.NOME,
               (SELECT COUNT(*) FROM PET p WHERE p.ID_TUTOR = t.ID_TUTOR) AS QTD_PETS
          FROM TUTOR t
         ORDER BY t.NOME;
    v_t         c_tutor%ROWTYPE;
    v_categoria VARCHAR2(20);
BEGIN
    OPEN c_tutor;
    LOOP
        FETCH c_tutor INTO v_t;
        EXIT WHEN c_tutor%NOTFOUND;

        IF c_tutor%ROWCOUNT = 1 THEN
            DBMS_OUTPUT.PUT_LINE('=== B6 Categoria do tutor ===');
            DBMS_OUTPUT.PUT_LINE(RPAD('TUTOR', 30) || RPAD('QTD PETS', 10) || 'CATEGORIA');
            DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
        END IF;

        IF v_t.QTD_PETS >= 2 THEN
            v_categoria := 'Cliente Ouro';
        ELSIF v_t.QTD_PETS = 1 THEN
            v_categoria := 'Cliente Prata';
        ELSE
            v_categoria := 'Sem pets';
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(v_t.NOME, 30) || RPAD(v_t.QTD_PETS, 10) || v_categoria);
    END LOOP;

    IF c_tutor%ROWCOUNT = 0 THEN
        CLOSE c_tutor;
        RAISE PKG_KV_UTIL.e_sem_dados;
    END IF;
    CLOSE c_tutor;
EXCEPTION
    WHEN PKG_KV_UTIL.e_sem_dados THEN
        DBMS_OUTPUT.PUT_LINE('Aviso (B6): nao ha tutores cadastrados.');
    WHEN OTHERS THEN
        IF c_tutor%ISOPEN THEN CLOSE c_tutor; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro inesperado no bloco B6: ' || SQLERRM);
END;
/
