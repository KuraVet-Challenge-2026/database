--------------------------------------------------------------------------------
-- SISTEMA KURAVET - PLATAFORMA DE SAUDE PREVENTIVA CONTINUA PARA PETS
-- SCRIPT_BD.SQL - Oracle Database
--------------------------------------------------------------------------------

SET SERVEROUTPUT ON;
SET LINESIZE 200;

--------------------------------------------------------------------------------
-- 0. LIMPEZA DE OBJETOS EXISTENTES (IDEMPOTENCIA)
--------------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER TRG_AUDITORIA_CONSULTA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AUDITORIA_LOG CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE FATO_PAGAMENTO CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE CONSULTA CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE PET CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE VETERINARIO CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE TUTOR CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

--------------------------------------------------------------------------------
-- 1. DDL - TABELAS CORE
--------------------------------------------------------------------------------

CREATE TABLE TUTOR (
    ID_TUTOR        NUMBER(6)       NOT NULL,
    NOME            VARCHAR2(100)   NOT NULL,
    CPF             VARCHAR2(14)    NOT NULL,
    TELEFONE        VARCHAR2(20),
    EMAIL           VARCHAR2(100),
    ENDERECO        VARCHAR2(200),
    DATA_CADASTRO   DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT KV_PK_TUTOR PRIMARY KEY (ID_TUTOR),
    CONSTRAINT KV_UQ_TUTOR_CPF UNIQUE (CPF)
);

CREATE TABLE VETERINARIO (
    ID_VETERINARIO  NUMBER(6)       NOT NULL,
    NOME            VARCHAR2(100)   NOT NULL,
    CRMV            VARCHAR2(20)    NOT NULL,
    ESPECIALIDADE   VARCHAR2(60),
    TELEFONE        VARCHAR2(20),
    EMAIL           VARCHAR2(100),
    CONSTRAINT KV_PK_VET PRIMARY KEY (ID_VETERINARIO),
    CONSTRAINT KV_UQ_VET_CRMV UNIQUE (CRMV)
);

CREATE TABLE PET (
    ID_PET          NUMBER(6)       NOT NULL,
    NOME            VARCHAR2(60)    NOT NULL,
    ESPECIE         VARCHAR2(30)    NOT NULL,
    RACA            VARCHAR2(60),
    DATA_NASCIMENTO DATE            NOT NULL,
    SEXO            CHAR(1)         NOT NULL,
    ID_TUTOR        NUMBER(6)       NOT NULL,
    CONSTRAINT KV_PK_PET PRIMARY KEY (ID_PET),
    CONSTRAINT KV_CK_PET_SEXO CHECK (SEXO IN ('M','F')),
    CONSTRAINT KV_FK_PET_TUTOR FOREIGN KEY (ID_TUTOR) REFERENCES TUTOR(ID_TUTOR)
);

CREATE TABLE CONSULTA (
    ID_CONSULTA     NUMBER(6)       NOT NULL,
    ID_PET          NUMBER(6)       NOT NULL,
    ID_VETERINARIO  NUMBER(6)       NOT NULL,
    DATA_CONSULTA   DATE            NOT NULL,
    TIPO_CONSULTA   VARCHAR2(40)    NOT NULL,
    DIAGNOSTICO     VARCHAR2(400),
    STATUS          VARCHAR2(20)    DEFAULT 'REALIZADA' NOT NULL,
    CONSTRAINT KV_PK_CONSULTA PRIMARY KEY (ID_CONSULTA),
    CONSTRAINT KV_CK_CONS_STATUS CHECK (STATUS IN ('AGENDADA','REALIZADA','CANCELADA')),
    CONSTRAINT KV_FK_CONS_PET FOREIGN KEY (ID_PET) REFERENCES PET(ID_PET),
    CONSTRAINT KV_FK_CONS_VET FOREIGN KEY (ID_VETERINARIO) REFERENCES VETERINARIO(ID_VETERINARIO)
);

CREATE TABLE FATO_PAGAMENTO (
    ID_PAGAMENTO    NUMBER(6)       NOT NULL,
    ID_CONSULTA     NUMBER(6)       NOT NULL,
    CLINICA         VARCHAR2(60)    NOT NULL,
    TIPO_PAGAMENTO  VARCHAR2(30)    NOT NULL,
    VALOR           NUMBER(10,2)    NOT NULL,
    DATA_PAGAMENTO  DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT KV_PK_FATO_PAG PRIMARY KEY (ID_PAGAMENTO),
    CONSTRAINT KV_CK_PAG_VALOR CHECK (VALOR >= 0),
    CONSTRAINT KV_FK_PAG_CONS FOREIGN KEY (ID_CONSULTA) REFERENCES CONSULTA(ID_CONSULTA)
);

CREATE TABLE AUDITORIA_LOG (
    ID_LOG          NUMBER GENERATED ALWAYS AS IDENTITY,
    USUARIO         VARCHAR2(60),
    OPERACAO        VARCHAR2(10),
    DATA_HORA       DATE,
    TABELA_AFETADA  VARCHAR2(30),
    VALORES_OLD     VARCHAR2(4000),
    VALORES_NEW     VARCHAR2(4000),
    CONSTRAINT KV_PK_AUDITORIA_LOG PRIMARY KEY (ID_LOG)
);

--------------------------------------------------------------------------------
-- 2. DML - CARGA DE DADOS (10 REGISTROS POR TABELA)
--------------------------------------------------------------------------------

-- TUTOR
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (1,'Ana Beatriz Souza','111.222.333-44','(11) 91234-5601','ana.souza@email.com','Rua das Flores, 120 - Sao Paulo/SP', DATE '2024-01-10');
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (2,'Carlos Eduardo Lima','222.333.444-55','(11) 91234-5602','carlos.lima@email.com','Av. Paulista, 900 - Sao Paulo/SP', DATE '2024-01-15');
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (3,'Beatriz Fernandes','333.444.555-66','(21) 91234-5603','beatriz.fernandes@email.com','Rua Copacabana, 45 - Rio de Janeiro/RJ', DATE '2024-02-01');
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (4,'Diego Almeida','444.555.666-77','(31) 91234-5604','diego.almeida@email.com','Rua Minas, 78 - Belo Horizonte/MG', DATE '2024-02-20');
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (5,'Fernanda Costa','555.666.777-88','(41) 91234-5605','fernanda.costa@email.com','Rua Curitiba, 300 - Curitiba/PR', DATE '2024-03-05');
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (6,'Gabriel Rocha','666.777.888-99','(51) 91234-5606','gabriel.rocha@email.com','Av. Ipiranga, 500 - Porto Alegre/RS', DATE '2024-03-18');
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (7,'Helena Martins','777.888.999-00','(81) 91234-5607','helena.martins@email.com','Rua Recife, 150 - Recife/PE', DATE '2024-04-02');
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (8,'Igor Nogueira','888.999.000-11','(61) 91234-5608','igor.nogueira@email.com','SQN 210 - Brasilia/DF', DATE '2024-04-25');
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (9,'Juliana Pires','999.000.111-22','(85) 91234-5609','juliana.pires@email.com','Av. Beira Mar, 88 - Fortaleza/CE', DATE '2024-05-10');
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (10,'Marcos Vinicius Teixeira','000.111.222-33','(71) 91234-5610','marcos.teixeira@email.com','Rua Salvador, 60 - Salvador/BA', DATE '2024-05-30');

