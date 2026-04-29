/*
KuraVet - Banco de Dados

Guilherme Macedo Martins - RM562396
Henrique Martins Oliveira - RM563620
Pedro Henrique Luiz Alves Duarte - RM563405
*/

-- Configurações do Ambiente
SET SERVEROUTPUT ON
SET VERIFY OFF

-- =========================================================================================================
-- Criação das Tabelas
-- TABELA TUTOR
CREATE TABLE tbl_tutor (
    -- Atributos
    id_tutor NUMBER GENERATED ALWAYS AS IDENTITY,
    nm_tutor VARCHAR2(100) NOT NULL,
    nr_cpf VARCHAR2(11) NOT NULL,
    ds_email VARCHAR2(100) NOT NULL,
    nr_telefone VARCHAR2(15),
    dt_cadastro DATE DEFAULT SYSDATE NOT NULL,
    -- Restrições
    CONSTRAINT pk_tutor PRIMARY KEY (id_tutor),
    CONSTRAINT un_tutor_cpf UNIQUE (nr_cpf),
    CONSTRAINT un_tutor_email UNIQUE (ds_email)
);

-- TABELA PET
CREATE TABLE tbl_pet (
    -- Atributos
    id_pet NUMBER GENERATED ALWAYS AS IDENTITY,
    id_tutor NUMBER NOT NULL,
    nm_pet VARCHAR2(50) NOT NULL,
    ds_especie VARCHAR2(30) NOT NULL,
    ds_raca VARCHAR2(50),
    dt_nascimento DATE,
    nr_score_vitalidade NUMBER(3) DEFAULT 100 NOT NULL, 
     -- Restrições
    CONSTRAINT pk_pet PRIMARY KEY (id_pet),
    CONSTRAINT fk_pet_tutor FOREIGN KEY (id_tutor) REFERENCES tbl_tutor(id_tutor),
    CONSTRAINT ck_pet_score CHECK (nr_score_vitalidade BETWEEN 0 AND 100)
);

-- TABELA EVENTOS E CONSULTAS
CREATE TABLE tbl_evento_consulta (
     -- Atributos
    id_evento NUMBER GENERATED ALWAYS AS IDENTITY,
    id_pet NUMBER NOT NULL,
    tp_evento VARCHAR2(50) NOT NULL, -- Ex: Vacina, Check-up, Cirurgia
    dt_evento DATE NOT NULL,
    ds_evento VARCHAR2(255) NOT NULL,
    nm_veterinario VARCHAR2(100),
     -- Restrições
    CONSTRAINT pk_evento PRIMARY KEY (id_evento),
    CONSTRAINT fk_evento_pet FOREIGN KEY (id_pet) REFERENCES tbl_pet(id_pet)
);

-- TABELA HISTÓRICO DE CHECK-IN 
CREATE TABLE tbl_checkin_historico (
     -- Atributos
    id_checkin NUMBER GENERATED ALWAYS AS IDENTITY,
    id_pet NUMBER NOT NULL,
    dt_checkin TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ds_status_vitalidade VARCHAR2(100) NOT NULL,
    url_foto_pet VARCHAR2(255), 
    ds_observacao VARCHAR2(500),
    -- Restrições
    CONSTRAINT pk_checkin PRIMARY KEY (id_checkin),
    CONSTRAINT fk_checkin_pet FOREIGN KEY (id_pet) REFERENCES tbl_pet(id_pet)
);

-- TABELA DE REGISTRO DE LOGS 
CREATE TABLE tbl_registro_logs (
     -- Atributos
    id_log NUMBER GENERATED ALWAYS AS IDENTITY,
    nm_procedure VARCHAR2(100) NOT NULL,
    nm_usuario VARCHAR2(50) NOT NULL,
    dt_ocorrencia TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    cd_erro VARCHAR2(20) NOT NULL,
    -- Restrições
    ds_mensagem_erro VARCHAR2(4000) NOT NULL,
    CONSTRAINT pk_registro_logs PRIMARY KEY (id_log)
);

