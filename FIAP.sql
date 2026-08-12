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