-- VETERINARIO
INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL) VALUES (1,'Dra. Patricia Gomes','CRMV-SP 12345','Clinica Geral','(11) 3222-1001','patricia.gomes@kuravet.com');
INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL) VALUES (2,'Dr. Rafael Andrade','CRMV-SP 12346','Dermatologia','(11) 3222-1002','rafael.andrade@kuravet.com');
INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL) VALUES (3,'Dra. Camila Duarte','CRMV-RJ 22345','Cardiologia','(21) 3222-1003','camila.duarte@kuravet.com');
INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL) VALUES (4,'Dr. Bruno Cardoso','CRMV-MG 32345','Ortopedia','(31) 3222-1004','bruno.cardoso@kuravet.com');
INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL) VALUES (5,'Dra. Larissa Ferreira','CRMV-PR 42345','Clinica Geral','(41) 3222-1005','larissa.ferreira@kuravet.com');
INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL) VALUES (6,'Dr. Eduardo Santos','CRMV-RS 52345','Cirurgia','(51) 3222-1006','eduardo.santos@kuravet.com');
INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL) VALUES (7,'Dra. Renata Barbosa','CRMV-PE 62345','Oncologia','(81) 3222-1007','renata.barbosa@kuravet.com');
INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL) VALUES (8,'Dr. Felipe Ramos','CRMV-DF 72345','Clinica Geral','(61) 3222-1008','felipe.ramos@kuravet.com');
INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL) VALUES (9,'Dra. Vanessa Lopes','CRMV-CE 82345','Nutricao','(85) 3222-1009','vanessa.lopes@kuravet.com');
INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL) VALUES (10,'Dr. Thiago Moreira','CRMV-BA 92345','Clinica Geral','(71) 3222-1010','thiago.moreira@kuravet.com');

-- PET
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (1,'Thor','Cachorro','Labrador', DATE '2022-03-15','M',1);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (2,'Mel','Gato','SRD', DATE '2021-07-20','F',2);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (3,'Bidu','Cachorro','Poodle', DATE '2019-11-05','M',3);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (4,'Luna','Gato','Siames', DATE '2023-01-10','F',4);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (5,'Rex','Cachorro','Pastor Alemao', DATE '2020-05-25','M',5);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (6,'Nina','Gato','Persa', DATE '2022-09-12','F',6);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (7,'Toby','Cachorro','Beagle', DATE '2021-02-18','M',7);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (8,'Mimi','Gato','SRD', DATE '2023-06-30','F',8);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (9,'Zeus','Cachorro','Rottweiler', DATE '2018-12-01','M',9);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (10,'Belinha','Cachorro','Shih Tzu', DATE '2024-02-14','F',10);

-- CONSULTA
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS) VALUES (1,1,1, DATE '2025-01-10','Checkup','Animal saudavel, vacinacao em dia','REALIZADA');
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS) VALUES (2,2,2, DATE '2025-02-14','Dermatologia','Dermatite alergica leve','REALIZADA');
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS) VALUES (3,3,3, DATE '2025-03-05','Cardiologia','Sopro cardiaco grau I, monitorar','REALIZADA');
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS) VALUES (4,4,1, DATE '2025-04-18','Vacinacao','Aplicada V4 felina','REALIZADA');
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS) VALUES (5,5,4, DATE '2025-05-22','Ortopedia','Displasia coxofemoral leve','REALIZADA');
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS) VALUES (6,6,5, DATE '2025-06-30','Checkup','Sem alteracoes','REALIZADA');
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS) VALUES (7,7,6, DATE '2025-07-11','Cirurgia','Castracao eletiva realizada','REALIZADA');
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS) VALUES (8,8,7, DATE '2025-08-09','Oncologia','Nodulo mamario em investigacao','REALIZADA');
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS) VALUES (9,9,8, DATE '2025-09-25','Checkup','Peso acima do ideal, dieta recomendada','REALIZADA');
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS) VALUES (10,10,9, DATE '2026-01-15','Nutricao','Ajuste de dieta para filhote','AGENDADA');

-- FATO_PAGAMENTO
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (1,1,'KuraVet Pinheiros','Pix',150.00, DATE '2025-01-10');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (2,2,'KuraVet Pinheiros','Pix',180.00, DATE '2025-02-14');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (3,3,'KuraVet Pinheiros','Cartao de Credito',220.00, DATE '2025-03-05');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (4,4,'KuraVet Moema','Pix',90.00, DATE '2025-04-18');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (5,5,'KuraVet Moema','Cartao de Credito',350.00, DATE '2025-05-22');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (6,6,'KuraVet Moema','Cartao de Credito',130.00, DATE '2025-06-30');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (7,7,'KuraVet Moema','Dinheiro',200.00, DATE '2025-07-11');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (8,8,'KuraVet Alphaville','Pix',275.00, DATE '2025-08-09');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (9,9,'KuraVet Alphaville','Cartao de Credito',310.00, DATE '2025-09-25');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (10,10,'KuraVet Alphaville','Dinheiro',95.00, DATE '2026-01-15');

COMMIT;

--------------------------------------------------------------------------------
-- 3. FUNCAO 1 - CONVERSOR JSON MANUAL (SEM FUNCOES NATIVAS DE JSON)
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_MONTA_JSON (
    p_id_consulta   IN NUMBER,
    p_pet           IN VARCHAR2,
    p_tutor         IN VARCHAR2,
    p_veterinario   IN VARCHAR2,
    p_data_consulta IN VARCHAR2,
    p_tipo_consulta IN VARCHAR2
) RETURN VARCHAR2
IS
    v_json          VARCHAR2(4000);
BEGIN
    IF p_id_consulta IS NULL THEN
        RAISE VALUE_ERROR;
    END IF;

    v_json := '{' ||
              '"id_consulta":' || TO_CHAR(p_id_consulta) || ',' ||
              '"pet":"'         || NVL(p_pet,'N/A')         || '",' ||
              '"tutor":"'       || NVL(p_tutor,'N/A')       || '",' ||
              '"veterinario":"' || NVL(p_veterinario,'N/A')   || '",' ||
              '"data_consulta":"' || NVL(p_data_consulta,'N/A') || '",' ||
              '"tipo_consulta":"' || NVL(p_tipo_consulta,'N/A') || '"' ||
              '}';

    RETURN v_json;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '{"erro":"Nenhum dado encontrado para montagem do JSON"}';
    WHEN TOO_MANY_ROWS THEN
        RETURN '{"erro":"Mais de um registro retornado para montagem do JSON"}';
    WHEN VALUE_ERROR THEN
        RETURN '{"erro":"Parametro obrigatorio invalido ou nulo"}';
    WHEN OTHERS THEN
        RETURN '{"erro":"Falha inesperada: ' || SQLERRM || '"}';
END FN_MONTA_JSON;
/

--------------------------------------------------------------------------------
-- 4. PROCEDIMENTO 1 - JOIN ENTRE TABELAS + USO DA FUNCAO JSON
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PROC_LISTAR_CONSULTAS_JSON
IS
    CURSOR c_consultas IS
        SELECT c.id_consulta,
               p.nome  AS nome_pet,
               t.nome  AS nome_tutor,
               v.nome  AS nome_vet,
               TO_CHAR(c.data_consulta,'DD/MM/YYYY') AS data_fmt,
               c.tipo_consulta
        FROM   CONSULTA c
        JOIN   PET p          ON p.id_pet = c.id_pet
        JOIN   TUTOR t        ON t.id_tutor = p.id_tutor
        JOIN   VETERINARIO v  ON v.id_veterinario = c.id_veterinario
        ORDER BY c.id_consulta;

    v_json          VARCHAR2(4000);
    v_total         NUMBER := 0;