-- =========================================================================================================
/*
-- ==============================================================================
-- CARGA DE DADOS MASSIVA PARA TESTES (40 LINHAS NO TOTAL)
-- ==============================================================================

-- ---------------------------------------------------------
-- 1. CARGA DA TABELA: TUTOR (10 Linhas)
-- ---------------------------------------------------------
INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone) VALUES ('Pedro Henrique Duarte', '11122233344', 'pedro@fiap.com.br', '11999999999');
INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone) VALUES ('Guilherme Macedo', '22233344455', 'gui@fiap.com.br', '11888888888');
INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone) VALUES ('Henrique Martins', '33344455566', 'henrique@fiap.com.br', '11777777777');
INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone) VALUES ('Ana Beatriz Costa', '44455566677', 'ana@email.com', '11911111111');
INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone) VALUES ('Carlos Silva Junior', '55566677788', 'carlos@email.com', '11922222222');
INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone) VALUES ('Marina dos Santos', '66677788899', 'marina@email.com', '11933333333');
INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone) VALUES ('Joao Pedro Lima', '77788899900', 'joao@email.com', '11944444444');
INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone) VALUES ('Beatriz Souza', '88899900011', 'bea@email.com', '11955555555');
INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone) VALUES ('Rafael Oliveira', '99900011122', 'rafael@email.com', '11966666666');
INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone) VALUES ('Juliana Alves', '00011122233', 'ju@email.com', '11977777777');

-- ---------------------------------------------------------
-- 2. CARGA DA TABELA: PET (10 Linhas)
-- Nota: Os IDs de tutor (1 a 10) referenciam a carga acima.
-- ---------------------------------------------------------
INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade) VALUES (1, 'Rex', 'Cachorro', 'Golden Retriever', TO_DATE('2020-01-10', 'YYYY-MM-DD'), 95);
INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade) VALUES (1, 'Mia', 'Gato', 'Siames', TO_DATE('2021-05-20', 'YYYY-MM-DD'), 88);
INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade) VALUES (2, 'Thor', 'Cachorro', 'Bulldog', TO_DATE('2019-11-05', 'YYYY-MM-DD'), 70);
INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade) VALUES (3, 'Nina', 'Gato', 'Persa', TO_DATE('2022-08-15', 'YYYY-MM-DD'), 100);
INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade) VALUES (3, 'Bolinha', 'Cachorro', 'Poodle', TO_DATE('2018-03-30', 'YYYY-MM-DD'), 60);
INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade) VALUES (4, 'Luna', 'Cachorro', 'Shih Tzu', TO_DATE('2023-01-12', 'YYYY-MM-DD'), 85);
INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade) VALUES (5, 'Simba', 'Gato', 'SRD', TO_DATE('2020-07-07', 'YYYY-MM-DD'), 90);
INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade) VALUES (6, 'Max', 'Cachorro', 'Labrador', TO_DATE('2017-09-22', 'YYYY-MM-DD'), 55);
INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade) VALUES (7, 'Amora', 'Gato', 'Maine Coon', TO_DATE('2021-11-30', 'YYYY-MM-DD'), 92);
INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade) VALUES (8, 'Bob', 'Cachorro', 'Pug', TO_DATE('2019-04-14', 'YYYY-MM-DD'), 75);

-- ---------------------------------------------------------
-- 3. CARGA DA TABELA: EVENTOS E CONSULTAS (10 Linhas)
-- ---------------------------------------------------------
INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario) VALUES (1, 'Vacina', TO_DATE('2026-01-15', 'YYYY-MM-DD'), 'V8 Anual', 'Dr. Carlos');
INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario) VALUES (2, 'Check-up', TO_DATE('2026-02-10', 'YYYY-MM-DD'), 'Exames de rotina', 'Dra. Ana');
INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario) VALUES (3, 'Cirurgia', TO_DATE('2026-03-05', 'YYYY-MM-DD'), 'Castracao', 'Dr. Roberto');
INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario) VALUES (4, 'Vacina', TO_DATE('2026-01-20', 'YYYY-MM-DD'), 'Antirrabica', 'Dra. Camila');
INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario) VALUES (5, 'Retorno', TO_DATE('2026-03-12', 'YYYY-MM-DD'), 'Avaliacao Pos-Cirurgia', 'Dr. Roberto');
INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario) VALUES (6, 'Exame', TO_DATE('2026-02-28', 'YYYY-MM-DD'), 'Hemograma completo', 'Dra. Ana');
INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario) VALUES (7, 'Check-up', TO_DATE('2026-04-01', 'YYYY-MM-DD'), 'Rotina Felina', 'Dra. Camila');
INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario) VALUES (8, 'Fisioterapia', TO_DATE('2026-04-10', 'YYYY-MM-DD'), 'Sessao 1 - Articulacao', 'Dr. Carlos');
INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario) VALUES (9, 'Vacina', TO_DATE('2026-03-15', 'YYYY-MM-DD'), 'Quintupla Felina', 'Dra. Camila');
INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario) VALUES (10, 'Emergencia', TO_DATE('2026-04-20', 'YYYY-MM-DD'), 'Alergia alimentar', 'Dr. Roberto');

-- ---------------------------------------------------------
-- 4. CARGA DA TABELA: HISTÓRICO DE CHECK-IN (CAREBRIDGE) (10 Linhas)
-- ---------------------------------------------------------
INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao) VALUES (3, 'Com dor', 'foto_thor_dia1.jpg', 'Ficou muito quieto e nao quis comer.');
INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao) VALUES (3, 'Recuperacao Estavel', 'foto_thor_dia2.jpg', 'Hoje ja se alimentou um pouco.');
INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao) VALUES (3, 'Excelente', 'foto_thor_dia3.jpg', 'Brincou no quintal, parece 100%.');
INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao) VALUES (5, 'Apatia', 'bolinha_1.jpg', 'Dormiu o dia todo, tosse leve.');
INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao) VALUES (5, 'Melhorando', 'bolinha_2.jpg', 'Tomou a medicacao sem reclamar.');
INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao) VALUES (8, 'Dificuldade motora', 'max_perna.jpg', 'Manquou bastante no passeio da manha.');
INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao) VALUES (8, 'Estavel', 'max_repouso.jpg', 'Fez a fisioterapia e dormiu bem.');
INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao) VALUES (10, 'Coceira intensa', 'bob_alergia.jpg', 'Manchas vermelhas na barriga.');
INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao) VALUES (1, 'Excelente', 'rex_parque.jpg', 'Correu 5km, super ativo!');
INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao) VALUES (2, 'Normal', 'mia_sofa.jpg', 'Comportamento felino padrao, dormindo muito.');

COMMIT;
*/