BEGIN
    SELECT COUNT(*) INTO v_total FROM CONSULTA;

    IF v_total = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;

    DBMS_OUTPUT.PUT_LINE('=== LISTAGEM DE CONSULTAS (JSON MANUAL) ===');

    FOR r_reg IN c_consultas LOOP
        v_json := FN_MONTA_JSON(
                     p_id_consulta   => r_reg.id_consulta,
                     p_pet           => r_reg.nome_pet,
                     p_tutor         => r_reg.nome_tutor,
                     p_veterinario   => r_reg.nome_vet,
                     p_data_consulta => r_reg.data_fmt,
                     p_tipo_consulta => r_reg.tipo_consulta
                  );
        DBMS_OUTPUT.PUT_LINE(v_json);
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: Nenhuma consulta cadastrada no sistema.');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Erro: Retorno de dados excedeu o esperado.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado em PROC_LISTAR_CONSULTAS_JSON: ' || SQLERRM);
END PROC_LISTAR_CONSULTAS_JSON;
/

--------------------------------------------------------------------------------
-- 5. PROCEDIMENTO 2 - SUBTOTAIS MANUAIS (COM FORMATACAO TABULAR)
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PROC_SUBTOTAIS_PAGAMENTO
IS
    CURSOR c_pag IS
        SELECT clinica, tipo_pagamento, id_pagamento, valor
        FROM   FATO_PAGAMENTO
        ORDER BY clinica, tipo_pagamento, id_pagamento;

    r_pag               c_pag%ROWTYPE;
    v_clinica_ant       VARCHAR2(60) := NULL;
    v_tipo_ant          VARCHAR2(30) := NULL;
    v_subtotal_tipo     NUMBER(10,2) := 0;
    v_subtotal_clinica  NUMBER(10,2) := 0;
    v_total_geral       NUMBER(10,2) := 0;
    v_qtd_linhas        NUMBER       := 0;
BEGIN
    OPEN c_pag;

    -- Cabeçalho da Tabela
    DBMS_OUTPUT.PUT_LINE(RPAD('CLINICA', 25) || ' | ' || RPAD('TIPO PAGAMENTO', 20) || ' | ' || 'VALOR (R$)');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 25, '-') || '-|-' || RPAD('-', 20, '-') || '-|-' || RPAD('-', 15, '-'));

    LOOP
        FETCH c_pag INTO r_pag;
        EXIT WHEN c_pag%NOTFOUND;

        v_qtd_linhas := v_qtd_linhas + 1;

        -- QUEBRA DE CLINICA
        IF v_clinica_ant IS NOT NULL AND r_pag.clinica <> v_clinica_ant THEN
            DBMS_OUTPUT.PUT_LINE(RPAD('Sub Total', 25) || ' | ' || RPAD(' ', 20) || ' | ' || TO_CHAR(v_subtotal_clinica, 'FM999G999D00'));
            DBMS_OUTPUT.PUT_LINE(RPAD('-', 66, '-'));
            v_subtotal_clinica := 0;
            v_subtotal_tipo    := 0;
            v_tipo_ant         := NULL;
        END IF;

        v_clinica_ant := r_pag.clinica;
        v_tipo_ant := r_pag.tipo_pagamento;

        -- Imprime a linha atual
        DBMS_OUTPUT.PUT_LINE(RPAD(r_pag.clinica, 25) || ' | ' || RPAD(r_pag.tipo_pagamento, 20) || ' | ' || TO_CHAR(r_pag.valor, 'FM999G999D00'));

        -- ACUMULO MANUAL DOS TOTAIS
        v_subtotal_tipo    := v_subtotal_tipo + r_pag.valor;
        v_subtotal_clinica := v_subtotal_clinica + r_pag.valor;
        v_total_geral      := v_total_geral + r_pag.valor;
    END LOOP;

    CLOSE c_pag;

    IF v_qtd_linhas = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;

    -- FECHA O ÚLTIMO GRUPO E TOTAL GERAL
    IF v_clinica_ant IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE(RPAD('Sub Total', 25) || ' | ' || RPAD(' ', 20) || ' | ' || TO_CHAR(v_subtotal_clinica, 'FM999G999D00'));
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 66, '='));
    DBMS_OUTPUT.PUT_LINE(RPAD('Total Geral', 25) || ' | ' || RPAD(' ', 20) || ' | ' || TO_CHAR(v_total_geral, 'FM999G999D00'));

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: Nao ha registros na tabela FATO_PAGAMENTO.');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Erro: Consulta retornou mais linhas do que o esperado.');
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('Erro: Divisao por zero detectada.');
    WHEN OTHERS THEN
        IF c_pag%ISOPEN THEN
            CLOSE c_pag;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Erro inesperado: ' || SQLERRM);
END PROC_SUBTOTAIS_PAGAMENTO;
/

--------------------------------------------------------------------------------
-- 6. FUNCAO 2 - REGRA DE NEGOCIO: CALCULO DA IDADE EXATA DO PET
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION FN_CALCULA_IDADE_PET (
    p_id_pet IN NUMBER
) RETURN VARCHAR2
IS
    v_data_nasc     PET.DATA_NASCIMENTO%TYPE;
    v_meses_total   NUMBER;
    v_anos          NUMBER;
    v_meses         NUMBER;
    v_resultado     VARCHAR2(200);
BEGIN
    IF p_id_pet IS NULL THEN
        RAISE VALUE_ERROR;
    END IF;

    SELECT data_nascimento
    INTO   v_data_nasc
    FROM   PET
    WHERE  id_pet = p_id_pet;

    v_meses_total := TRUNC(MONTHS_BETWEEN(SYSDATE, v_data_nasc));

    IF v_meses_total < 0 THEN
        RAISE VALUE_ERROR;
    END IF;

    v_anos  := TRUNC(v_meses_total / 12);
    v_meses := MOD(v_meses_total, 12);

    IF v_meses_total < 1 THEN
        v_resultado := 'Filhote recem-nascido (menos de 1 mes)';
    ELSE
        v_resultado := v_anos || ' ano(s) e ' || v_meses || ' mes(es)';
    END IF;

    RETURN v_resultado;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Erro: Pet ID ' || p_id_pet || ' nao encontrado.';
    WHEN TOO_MANY_ROWS THEN
        RETURN 'Erro: Mais de um pet encontrado para o mesmo ID.';
    WHEN VALUE_ERROR THEN
        RETURN 'Erro: Parametro invalido ou data de nascimento inconsistente.';
    WHEN OTHERS THEN
        RETURN 'Erro inesperado: ' || SQLERRM;
END FN_CALCULA_IDADE_PET;
/

--------------------------------------------------------------------------------
-- 7. TRIGGER DE AUDITORIA (AFTER INSERT OR UPDATE OR DELETE) NA TABELA CONSULTA
--------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_CONSULTA
AFTER INSERT OR UPDATE OR DELETE ON CONSULTA
FOR EACH ROW
DECLARE
    v_operacao  VARCHAR2(10);
    v_old_vals  VARCHAR2(4000);
    v_new_vals  VARCHAR2(4000);
BEGIN
    IF INSERTING THEN
        v_operacao := 'INSERT';
        v_old_vals := NULL;
        v_new_vals := 'ID_CONSULTA=' || :NEW.id_consulta ||
                      ';ID_PET=' || :NEW.id_pet ||
                      ';ID_VETERINARIO=' || :NEW.id_veterinario ||
                      ';DATA_CONSULTA=' || TO_CHAR(:NEW.data_consulta,'DD/MM/YYYY') ||
                      ';TIPO_CONSULTA=' || :NEW.tipo_consulta ||
                      ';STATUS=' || :NEW.status;

    ELSIF UPDATING THEN
        v_operacao := 'UPDATE';
        v_old_vals := 'ID_CONSULTA=' || :OLD.id_consulta ||
                      ';ID_PET=' || :OLD.id_pet ||
                      ';ID_VETERINARIO=' || :OLD.id_veterinario ||
                      ';DATA_CONSULTA=' || TO_CHAR(:OLD.data_consulta,'DD/MM/YYYY') ||
                      ';TIPO_CONSULTA=' || :OLD.tipo_consulta ||
                      ';STATUS=' || :OLD.status;
        v_new_vals := 'ID_CONSULTA=' || :NEW.id_consulta ||
                      ';ID_PET=' || :NEW.id_pet ||
                      ';ID_VETERINARIO=' || :NEW.id_veterinario ||
                      ';DATA_CONSULTA=' || TO_CHAR(:NEW.data_consulta,'DD/MM/YYYY') ||
                      ';TIPO_CONSULTA=' || :NEW.tipo_consulta ||
                      ';STATUS=' || :NEW.status;

    ELSIF DELETING THEN
        v_operacao := 'DELETE';
        v_old_vals := 'ID_CONSULTA=' || :OLD.id_consulta ||
                      ';ID_PET=' || :OLD.id_pet ||
                      ';ID_VETERINARIO=' || :OLD.id_veterinario ||
                      ';DATA_CONSULTA=' || TO_CHAR(:OLD.data_consulta,'DD/MM/YYYY') ||
                      ';TIPO_CONSULTA=' || :OLD.tipo_consulta ||
                      ';STATUS=' || :OLD.status;
        v_new_vals := NULL;
    END IF;

    INSERT INTO AUDITORIA_LOG (USUARIO, OPERACAO, DATA_HORA, TABELA_AFETADA, VALORES_OLD, VALORES_NEW)
    VALUES (USER, v_operacao, SYSDATE, 'CONSULTA', v_old_vals, v_new_vals);

EXCEPTION
    -- Tratamento defensivo: a trigger NUNCA deve mascarar silenciosamente uma
    -- falha de auditoria. Cada excecao e registrada via DBMS_OUTPUT e, em
    -- seguida, relancada (RAISE) para que a transacao original tambem seja
    -- interrompida caso o log de auditoria nao possa ser gravado.
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('Erro de conversao de dados na trigger TRG_AUDITORIA_CONSULTA: ' || SQLERRM);
        RAISE;
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Erro de chave duplicada na trigger TRG_AUDITORIA_CONSULTA: ' || SQLERRM);
        RAISE;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado na trigger TRG_AUDITORIA_CONSULTA: ' || SQLERRM);
        RAISE;
END TRG_AUDITORIA_CONSULTA;
/

--------------------------------------------------------------------------------
-- 8. BLOCO DE DEMONSTRACAO / TESTES
--------------------------------------------------------------------------------

-- Teste Procedimento 1 (JOIN + JSON manual)
BEGIN PROC_LISTAR_CONSULTAS_JSON; END;
/

-- Teste Procedimento 2 (subtotais manuais)
BEGIN PROC_SUBTOTAIS_PAGAMENTO; END;
/

-- Teste Funcao 2 (idade do pet)
BEGIN
    DBMS_OUTPUT.PUT_LINE('Idade do Pet ID 1: ' || FN_CALCULA_IDADE_PET(1));
    DBMS_OUTPUT.PUT_LINE('Idade do Pet ID 10: ' || FN_CALCULA_IDADE_PET(10));
    DBMS_OUTPUT.PUT_LINE('Idade do Pet ID 999 (inexistente): ' || FN_CALCULA_IDADE_PET(999));
END;
/

-- Teste da Trigger de Auditoria (INSERT, UPDATE, DELETE em CONSULTA)
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS)
VALUES (11, 1, 2, SYSDATE, 'Retorno', 'Avaliacao de rotina pos-checkup', 'AGENDADA');

UPDATE CONSULTA SET STATUS = 'REALIZADA', DIAGNOSTICO = 'Retorno concluido sem intercorrencias' WHERE ID_CONSULTA = 11;

DELETE FROM CONSULTA WHERE ID_CONSULTA = 11;

COMMIT;

-- Conferencia do log de auditoria gerado
SELECT ID_LOG, USUARIO, OPERACAO, TABELA_AFETADA, DATA_HORA, VALORES_OLD, VALORES_NEW
FROM   AUDITORIA_LOG
ORDER  BY ID_LOG;

--------------------------------------------------------------------------------
-- FIM DO BLOCO HERDADO DA SPRINT 2 (Funcoes, Procedimentos e Trigger)
-- A PARTIR DAQUI: NOVOS REQUISITOS DA SPRINT 3, CONFORME FEEDBACK DO PROFESSOR
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- 9. TABELA DE LOG DE ERROS DE CARGA (Sprint 3)
--------------------------------------------------------------------------------
-- Registra falhas ocorridas durante a execucao das procedures de carga de dados:
-- nome da procedure, usuario, data/hora, codigo do erro e mensagem do erro.
BEGIN EXECUTE IMMEDIATE 'DROP TABLE LOG_ERRO_CARGA CASCADE CONSTRAINTS PURGE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE LOG_ERRO_CARGA (
    ID_LOG_ERRO      NUMBER GENERATED ALWAYS AS IDENTITY,
    NM_PROCEDURE     VARCHAR2(60)    NOT NULL,
    NM_USUARIO       VARCHAR2(60)    NOT NULL,
    DT_OCORRENCIA    DATE            DEFAULT SYSDATE NOT NULL,
    CD_ERRO          VARCHAR2(20)    NOT NULL,
    DS_MENSAGEM_ERRO VARCHAR2(500)   NOT NULL,
    CONSTRAINT KV_PK_LOG_ERRO_CARGA PRIMARY KEY (ID_LOG_ERRO)
);

--------------------------------------------------------------------------------
-- 10. SEQUENCES PARA GERACAO DE CHAVES NAS PROCEDURES DE CARGA
--------------------------------------------------------------------------------
-- Comecam em 100 para nao colidir com os IDs 1 a 10 ja carregados na Secao 2.
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_KV_TUTOR'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_KV_VETERINARIO'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_KV_PET'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_KV_CONSULTA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_KV_PAGAMENTO'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE SEQUENCE SEQ_KV_TUTOR       START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_KV_VETERINARIO START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_KV_PET         START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_KV_CONSULTA    START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_KV_PAGAMENTO   START WITH 100 INCREMENT BY 1 NOCACHE;

--------------------------------------------------------------------------------
-- 11. PROCEDURES DE CARGA DE DADOS (1 POR TABELA, POR PASSAGEM DE PARAMETRO)
--------------------------------------------------------------------------------
-- Cada procedure: (a) recebe os dados via parametros IN (sem hard-code),
-- (b) valida uma regra de negocio especifica, (c) grava o registro,
-- (d) trata no minimo 3 excecoes distintas (incluindo OTHERS),
-- (e) grava qualquer falha em LOG_ERRO_CARGA com procedure, usuario, data,
--     codigo do erro e mensagem.