-- ==============
-- CARGA DE DADOS 
-- ==============

-- CARGA DO TUTOR
DECLARE
    v_nm_tutor   tbl_tutor.nm_tutor%TYPE := '&nome_do_tutor';
    v_cpf        tbl_tutor.nr_cpf%TYPE := '&cpf_somente_numeros';
    v_email      tbl_tutor.ds_email%TYPE := '&email';
    v_telefone   tbl_tutor.nr_telefone%TYPE := '&telefone';
    
    err_code     NUMBER(5);
    err_msg      VARCHAR2(200);
    
    -- Exceção 
    e_cpf_curto  EXCEPTION;
BEGIN
    IF LENGTH(v_cpf) < 11 THEN
        RAISE e_cpf_curto;
    END IF;

    INSERT INTO tbl_tutor (nm_tutor, nr_cpf, ds_email, nr_telefone)
    VALUES (v_nm_tutor, v_cpf, v_email, v_telefone);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Processo concluido com sucesso');

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        err_code := SQLCODE;
        err_msg := SUBSTR(SQLERRM, 1, 200);
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_TUTOR', USER, err_code, 'Erro de Duplicidade. ' || err_msg);
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
        
    WHEN e_cpf_curto THEN
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_TUTOR', USER, '-20001', 'Erro: O CPF informado possui menos de 11 digitos.');
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
        
    WHEN OTHERS THEN
        err_code := SQLCODE;
        err_msg := SUBSTR(SQLERRM, 1, 200);
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_TUTOR', USER, err_code, err_msg);
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
END;