-- 11.1 PRC_CARGA_TUTOR ----------------------------------------------------------
CREATE OR REPLACE PROCEDURE PRC_CARGA_TUTOR (
    p_nome      IN TUTOR.NOME%TYPE,
    p_cpf       IN TUTOR.CPF%TYPE,
    p_telefone  IN TUTOR.TELEFONE%TYPE,
    p_email     IN TUTOR.EMAIL%TYPE,
    p_endereco  IN TUTOR.ENDERECO%TYPE
) IS
    v_id_tutor      TUTOR.ID_TUTOR%TYPE;
    e_cpf_invalido  EXCEPTION;
BEGIN
    -- Regra de negocio: CPF deve ser informado e ter ao menos 11 digitos numericos
    IF p_cpf IS NULL OR LENGTH(REGEXP_REPLACE(p_cpf, '[^0-9]', '')) < 11 THEN
        RAISE e_cpf_invalido;
    END IF;

    v_id_tutor := SEQ_KV_TUTOR.NEXTVAL;

    INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO)
    VALUES (v_id_tutor, p_nome, p_cpf, p_telefone, p_email, p_endereco, SYSDATE);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK: Tutor "' || p_nome || '" cadastrado com ID_TUTOR = ' || v_id_tutor);

EXCEPTION
    WHEN e_cpf_invalido THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_TUTOR', USER, SYSDATE, '-20001',
                'CPF invalido ou nao informado para o tutor ' || NVL(p_nome, '(nome nao informado)'));
        DBMS_OUTPUT.PUT_LINE('FALHA: CPF invalido para o tutor "' || p_nome || '".');
    WHEN DUP_VAL_ON_INDEX THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_TUTOR', USER, SYSDATE, SQLCODE, SUBSTR('CPF ja cadastrado: ' || SQLERRM, 1, 480));
        DBMS_OUTPUT.PUT_LINE('FALHA: CPF ja cadastrado para o tutor "' || p_nome || '".');
    WHEN OTHERS THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_TUTOR', USER, SYSDATE, SQLCODE, SUBSTR(SQLERRM, 1, 480));
        DBMS_OUTPUT.PUT_LINE('FALHA inesperada ao cadastrar tutor "' || p_nome || '": ' || SQLERRM);
END PRC_CARGA_TUTOR;
/

-- 11.2 PRC_CARGA_VETERINARIO -----------------------------------------------------
CREATE OR REPLACE PROCEDURE PRC_CARGA_VETERINARIO (
    p_nome          IN VETERINARIO.NOME%TYPE,
    p_crmv          IN VETERINARIO.CRMV%TYPE,
    p_especialidade IN VETERINARIO.ESPECIALIDADE%TYPE,
    p_telefone      IN VETERINARIO.TELEFONE%TYPE,
    p_email         IN VETERINARIO.EMAIL%TYPE
) IS
    v_id_vet        VETERINARIO.ID_VETERINARIO%TYPE;
    e_crmv_invalido EXCEPTION;
BEGIN
    -- Regra de negocio: CRMV obrigatorio, com no minimo 5 caracteres
    IF p_crmv IS NULL OR LENGTH(TRIM(p_crmv)) < 5 THEN
        RAISE e_crmv_invalido;
    END IF;

    v_id_vet := SEQ_KV_VETERINARIO.NEXTVAL;

    INSERT INTO VETERINARIO (ID_VETERINARIO, NOME, CRMV, ESPECIALIDADE, TELEFONE, EMAIL)
    VALUES (v_id_vet, p_nome, p_crmv, p_especialidade, p_telefone, p_email);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK: Veterinario "' || p_nome || '" cadastrado com ID_VETERINARIO = ' || v_id_vet);

EXCEPTION
    WHEN e_crmv_invalido THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_VETERINARIO', USER, SYSDATE, '-20002',
                'CRMV invalido ou nao informado para o veterinario ' || NVL(p_nome, '(nome nao informado)'));
        DBMS_OUTPUT.PUT_LINE('FALHA: CRMV invalido para o veterinario "' || p_nome || '".');
    WHEN DUP_VAL_ON_INDEX THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_VETERINARIO', USER, SYSDATE, SQLCODE, SUBSTR('CRMV ja cadastrado: ' || SQLERRM, 1, 480));
        DBMS_OUTPUT.PUT_LINE('FALHA: CRMV ja cadastrado para o veterinario "' || p_nome || '".');
    WHEN OTHERS THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_VETERINARIO', USER, SYSDATE, SQLCODE, SUBSTR(SQLERRM, 1, 480));
        DBMS_OUTPUT.PUT_LINE('FALHA inesperada ao cadastrar veterinario "' || p_nome || '": ' || SQLERRM);
END PRC_CARGA_VETERINARIO;
/

-- 11.3 PRC_CARGA_PET --------------------------------------------------------------
CREATE OR REPLACE PROCEDURE PRC_CARGA_PET (
    p_nome            IN PET.NOME%TYPE,
    p_especie         IN PET.ESPECIE%TYPE,
    p_raca            IN PET.RACA%TYPE,
    p_data_nascimento IN PET.DATA_NASCIMENTO%TYPE,
    p_sexo            IN PET.SEXO%TYPE,
    p_id_tutor        IN PET.ID_TUTOR%TYPE
) IS
    v_id_pet             PET.ID_PET%TYPE;
    v_qtd_tutor          NUMBER;
    e_tutor_inexistente  EXCEPTION;
    e_data_nasc_futura   EXCEPTION;
BEGIN
    -- Regra de negocio 1: o tutor referenciado precisa existir
    SELECT COUNT(*) INTO v_qtd_tutor FROM TUTOR WHERE id_tutor = p_id_tutor;
    IF v_qtd_tutor = 0 THEN
        RAISE e_tutor_inexistente;
    END IF;

    -- Regra de negocio 2: data de nascimento nao pode ser no futuro
    IF p_data_nascimento > SYSDATE THEN
        RAISE e_data_nasc_futura;
    END IF;

    v_id_pet := SEQ_KV_PET.NEXTVAL;

    INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR)
    VALUES (v_id_pet, p_nome, p_especie, p_raca, p_data_nascimento, p_sexo, p_id_tutor);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK: Pet "' || p_nome || '" cadastrado com ID_PET = ' || v_id_pet);

EXCEPTION
    WHEN e_tutor_inexistente THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_PET', USER, SYSDATE, '-20003',
                'ID_TUTOR ' || p_id_tutor || ' nao existe para o pet ' || NVL(p_nome, '(nome nao informado)'));
        DBMS_OUTPUT.PUT_LINE('FALHA: tutor inexistente para o pet "' || p_nome || '".');
    WHEN e_data_nasc_futura THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_PET', USER, SYSDATE, '-20004',
                'Data de nascimento futura informada para o pet ' || NVL(p_nome, '(nome nao informado)'));
        DBMS_OUTPUT.PUT_LINE('FALHA: data de nascimento futura para o pet "' || p_nome || '".');
    WHEN OTHERS THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_PET', USER, SYSDATE, SQLCODE, SUBSTR(SQLERRM, 1, 480));
        DBMS_OUTPUT.PUT_LINE('FALHA inesperada ao cadastrar pet "' || p_nome || '": ' || SQLERRM);
END PRC_CARGA_PET;
/

-- 11.4 PRC_CARGA_CONSULTA ----------------------------------------------------------
CREATE OR REPLACE PROCEDURE PRC_CARGA_CONSULTA (
    p_id_pet         IN CONSULTA.ID_PET%TYPE,
    p_id_veterinario IN CONSULTA.ID_VETERINARIO%TYPE,
    p_data_consulta  IN CONSULTA.DATA_CONSULTA%TYPE,
    p_tipo_consulta  IN CONSULTA.TIPO_CONSULTA%TYPE,
    p_diagnostico    IN CONSULTA.DIAGNOSTICO%TYPE,
    p_status         IN CONSULTA.STATUS%TYPE
) IS
    v_id_consulta     CONSULTA.ID_CONSULTA%TYPE;
    v_qtd_pet         NUMBER;
    e_pet_inexistente EXCEPTION;
    e_status_invalido EXCEPTION;
BEGIN
    -- Regra de negocio 1: o pet referenciado precisa existir
    SELECT COUNT(*) INTO v_qtd_pet FROM PET WHERE id_pet = p_id_pet;
    IF v_qtd_pet = 0 THEN
        RAISE e_pet_inexistente;
    END IF;

    -- Regra de negocio 2: status deve pertencer ao dominio valido
    IF p_status NOT IN ('AGENDADA', 'REALIZADA', 'CANCELADA') THEN
        RAISE e_status_invalido;
    END IF;

    v_id_consulta := SEQ_KV_CONSULTA.NEXTVAL;

    INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_CONSULTA, TIPO_CONSULTA, DIAGNOSTICO, STATUS)
    VALUES (v_id_consulta, p_id_pet, p_id_veterinario, p_data_consulta, p_tipo_consulta, p_diagnostico, p_status);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK: Consulta cadastrada com ID_CONSULTA = ' || v_id_consulta);

EXCEPTION
    WHEN e_pet_inexistente THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_CONSULTA', USER, SYSDATE, '-20005',
                'ID_PET ' || p_id_pet || ' nao existe para a nova consulta');
        DBMS_OUTPUT.PUT_LINE('FALHA: pet inexistente (ID_PET = ' || p_id_pet || ').');
    WHEN e_status_invalido THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_CONSULTA', USER, SYSDATE, '-20006',
                'Status invalido informado: ' || NVL(p_status, '(nulo)'));
        DBMS_OUTPUT.PUT_LINE('FALHA: status invalido "' || p_status || '".');
    WHEN OTHERS THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_CONSULTA', USER, SYSDATE, SQLCODE, SUBSTR(SQLERRM, 1, 480));
        DBMS_OUTPUT.PUT_LINE('FALHA inesperada ao cadastrar consulta: ' || SQLERRM);
END PRC_CARGA_CONSULTA;
/

-- 11.5 PRC_CARGA_PAGAMENTO ---------------------------------------------------------
CREATE OR REPLACE PROCEDURE PRC_CARGA_PAGAMENTO (
    p_id_consulta    IN FATO_PAGAMENTO.ID_CONSULTA%TYPE,
    p_clinica        IN FATO_PAGAMENTO.CLINICA%TYPE,
    p_tipo_pagamento IN FATO_PAGAMENTO.TIPO_PAGAMENTO%TYPE,
    p_valor          IN FATO_PAGAMENTO.VALOR%TYPE,
    p_data_pagamento IN FATO_PAGAMENTO.DATA_PAGAMENTO%TYPE
) IS
    v_id_pagamento      FATO_PAGAMENTO.ID_PAGAMENTO%TYPE;
    v_qtd_consulta      NUMBER;
    e_consulta_inexiste EXCEPTION;
    e_valor_invalido    EXCEPTION;
BEGIN
    -- Regra de negocio 1: a consulta referenciada precisa existir
    SELECT COUNT(*) INTO v_qtd_consulta FROM CONSULTA WHERE id_consulta = p_id_consulta;
    IF v_qtd_consulta = 0 THEN
        RAISE e_consulta_inexiste;
    END IF;

    -- Regra de negocio 2: valor do pagamento deve ser positivo
    IF p_valor IS NULL OR p_valor <= 0 THEN
        RAISE e_valor_invalido;
    END IF;

    v_id_pagamento := SEQ_KV_PAGAMENTO.NEXTVAL;

    INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO)
    VALUES (v_id_pagamento, p_id_consulta, p_clinica, p_tipo_pagamento, p_valor, p_data_pagamento);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK: Pagamento cadastrado com ID_PAGAMENTO = ' || v_id_pagamento);

EXCEPTION
    WHEN e_consulta_inexiste THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_PAGAMENTO', USER, SYSDATE, '-20007',
                'ID_CONSULTA ' || p_id_consulta || ' nao existe para o pagamento');
        DBMS_OUTPUT.PUT_LINE('FALHA: consulta inexistente (ID_CONSULTA = ' || p_id_consulta || ').');
    WHEN e_valor_invalido THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_PAGAMENTO', USER, SYSDATE, '-20008',
                'Valor invalido (<= 0) informado para pagamento da consulta ' || p_id_consulta);
        DBMS_OUTPUT.PUT_LINE('FALHA: valor invalido para pagamento da consulta ' || p_id_consulta || '.');
    WHEN OTHERS THEN
        INSERT INTO LOG_ERRO_CARGA (NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO)
        VALUES ('PRC_CARGA_PAGAMENTO', USER, SYSDATE, SQLCODE, SUBSTR(SQLERRM, 1, 480));
        DBMS_OUTPUT.PUT_LINE('FALHA inesperada ao cadastrar pagamento: ' || SQLERRM);
END PRC_CARGA_PAGAMENTO;
/

--------------------------------------------------------------------------------
-- 12. DEMONSTRACAO DAS PROCEDURES DE CARGA (casos de sucesso e de erro)
--------------------------------------------------------------------------------
-- Cada procedure e chamada por passagem de parametro (sem hard-code no corpo).
-- Em cada caso e feita 1 chamada valida e 1 chamada invalida, para evidenciar
-- o tratamento de excecao e o registro em LOG_ERRO_CARGA.

BEGIN
    PRC_CARGA_TUTOR('Roberta Nascimento', '123.456.789-01', '(11) 90000-1001', 'roberta.nascimento@email.com', 'Rua Nova, 10 - Sao Paulo/SP');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha nao tratada na chamada de PRC_CARGA_TUTOR: ' || SQLERRM);
END;
/
BEGIN
    PRC_CARGA_TUTOR('Tutor CPF Invalido', '123', '(11) 90000-1002', 'invalido@email.com', 'Rua Teste, 20');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha nao tratada na chamada de PRC_CARGA_TUTOR: ' || SQLERRM);
END;
/

BEGIN
    PRC_CARGA_VETERINARIO('Dr. Vinicius Prado', 'CRMV-SP 99999', 'Endocrinologia', '(11) 3222-1099', 'vinicius.prado@kuravet.com');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha nao tratada na chamada de PRC_CARGA_VETERINARIO: ' || SQLERRM);
END;
/
BEGIN
    PRC_CARGA_VETERINARIO('Veterinario CRMV Invalido', 'X', 'Clinica Geral', '(11) 3222-1098', 'semcrmv@kuravet.com');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha nao tratada na chamada de PRC_CARGA_VETERINARIO: ' || SQLERRM);
END;
/