-- CARGA DO PET
DECLARE
    v_id_tutor   tbl_pet.id_tutor%TYPE := &id_tutor_cadastrado;
    v_nm_pet     tbl_pet.nm_pet%TYPE := '&nome_do_pet';
    v_especie    tbl_pet.ds_especie%TYPE := '&especie';
    v_raca       tbl_pet.ds_raca%TYPE := '&raca';
    v_dt_nasc    tbl_pet.dt_nascimento%TYPE := TO_DATE('&data_nasc_DD_MM_YYYY', 'DD/MM/YYYY');
    v_score      tbl_pet.nr_score_vitalidade%TYPE := &score_vitalidade_0_a_100;
    
    err_code     NUMBER(5);
    err_msg      VARCHAR2(200);
    
    e_score_inv  EXCEPTION;
BEGIN
    IF v_score < 0 OR v_score > 100 THEN
        RAISE e_score_inv;
    END IF;

    INSERT INTO tbl_pet (id_tutor, nm_pet, ds_especie, ds_raca, dt_nascimento, nr_score_vitalidade)
    VALUES (v_id_tutor, v_nm_pet, v_especie, v_raca, v_dt_nasc, v_score);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Processo concluido com sucesso');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        err_code := SQLCODE;
        err_msg := SUBSTR(SQLERRM, 1, 200);
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_PET', USER, err_code, 'Erro: Dado nao encontrado. ' || err_msg);
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
        
    WHEN e_score_inv THEN
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_PET', USER, '-20002', 'Erro: O Score de vitalidade inserido eh invalido.');
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
        
    WHEN OTHERS THEN
        err_code := SQLCODE;
        err_msg := SUBSTR(SQLERRM, 1, 200);
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_PET', USER, err_code, err_msg);
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
END;

-- CARGA DO EVENTOS E CONSULTAS
DECLARE
    v_id_pet     tbl_evento_consulta.id_pet%TYPE := &id_pet_cadastrado;
    v_tp_evento  tbl_evento_consulta.tp_evento%TYPE := '&tipo_evento';
    v_dt_evento  tbl_evento_consulta.dt_evento%TYPE := TO_DATE('&dt_evento_DD_MM_YYYY', 'DD/MM/YYYY');
    v_ds_evento  tbl_evento_consulta.ds_evento%TYPE := '&descricao_evento';
    v_vet        tbl_evento_consulta.nm_veterinario%TYPE := '&nome_veterinario';
    
    err_code     NUMBER(5);
    err_msg      VARCHAR2(200);
    
    e_dt_futura  EXCEPTION;
BEGIN
    IF v_dt_evento > SYSDATE THEN
        RAISE e_dt_futura;
    END IF;

    INSERT INTO tbl_evento_consulta (id_pet, tp_evento, dt_evento, ds_evento, nm_veterinario)
    VALUES (v_id_pet, v_tp_evento, v_dt_evento, v_ds_evento, v_vet);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Processo concluido com sucesso');

EXCEPTION
    WHEN TOO_MANY_ROWS THEN
        err_code := SQLCODE;
        err_msg := SUBSTR(SQLERRM, 1, 200);
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_EVENTO', USER, err_code, 'Erro de integridade/linhas. ' || err_msg);
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
        
    WHEN e_dt_futura THEN
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_EVENTO', USER, '-20003', 'Erro: A data do evento nao pode ser no futuro.');
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
        
    WHEN OTHERS THEN
        err_code := SQLCODE;
        err_msg := SUBSTR(SQLERRM, 1, 200);
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_EVENTO', USER, err_code, err_msg);
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
END;

-- CARGA DO HISTÓRICO DE CHECK-IN 
DECLARE
    v_id_pet     tbl_checkin_historico.id_pet%TYPE := &id_pet_cadastrado;
    v_status     tbl_checkin_historico.ds_status_vitalidade%TYPE := '&status_vitalidade';
    v_url_foto   tbl_checkin_historico.url_foto_pet%TYPE := '&url_foto_se_houver';
    v_obs        tbl_checkin_historico.ds_observacao%TYPE := '&observacoes';
    
    err_code     NUMBER(5);
    err_msg      VARCHAR2(200);
    
    e_status_nulo EXCEPTION;
BEGIN
    IF v_status IS NULL OR v_status = '' THEN
        RAISE e_status_nulo;
    END IF;

    INSERT INTO tbl_checkin_historico (id_pet, ds_status_vitalidade, url_foto_pet, ds_observacao)
    VALUES (v_id_pet, v_status, v_url_foto, v_obs);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Processo concluido com sucesso');

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        err_code := SQLCODE;
        err_msg := SUBSTR(SQLERRM, 1, 200);
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_CHECKIN', USER, err_code, 'Erro de FK/Dado Inexistente. ' || err_msg);
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
        
    WHEN e_status_nulo THEN
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_CHECKIN', USER, '-20004', 'Erro: O Status de Vitalidade eh obrigatorio.');
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
        
    WHEN OTHERS THEN
        err_code := SQLCODE;
        err_msg := SUBSTR(SQLERRM, 1, 200);
        INSERT INTO tbl_registro_logs (nm_procedure, nm_usuario, cd_erro, ds_mensagem_erro)
        VALUES ('BLOCO_INSERE_CHECKIN', USER, err_code, err_msg);
        DBMS_OUTPUT.PUT_LINE('Processo nao concluido com sucesso');
END;

-- =========================================================================================================

-- CONSULTA 1: Engajamento Cruzado (Eventos e Check-ins por Pet/Tutor)
DECLARE

BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('TUTOR', 20) || RPAD('PET', 15) || RPAD('QTD EVENTOS', 15) || 'QTD CHECK-INS');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------');
    
    FOR reg IN (
        SELECT t.nm_tutor, 
               p.nm_pet, 
               COUNT(DISTINCT e.id_evento) AS qt_eventos,
               COUNT(DISTINCT c.id_checkin) AS qt_checkins
        FROM tbl_tutor t
        INNER JOIN tbl_pet p ON t.id_tutor = p.id_tutor
        INNER JOIN tbl_evento_consulta e ON p.id_pet = e.id_pet
        INNER JOIN tbl_checkin_historico c ON p.id_pet = c.id_pet
        GROUP BY t.nm_tutor, p.nm_pet
        ORDER BY qt_eventos DESC, t.nm_tutor ASC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(SUBSTR(reg.nm_tutor, 1, 18), 20) || 
                             RPAD(reg.nm_pet, 15) || 
                             RPAD(reg.qt_eventos, 15) || 
                             reg.qt_checkins);
    END LOOP;
END;

-- CONSULTA 2: Análise de Status de Vitalidade Pós-Evento
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('ESPECIE', 15) || RPAD('EVENTO', 15) || RPAD('STATUS ATUAL', 25) || 'TOTAL PETS');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------');
    
    FOR reg IN (
        SELECT p.ds_especie, 
               e.tp_evento, 
               c.ds_status_vitalidade, 
               COUNT(p.id_pet) AS total_pets
        FROM tbl_pet p
        INNER JOIN tbl_tutor t ON p.id_tutor = t.id_tutor
        INNER JOIN tbl_evento_consulta e ON p.id_pet = e.id_pet
        INNER JOIN tbl_checkin_historico c ON p.id_pet = c.id_pet
        GROUP BY p.ds_especie, e.tp_evento, c.ds_status_vitalidade
        ORDER BY p.ds_especie ASC, total_pets DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(reg.ds_especie, 15) || 
                             RPAD(reg.tp_evento, 15) || 
                             RPAD(SUBSTR(reg.ds_status_vitalidade, 1, 23), 25) || 
                             reg.total_pets);
    END LOOP;
END;

-- =========================================================================================================