BEGIN
    PRC_CARGA_PET('Amora', 'Gato', 'Maine Coon', DATE '2023-04-10', 'F', 1);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha nao tratada na chamada de PRC_CARGA_PET: ' || SQLERRM);
END;
/
BEGIN
    PRC_CARGA_PET('Pet Tutor Inexistente', 'Cachorro', 'SRD', DATE '2022-01-01', 'M', 9999);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha nao tratada na chamada de PRC_CARGA_PET: ' || SQLERRM);
END;
/

BEGIN
    PRC_CARGA_CONSULTA(1, 1, SYSDATE, 'Checkup', 'Retorno de rotina cadastrado via procedure', 'AGENDADA');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha nao tratada na chamada de PRC_CARGA_CONSULTA: ' || SQLERRM);
END;
/
BEGIN
    PRC_CARGA_CONSULTA(1, 1, SYSDATE, 'Checkup', 'Status invalido de teste', 'EM_ANDAMENTO');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha nao tratada na chamada de PRC_CARGA_CONSULTA: ' || SQLERRM);
END;
/

BEGIN
    PRC_CARGA_PAGAMENTO(1, 'KuraVet Pinheiros', 'Pix', 175.00, SYSDATE);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha nao tratada na chamada de PRC_CARGA_PAGAMENTO: ' || SQLERRM);
END;
/
BEGIN
    PRC_CARGA_PAGAMENTO(1, 'KuraVet Pinheiros', 'Pix', -50.00, SYSDATE);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha nao tratada na chamada de PRC_CARGA_PAGAMENTO: ' || SQLERRM);
END;
/

-- Conferencia dos erros efetivamente registrados pelas procedures de carga
SELECT ID_LOG_ERRO, NM_PROCEDURE, NM_USUARIO, DT_OCORRENCIA, CD_ERRO, DS_MENSAGEM_ERRO
FROM   LOG_ERRO_CARGA
ORDER  BY ID_LOG_ERRO;

--------------------------------------------------------------------------------
-- 13. BLOCOS ANONIMOS COM JUNCOES (JOIN), AGRUPAMENTO (GROUP BY) E ORDENACAO
--     (ORDER BY) -- minimo de 3 consultas distribuidas em 2 blocos
--------------------------------------------------------------------------------

-- 13.1 Bloco Anonimo 1: consultas por tutor/veterinario e faturamento por especie/clinica
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Quantidade de consultas por Tutor e Veterinario ===');
    FOR r IN (
        SELECT t.nome AS tutor, v.nome AS veterinario, COUNT(c.id_consulta) AS qtd_consultas
        FROM   TUTOR t
        JOIN   PET p          ON p.id_tutor = t.id_tutor
        JOIN   CONSULTA c     ON c.id_pet = p.id_pet
        JOIN   VETERINARIO v  ON v.id_veterinario = c.id_veterinario
        GROUP BY t.nome, v.nome
        ORDER BY qtd_consultas DESC, t.nome ASC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(r.tutor, 26) || RPAD(r.veterinario, 24) || r.qtd_consultas);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('=== Faturamento total por Especie do Pet e Clinica ===');
    FOR r IN (
        SELECT p.especie, f.clinica, SUM(f.valor) AS total_faturado
        FROM   PET p
        JOIN   CONSULTA c        ON c.id_pet = p.id_pet
        JOIN   FATO_PAGAMENTO f  ON f.id_consulta = c.id_consulta
        GROUP BY p.especie, f.clinica
        ORDER BY total_faturado DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(r.especie, 12) || RPAD(r.clinica, 22) ||
                              'R$ ' || TO_CHAR(r.total_faturado, 'FM999G999D00'));
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: nao ha dados suficientes para as juncoes deste bloco.');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Erro: retorno de dados excedeu o esperado.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado no Bloco Anonimo 1: ' || SQLERRM);
END;
/

-- 13.2 Bloco Anonimo 2: diagnosticos por veterinario e tipo de consulta
DECLARE
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== Quantidade de consultas por Veterinario e Tipo de Consulta ===');
    FOR r IN (
        SELECT v.nome AS veterinario, c.tipo_consulta, COUNT(*) AS qtd
        FROM   VETERINARIO v
        JOIN   CONSULTA c  ON c.id_veterinario = v.id_veterinario
        JOIN   PET p       ON p.id_pet = c.id_pet
        JOIN   TUTOR t     ON t.id_tutor = p.id_tutor
        GROUP BY v.nome, c.tipo_consulta
        ORDER BY v.nome ASC, qtd DESC
    ) LOOP
        DBMS_OUTPUT.PUT_LINE(RPAD(r.veterinario, 24) || RPAD(r.tipo_consulta, 18) || r.qtd);
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: nao ha dados suficientes para a juncao deste bloco.');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Erro: retorno de dados excedeu o esperado.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado no Bloco Anonimo 2: ' || SQLERRM);
END;
/

--------------------------------------------------------------------------------
-- 14. BLOCO ANONIMO: VALOR ATUAL, ANTERIOR E PROXIMO DA MESMA COLUNA
--------------------------------------------------------------------------------
-- Le a tabela FATO_PAGAMENTO ordenada por ID_PAGAMENTO e, para a coluna VALOR,
-- exibe em cada linha o valor atual, o valor da linha anterior e o valor da
-- proxima linha. Quando nao existir linha anterior/seguinte, exibe 'Vazio'.
-- A leitura completa e feita para uma colecao em memoria (PL/SQL table),
-- permitindo acessar o indice anterior (i-1) e o proximo (i+1) sem usar
-- funcoes analiticas prontas (LAG/LEAD).
DECLARE
    TYPE t_valores IS TABLE OF FATO_PAGAMENTO.VALOR%TYPE INDEX BY PLS_INTEGER;
    v_valores    t_valores;
    v_qtd        PLS_INTEGER := 0;
    v_atual      VARCHAR2(20);
    v_anterior   VARCHAR2(20);
    v_proximo    VARCHAR2(20);
BEGIN
    FOR r IN (SELECT valor FROM FATO_PAGAMENTO ORDER BY id_pagamento) LOOP
        v_qtd := v_qtd + 1;
        v_valores(v_qtd) := r.valor;
    END LOOP;

    IF v_qtd = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;

    DBMS_OUTPUT.PUT_LINE(RPAD('LINHA', 8) || RPAD('ANTERIOR', 15) || RPAD('ATUAL', 15) || 'PROXIMO');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 50, '-'));

    FOR i IN 1..v_qtd LOOP
        v_atual := TO_CHAR(v_valores(i), 'FM999G999D00');

        IF i = 1 THEN
            v_anterior := 'Vazio';
        ELSE
            v_anterior := TO_CHAR(v_valores(i - 1), 'FM999G999D00');
        END IF;

        IF i = v_qtd THEN
            v_proximo := 'Vazio';
        ELSE
            v_proximo := TO_CHAR(v_valores(i + 1), 'FM999G999D00');
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(i, 8) || RPAD(v_anterior, 15) || RPAD(v_atual, 15) || v_proximo);
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: a tabela FATO_PAGAMENTO nao possui registros.');
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('Erro: valor incompativel encontrado na coluna VALOR.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado: ' || SQLERRM);
END;
/

--------------------------------------------------------------------------------
-- 15. RELATORIOS COM CURSOR EXPLICITO E TOMADA DE DECISAO (4 BLOCOS ANONIMOS)
--------------------------------------------------------------------------------