-- RELATÓRIO 1: Alerta de Score de Vitalidade do KuraVet
DECLARE
    CURSOR c_pets IS SELECT nm_pet, ds_especie, nr_score_vitalidade FROM tbl_pet ORDER BY nr_score_vitalidade DESC;
    v_reg c_pets%ROWTYPE;
    v_status VARCHAR2(30);
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('NOME DO PET', 15) || RPAD('ESPECIE', 15) || RPAD('SCORE', 10) || 'ANALISE DO SISTEMA');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------');
    
    OPEN c_pets;
    LOOP
        FETCH c_pets INTO v_reg;
        EXIT WHEN c_pets%NOTFOUND;
        
        -- Tomada de decisão puramente com IF/ELSE
        IF v_reg.nr_score_vitalidade >= 90 THEN
            v_status := 'Excelente - Manter rotina';
        ELSIF v_reg.nr_score_vitalidade >= 70 THEN
            v_status := 'Bom - Requer atencao leve';
        ELSE
            v_status := 'ALERTA - Agendar Consulta!';
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(RPAD(v_reg.nm_pet, 15) || 
                             RPAD(v_reg.ds_especie, 15) || 
                             RPAD(v_reg.nr_score_vitalidade, 10) || 
                             v_status);
    END LOOP;
    CLOSE c_pets;
END;

-- RELATÓRIO 2: Triagem de Urgência do Módulo CareBridge
DECLARE
    CURSOR c_checkin IS 
        SELECT p.nm_pet, c.ds_status_vitalidade 
        FROM tbl_checkin_historico c 
        INNER JOIN tbl_pet p ON c.id_pet = p.id_pet;
        
    v_chk c_checkin%ROWTYPE;
    v_acao_clinica VARCHAR2(50);
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('PACIENTE (PET)', 20) || RPAD('RELATO (TUTOR)', 25) || 'ACAO RECOMENDADA');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------');
    
    OPEN c_checkin;
    LOOP
        FETCH c_checkin INTO v_chk;
        EXIT WHEN c_checkin%NOTFOUND;
        
        -- Decisão baseada no texto do check-in
        IF v_chk.ds_status_vitalidade = 'Com dor' OR v_chk.ds_status_vitalidade = 'Apatia' THEN
            v_acao_clinica := 'ACIONAR VETERINARIO (URGENCIA)';
        ELSE
            v_acao_clinica := 'Acompanhamento normal';
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(RPAD(v_chk.nm_pet, 20) || 
                             RPAD(v_chk.ds_status_vitalidade, 25) || 
                             v_acao_clinica);
    END LOOP;
    CLOSE c_checkin;
END;

-- RELATÓRIO 3: Classificação de Fidelidade (Engajamento do Tutor)
DECLARE
    CURSOR c_tutor IS 
        SELECT t.nm_tutor, COUNT(p.id_pet) as qt_pets 
        FROM tbl_tutor t 
        LEFT JOIN tbl_pet p ON t.id_tutor = p.id_tutor 
        GROUP BY t.nm_tutor
        ORDER BY qt_pets DESC;
        
    v_tutor c_tutor%ROWTYPE;
    v_categoria VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('NOME DO TUTOR', 25) || RPAD('QTD PETS', 15) || 'CATEGORIA CLIENTE');
    DBMS_OUTPUT.PUT_LINE('------------------------------------------------------------------');
    
    OPEN c_tutor;
    LOOP
        FETCH c_tutor INTO v_tutor;
        EXIT WHEN c_tutor%NOTFOUND;
        
        IF v_tutor.qt_pets >= 2 THEN
            v_categoria := 'Cliente OURO';
        ELSIF v_tutor.qt_pets = 1 THEN
            v_categoria := 'Cliente PRATA';
        ELSE
            v_categoria := 'Sem Pets Cadastrados';
        END IF;
        
        DBMS_OUTPUT.PUT_LINE(RPAD(SUBSTR(v_tutor.nm_tutor, 1, 23), 25) || 
                             RPAD(v_tutor.qt_pets, 15) || 
                             v_categoria);
    END LOOP;
    CLOSE c_tutor;
END;