-- 15.1 Relatorio 1: classificacao etaria dos pets (cursor explicito + IF/ELSIF)
DECLARE
    CURSOR c_pet IS
        SELECT nome, especie, data_nascimento
        FROM   PET
        ORDER BY data_nascimento;
    v_pet        c_pet%ROWTYPE;
    v_meses      NUMBER;
    v_categoria  VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('PET', 15) || RPAD('ESPECIE', 12) || 'CATEGORIA ETARIA');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 45, '-'));

    OPEN c_pet;
    LOOP
        FETCH c_pet INTO v_pet;
        EXIT WHEN c_pet%NOTFOUND;

        v_meses := TRUNC(MONTHS_BETWEEN(SYSDATE, v_pet.data_nascimento));

        IF v_meses < 12 THEN
            v_categoria := 'Filhote';
        ELSIF v_meses < 84 THEN
            v_categoria := 'Adulto';
        ELSE
            v_categoria := 'Idoso';
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(v_pet.nome, 15) || RPAD(v_pet.especie, 12) || v_categoria);
    END LOOP;
    CLOSE c_pet;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: nenhum pet cadastrado.');
    WHEN CURSOR_ALREADY_OPEN THEN
        DBMS_OUTPUT.PUT_LINE('Erro: cursor ja estava aberto.');
    WHEN OTHERS THEN
        IF c_pet%ISOPEN THEN CLOSE c_pet; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro inesperado: ' || SQLERRM);
END;
/

-- 15.2 Relatorio 2: triagem de acao por status da consulta (cursor explicito + IF/ELSIF)
DECLARE
    CURSOR c_cons IS
        SELECT tipo_consulta, status
        FROM   CONSULTA
        ORDER BY status;
    v_c      c_cons%ROWTYPE;
    v_acao   VARCHAR2(40);
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('TIPO DE CONSULTA', 22) || RPAD('STATUS', 14) || 'ACAO RECOMENDADA');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));

    OPEN c_cons;
    LOOP
        FETCH c_cons INTO v_c;
        EXIT WHEN c_cons%NOTFOUND;

        IF v_c.status = 'AGENDADA' THEN
            v_acao := 'Enviar lembrete ao tutor';
        ELSIF v_c.status = 'CANCELADA' THEN
            v_acao := 'Verificar motivo do cancelamento';
        ELSE
            v_acao := 'Arquivar prontuario';
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(v_c.tipo_consulta, 22) || RPAD(v_c.status, 14) || v_acao);
    END LOOP;
    CLOSE c_cons;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: nenhuma consulta cadastrada.');
    WHEN TOO_MANY_ROWS THEN
        DBMS_OUTPUT.PUT_LINE('Erro: retorno inesperado de multiplas linhas.');
    WHEN OTHERS THEN
        IF c_cons%ISOPEN THEN CLOSE c_cons; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro inesperado: ' || SQLERRM);
END;
/

-- 15.3 Relatorio 3: classificacao de fidelidade do tutor (cursor explicito + IF/ELSIF)
DECLARE
    CURSOR c_tutor IS
        SELECT t.nome,
               (SELECT COUNT(*) FROM PET p WHERE p.id_tutor = t.id_tutor) AS qtd_pets
        FROM   TUTOR t
        ORDER BY t.nome;
    v_t          c_tutor%ROWTYPE;
    v_categoria  VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('TUTOR', 30) || RPAD('QTD PETS', 10) || 'CATEGORIA');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));

    OPEN c_tutor;
    LOOP
        FETCH c_tutor INTO v_t;
        EXIT WHEN c_tutor%NOTFOUND;

        IF v_t.qtd_pets >= 2 THEN
            v_categoria := 'Cliente Ouro';
        ELSIF v_t.qtd_pets = 1 THEN
            v_categoria := 'Cliente Prata';
        ELSE
            v_categoria := 'Sem pets';
        END IF;

        DBMS_OUTPUT.PUT_LINE(RPAD(v_t.nome, 30) || RPAD(v_t.qtd_pets, 10) || v_categoria);
    END LOOP;
    CLOSE c_tutor;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: nenhum tutor cadastrado.');
    WHEN INVALID_CURSOR THEN
        DBMS_OUTPUT.PUT_LINE('Erro: operacao invalida sobre o cursor.');
    WHEN OTHERS THEN
        IF c_tutor%ISOPEN THEN CLOSE c_tutor; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro inesperado: ' || SQLERRM);
END;
/

-- 15.4 Relatorio 4 (completo): lista todos os pagamentos, mostra o total geral
--      sumarizado e a sumarizacao agrupada por CLINICA -- cursor explicito +
--      decisao manual de quebra de grupo (sem ROLLUP/CUBE/GROUPING SETS).
DECLARE
    CURSOR c_pag IS
        SELECT clinica, tipo_pagamento, id_pagamento, valor
        FROM   FATO_PAGAMENTO
        ORDER BY clinica, id_pagamento;
    r_pag              c_pag%ROWTYPE;
    v_clinica_ant      VARCHAR2(60) := NULL;
    v_subtotal_clinica NUMBER(10,2) := 0;
    v_total_geral      NUMBER(10,2) := 0;
    v_qtd_linhas       NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== RELATORIO COMPLETO DE PAGAMENTOS (listagem + sumarizacao) ===');
    DBMS_OUTPUT.PUT_LINE(RPAD('CLINICA', 22) || RPAD('TIPO PAGAMENTO', 18) || RPAD('ID', 8) || 'VALOR (R$)');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));

    OPEN c_pag;
    LOOP
        FETCH c_pag INTO r_pag;
        EXIT WHEN c_pag%NOTFOUND;

        v_qtd_linhas := v_qtd_linhas + 1;

        -- Tomada de decisao: deteccao manual de quebra de grupo (primeira categoria: CLINICA)
        IF v_clinica_ant IS NOT NULL AND r_pag.clinica <> v_clinica_ant THEN
            DBMS_OUTPUT.PUT_LINE(RPAD('Subtotal ' || v_clinica_ant, 48) ||
                                  TO_CHAR(v_subtotal_clinica, 'FM999G999D00'));
            DBMS_OUTPUT.PUT_LINE(RPAD('-', 60, '-'));
            v_subtotal_clinica := 0;
        END IF;

        v_clinica_ant := r_pag.clinica;

        DBMS_OUTPUT.PUT_LINE(RPAD(r_pag.clinica, 22) || RPAD(r_pag.tipo_pagamento, 18) ||
                              RPAD(r_pag.id_pagamento, 8) || TO_CHAR(r_pag.valor, 'FM999G999D00'));

        v_subtotal_clinica := v_subtotal_clinica + r_pag.valor;
        v_total_geral       := v_total_geral + r_pag.valor;
    END LOOP;
    CLOSE c_pag;

    IF v_qtd_linhas = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;

    -- Fecha o ultimo grupo pendente
    DBMS_OUTPUT.PUT_LINE(RPAD('Subtotal ' || v_clinica_ant, 48) ||
                          TO_CHAR(v_subtotal_clinica, 'FM999G999D00'));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 60, '='));
    DBMS_OUTPUT.PUT_LINE(RPAD('TOTAL GERAL SUMARIZADO', 48) ||
                          TO_CHAR(v_total_geral, 'FM999G999D00'));

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: nao ha pagamentos cadastrados.');
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('Erro: divisao por zero detectada.');
    WHEN OTHERS THEN
        IF c_pag%ISOPEN THEN CLOSE c_pag; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro inesperado: ' || SQLERRM);
END;
/
