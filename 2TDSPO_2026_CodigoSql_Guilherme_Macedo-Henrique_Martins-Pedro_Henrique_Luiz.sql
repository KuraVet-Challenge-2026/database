-- =============================================================================
-- KuraVet - Challenge FIAP 2026 x Clyvo Vet
-- Disciplina: Mastering Relational and Non-Relational Database - Sprint 4
-- Turma 2TDSPO
--   Guilherme Macedo Martins ............ RM562396
--   Pedro Henrique Luiz Alves Duarte .... RM563405
--   Henrique Martins Oliveira ........... RM563620
-- =============================================================================
-- COMO EXECUTAR
--   SQL Developer: abrir este arquivo e executar com "Run Script" (F5).
--   O script e reexecutavel: a Parte 1 apaga os objetos do projeto e recria
--   tudo do zero. Executar em um schema de testes (nao no schema do backend).
--   Requer Oracle 19c ou superior (JSON_OBJECT, IS JSON, IDENTITY).
--
-- CONTEUDO (mapa para os entregaveis da Sprint 4)
--   Parte 1  Limpeza do schema
--   Parte 2  DDL corrigido (modelo fisico) ............ Entregavel 1 (SQL)
--   Parte 3  Carga inicial
--   Parte 4  Packages - especificacao ................. Entregavel 2
--   Parte 5  Packages - corpo ......................... Entregavel 2
--   Parte 6  Trigger de auditoria ..................... Entregavel 2
--   Parte 7  Blocos anonimos da Sprint 3 corrigidos ... Entregavel 1 (SQL)
--   Parte 8  JSON gerado a partir do banco ............ Entregavel 3
--   Parte 9  Evidencias (EV-01..EV-17): sucesso e excecao tratada de cada
--            funcao/procedimento (feedback da Sprint 3)
--   Parte 10 Verificacao: objetos VALID e USER_ERRORS vazio
--
-- PACKAGES
--   PKG_KV_UTIL      catalogo de erros (-20001..-20099), excecoes nomeadas, log
--                    de erros (transacao autonoma), FN_MONTA_JSON,
--                    FN_CALCULA_IDADE_PET, FN_CATEGORIA_ETARIA
--   PKG_KV_AUDITORIA FN_SERIALIZAR_CONSULTA, PRC_REGISTRAR (chamados pela trigger)
--   PKG_KV_CARGA     PRC_CARGA_TUTOR/VETERINARIO/PET/CONSULTA/PAGAMENTO e
--                    PRC_REGISTRAR_DIAGNOSTICO (chamadas pelo backend Java)
--   PKG_KV_RELATORIO PRC_LISTAR_CONSULTAS_JSON, PRC_SUBTOTAIS_PAGAMENTO (console)
--                    PRC_CONSULTAS_TUTOR, PRC_FATURAMENTO_CLINICA_TIPO (SYS_REFCURSOR)
--   PKG_KV_EXPORT    FN_DOC_PET, FN_DOC_VETERINARIO, FN_EXPORTAR_PETS,
--                    FN_EXPORTAR_VETERINARIOS (dataset JSON para o MongoDB)
--   Triggers nao podem ser declaradas dentro de packages no Oracle: a
--   TRG_AUDITORIA_CONSULTA apenas dispara e toda a regra fica no PKG_KV_AUDITORIA.
--
-- CORRECOES DO FEEDBACK DA SPRINT 3
--   * Procedimento 1 (PRC_LISTAR_CONSULTAS_JSON): ausencia de resultados
--     verificada pelas linhas do proprio cursor; filtro por tutor; somente
--     excecoes possiveis (TOO_MANY_ROWS removido).            -> EV-04
--   * Procedimento 2 (PRC_SUBTOTAIS_PAGAMENTO): valores consolidados por
--     clinica + tipo de pagamento no acumulador v_subtotal_tipo; linhas
--     "Sub Total" por clinica e "Total Geral".                 -> EV-05
--   * FN_MONTA_JSON: escape de aspas, barra invertida, quebra de linha, TAB e
--     demais caracteres de controle.                           -> EV-01
--   * FN_CALCULA_IDADE_PET: TOO_MANY_ROWS substituido pela validacao de data
--     de nascimento no futuro.                                 -> EV-02c
--   * Trigger: VALORES_OLD/NEW em JSON incluindo DIAGNOSTICO.  -> EV-14e
--   * Documentacao: uma excecao tratada demonstrada para cada funcao e
--     procedimento.                                            -> EV-01..EV-17
-- =============================================================================
SET SERVEROUTPUT ON SIZE UNLIMITED
SET VERIFY OFF
SET DEFINE OFF
SET LINESIZE 250
SET PAGESIZE 100



-- #############################################################################
-- PARTE 1 - LIMPEZA DO SCHEMA
-- #############################################################################
-- Limpeza do schema (SOMENTE schema de testes/sandbox)
--
-- Remove tambem as functions/procedures "soltas" da Sprint 3, para que no
-- schema fiquem apenas os objetos empacotados.
-- Ignora somente o erro "objeto nao existe"; qualquer outro erro e propagado.
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


-- #############################################################################
-- PARTE 2 - DDL (MODELO FISICO CORRIGIDO)
-- #############################################################################
-- DDL: tabelas, constraints, indices e sequences
--
-- Mudancas em relacao a Sprint 3:
--   * CONSULTA: status do fluxo do app (SOLICITADA, AGENDADA, REALIZADA,
--     CANCELADA, RECUSADA), DATA_SOLICITACAO, MOTIVO_RECUSA e regra
--     "consulta recusada exige motivo".
--   * FATO_PAGAMENTO: VALOR > 0 (igual a regra da procedure) e dominio de
--     TIPO_PAGAMENTO.
--   * AUDITORIA_LOG / LOG_ERRO_CARGA: TIMESTAMP, NOT NULL e valores de
--     auditoria validados como JSON.
--   * Indices nas chaves estrangeiras e colunas de filtro dos relatorios.
--   * LOG_ERRO_CARGA e sequences movidas para o DDL (antes no meio do script).
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
    CONSTRAINT KV_FK_PET_TUTOR FOREIGN KEY (ID_TUTOR) REFERENCES TUTOR (ID_TUTOR)
);

CREATE TABLE CONSULTA (
    ID_CONSULTA       NUMBER(6)       NOT NULL,
    ID_PET            NUMBER(6)       NOT NULL,
    ID_VETERINARIO    NUMBER(6)       NOT NULL,
    DATA_SOLICITACAO  DATE            DEFAULT SYSDATE NOT NULL,
    DATA_CONSULTA     DATE            NOT NULL,
    TIPO_CONSULTA     VARCHAR2(40)    NOT NULL,
    STATUS            VARCHAR2(20)    DEFAULT 'SOLICITADA' NOT NULL,
    DIAGNOSTICO       VARCHAR2(400),
    MOTIVO_RECUSA     VARCHAR2(400),
    CONSTRAINT KV_PK_CONSULTA PRIMARY KEY (ID_CONSULTA),
    CONSTRAINT KV_CK_CONS_STATUS CHECK (STATUS IN ('SOLICITADA','AGENDADA','REALIZADA','CANCELADA','RECUSADA')),
    CONSTRAINT KV_CK_CONS_MOTIVO CHECK (STATUS <> 'RECUSADA' OR MOTIVO_RECUSA IS NOT NULL),
    CONSTRAINT KV_FK_CONS_PET FOREIGN KEY (ID_PET) REFERENCES PET (ID_PET),
    CONSTRAINT KV_FK_CONS_VET FOREIGN KEY (ID_VETERINARIO) REFERENCES VETERINARIO (ID_VETERINARIO)
);

CREATE TABLE FATO_PAGAMENTO (
    ID_PAGAMENTO    NUMBER(6)       NOT NULL,
    ID_CONSULTA     NUMBER(6)       NOT NULL,
    CLINICA         VARCHAR2(60)    NOT NULL,
    TIPO_PAGAMENTO  VARCHAR2(30)    NOT NULL,
    VALOR           NUMBER(10,2)    NOT NULL,
    DATA_PAGAMENTO  DATE            DEFAULT SYSDATE NOT NULL,
    CONSTRAINT KV_PK_FATO_PAG PRIMARY KEY (ID_PAGAMENTO),
    CONSTRAINT KV_CK_PAG_VALOR CHECK (VALOR > 0),
    CONSTRAINT KV_CK_PAG_TIPO CHECK (TIPO_PAGAMENTO IN ('Pix','Cartao de Credito','Cartao de Debito','Dinheiro')),
    CONSTRAINT KV_FK_PAG_CONS FOREIGN KEY (ID_CONSULTA) REFERENCES CONSULTA (ID_CONSULTA)
);

CREATE TABLE AUDITORIA_LOG (
    ID_LOG          NUMBER GENERATED ALWAYS AS IDENTITY,
    USUARIO         VARCHAR2(60)    NOT NULL,
    OPERACAO        VARCHAR2(10)    NOT NULL,
    DATA_HORA       TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    TABELA_AFETADA  VARCHAR2(30)    NOT NULL,
    VALORES_OLD     VARCHAR2(4000),
    VALORES_NEW     VARCHAR2(4000),
    CONSTRAINT KV_PK_AUDITORIA_LOG PRIMARY KEY (ID_LOG),
    CONSTRAINT KV_CK_AUD_OPERACAO CHECK (OPERACAO IN ('INSERT','UPDATE','DELETE')),
    CONSTRAINT KV_CK_AUD_OLD_JSON CHECK (VALORES_OLD IS JSON),
    CONSTRAINT KV_CK_AUD_NEW_JSON CHECK (VALORES_NEW IS JSON)
);

CREATE TABLE LOG_ERRO_CARGA (
    ID_LOG_ERRO      NUMBER GENERATED ALWAYS AS IDENTITY,
    NM_PROCEDURE     VARCHAR2(60)    NOT NULL,
    NM_USUARIO       VARCHAR2(60)    NOT NULL,
    DT_OCORRENCIA    TIMESTAMP       DEFAULT SYSTIMESTAMP NOT NULL,
    CD_ERRO          VARCHAR2(20)    NOT NULL,
    DS_MENSAGEM_ERRO VARCHAR2(500)   NOT NULL,
    CONSTRAINT KV_PK_LOG_ERRO_CARGA PRIMARY KEY (ID_LOG_ERRO)
);

-- Indices em chaves estrangeiras e filtros usados nos relatorios
CREATE INDEX KV_IX_PET_TUTOR       ON PET (ID_TUTOR);
CREATE INDEX KV_IX_CONS_PET        ON CONSULTA (ID_PET);
CREATE INDEX KV_IX_CONS_VET        ON CONSULTA (ID_VETERINARIO);
CREATE INDEX KV_IX_CONS_STATUS     ON CONSULTA (STATUS, DATA_CONSULTA);
CREATE INDEX KV_IX_PAG_CONS        ON FATO_PAGAMENTO (ID_CONSULTA);
CREATE INDEX KV_IX_PAG_CLINICA     ON FATO_PAGAMENTO (CLINICA, TIPO_PAGAMENTO);

-- Sequences usadas pelas procedures de carga (dados iniciais usam IDs < 100)
CREATE SEQUENCE SEQ_KV_TUTOR       START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_KV_VETERINARIO START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_KV_PET         START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_KV_CONSULTA    START WITH 100 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE SEQ_KV_PAGAMENTO   START WITH 100 INCREMENT BY 1 NOCACHE;

COMMENT ON TABLE TUTOR          IS 'Tutor (responsavel) pelos pets';
COMMENT ON TABLE VETERINARIO    IS 'Veterinarios que atendem nas clinicas parceiras';
COMMENT ON TABLE PET            IS 'Pets cadastrados, cada um vinculado a um tutor';
COMMENT ON TABLE CONSULTA       IS 'Consultas/teleconsultas; STATUS segue o fluxo SOLICITADA -> AGENDADA -> REALIZADA (ou CANCELADA/RECUSADA)';
COMMENT ON TABLE FATO_PAGAMENTO IS 'Pagamentos das consultas realizadas';
COMMENT ON TABLE AUDITORIA_LOG  IS 'Trilha de auditoria (valores OLD/NEW em JSON) alimentada pela TRG_AUDITORIA_CONSULTA via PKG_KV_AUDITORIA';
COMMENT ON TABLE LOG_ERRO_CARGA IS 'Log de erros das rotinas dos packages (gravado em transacao autonoma)';


-- #############################################################################
-- PARTE 3 - CARGA INICIAL
-- #############################################################################
-- Carga inicial (dados controlados)
--
-- Dados pensados para as demonstracoes:
--   * Tutor 1 e tutor 3 tem 2 pets (categoria "Cliente Ouro").
--   * Tutor 11 nao tem pets nem consultas (demonstra "sem dados").
--   * Consultas em todos os status; pagamentos apenas de consultas REALIZADAS.
--   * Consultas 10 e 12 tem aspas, ponto e virgula e quebra de linha no
--     diagnostico (demonstra o tratamento de caracteres especiais no JSON).
--   * Consultas futuras usam datas relativas a SYSDATE (continuam futuras
--     no dia da correcao).
--   * Resultado esperado do relatorio de subtotais (antes da demo 90):
--       KuraVet Alphaville 825,00 | KuraVet Moema 770,00 |
--       KuraVet Pinheiros 805,00 | Total Geral 2.400,00
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
INSERT INTO TUTOR (ID_TUTOR, NOME, CPF, TELEFONE, EMAIL, ENDERECO, DATA_CADASTRO) VALUES (11,'Larissa Monteiro','101.202.303-40','(11) 91234-5611','larissa.monteiro@email.com','Rua Augusta, 1500 - Sao Paulo/SP', DATE '2024-06-12');

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
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (11,'Pipoca','Gato','SRD', DATE '2026-03-10','F',1);
INSERT INTO PET (ID_PET, NOME, ESPECIE, RACA, DATA_NASCIMENTO, SEXO, ID_TUTOR) VALUES (12,'Fred','Cachorro','Dachshund', DATE '2012-08-20','M',3);

-- CONSULTA (ID, PET, VET, DATA_SOLICITACAO, DATA_CONSULTA, TIPO, STATUS, DIAGNOSTICO, MOTIVO_RECUSA)
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (1, 1, 1, DATE '2025-01-05', DATE '2025-01-10', 'Checkup',      'REALIZADA', 'Animal saudavel, vacinacao em dia', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (2, 2, 2, DATE '2025-02-10', DATE '2025-02-14', 'Dermatologia', 'REALIZADA', 'Dermatite alergica leve', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (3, 3, 3, DATE '2025-03-01', DATE '2025-03-05', 'Cardiologia',  'REALIZADA', 'Sopro cardiaco grau I, monitorar', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (4, 4, 1, DATE '2025-04-15', DATE '2025-04-18', 'Vacinacao',    'REALIZADA', 'Aplicada V4 felina', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (5, 5, 4, DATE '2025-05-18', DATE '2025-05-22', 'Ortopedia',    'REALIZADA', 'Displasia coxofemoral leve', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (6, 6, 5, DATE '2025-06-25', DATE '2025-06-30', 'Checkup',      'REALIZADA', 'Sem alteracoes', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (7, 7, 6, DATE '2025-07-01', DATE '2025-07-11', 'Cirurgia',     'REALIZADA', 'Castracao eletiva realizada', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (8, 8, 7, DATE '2025-08-02', DATE '2025-08-09', 'Oncologia',    'REALIZADA', 'Nodulo mamario em investigacao', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (9, 9, 8, DATE '2025-09-20', DATE '2025-09-25', 'Checkup',      'REALIZADA', 'Peso acima do ideal, dieta recomendada', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (10, 1, 2, DATE '2026-01-28', DATE '2026-02-03', 'Dermatologia', 'REALIZADA', 'Otite externa; prescrito "gotas otologicas" 2x/dia por 7 dias', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (11, 3, 3, DATE '2026-03-05', DATE '2026-03-12', 'Cardiologia',  'REALIZADA', 'Retorno: sopro estavel, manter acompanhamento semestral', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (12, 11, 1, DATE '2026-05-15', DATE '2026-05-20', 'Vacinacao',   'REALIZADA', 'Aplicada V4 felina (1a dose)' || CHR(10) || 'Retorno em 21 dias para reforco', NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (13, 10, 9, TRUNC(SYSDATE) - 2, TRUNC(SYSDATE) + 10, 'Nutricao',  'AGENDADA',   NULL, NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (14, 12, 3, TRUNC(SYSDATE),     TRUNC(SYSDATE) + 20, 'Cardiologia', 'SOLICITADA', NULL, NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (15, 5, 4, DATE '2026-06-01', DATE '2026-06-15', 'Ortopedia',   'CANCELADA',  NULL, NULL);
INSERT INTO CONSULTA (ID_CONSULTA, ID_PET, ID_VETERINARIO, DATA_SOLICITACAO, DATA_CONSULTA, TIPO_CONSULTA, STATUS, DIAGNOSTICO, MOTIVO_RECUSA) VALUES (16, 7, 6, DATE '2026-06-28', DATE '2026-07-02', 'Cirurgia',    'RECUSADA',   NULL, 'Agenda cirurgica indisponivel na data solicitada');

-- FATO_PAGAMENTO (somente consultas REALIZADAS)
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (1,  1,  'KuraVet Pinheiros',  'Pix',               150.00, DATE '2025-01-10');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (2,  2,  'KuraVet Pinheiros',  'Pix',               180.00, DATE '2025-02-14');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (3,  3,  'KuraVet Pinheiros',  'Cartao de Credito', 220.00, DATE '2025-03-05');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (4,  4,  'KuraVet Moema',      'Pix',                90.00, DATE '2025-04-18');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (5,  5,  'KuraVet Moema',      'Cartao de Credito', 350.00, DATE '2025-05-22');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (6,  6,  'KuraVet Moema',      'Cartao de Credito', 130.00, DATE '2025-06-30');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (7,  7,  'KuraVet Moema',      'Dinheiro',          200.00, DATE '2025-07-11');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (8,  8,  'KuraVet Alphaville', 'Pix',               275.00, DATE '2025-08-09');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (9,  9,  'KuraVet Alphaville', 'Cartao de Credito', 310.00, DATE '2025-09-25');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (10, 10, 'KuraVet Pinheiros',  'Pix',               160.00, DATE '2026-02-03');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (11, 11, 'KuraVet Alphaville', 'Cartao de Debito',  240.00, DATE '2026-03-12');
INSERT INTO FATO_PAGAMENTO (ID_PAGAMENTO, ID_CONSULTA, CLINICA, TIPO_PAGAMENTO, VALOR, DATA_PAGAMENTO) VALUES (12, 12, 'KuraVet Pinheiros',  'Cartao de Debito',   95.00, DATE '2026-05-20');

COMMIT;


-- #############################################################################
-- PARTE 4 - PACKAGES: ESPECIFICACAO
-- #############################################################################
-- Especificacao (SPEC) dos packages
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


-- #############################################################################
-- PARTE 5 - PACKAGES: CORPO
-- #############################################################################
-- Corpo (BODY) dos packages
--
-- Regra de tratamento de excecoes (feedback Sprint 3): cada handler
-- corresponde a uma situacao que realmente pode ocorrer na rotina; nao ha
-- handlers "decorativos". Cada rotina publica tem ao menos uma excecao de
-- negocio demonstrada em 90_demo_evidencias.sql.
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


-- #############################################################################
-- PARTE 6 - TRIGGER DE AUDITORIA (DELEGA AO PKG_KV_AUDITORIA)
-- #############################################################################
-- Trigger de auditoria da CONSULTA
--
-- Triggers nao podem ficar dentro de package no Oracle; por isso a trigger e
-- apenas o ponto de disparo e toda a regra fica em PKG_KV_AUDITORIA.
-- Correcao do feedback Sprint 3: VALORES_OLD e VALORES_NEW incluem
-- DIAGNOSTICO (e tambem DATA_SOLICITACAO e MOTIVO_RECUSA).
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


-- #############################################################################
-- PARTE 7 - BLOCOS ANONIMOS (SPRINT 3 CORRIGIDOS)
-- #############################################################################
-- Blocos anonimos da Sprint 3 (corrigidos)
--
-- Correcoes:
--   * ausencia de resultados verificada pelo numero de linhas percorridas
--     (PKG_KV_UTIL.e_sem_dados) em todos os blocos;
--   * status novos (SOLICITADA/RECUSADA) na tomada de decisao;
--   * categoria etaria reaproveita PKG_KV_UTIL.FN_CATEGORIA_ETARIA;
--   * valores monetarios em formato brasileiro;
--   * o bloco "relatorio completo de pagamentos" foi removido por duplicar
--     PKG_KV_RELATORIO.PRC_SUBTOTAIS_PAGAMENTO.
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


-- #############################################################################
-- PARTE 8 - JSON GERADO A PARTIR DO BANCO RELACIONAL
-- #############################################################################
-- Gera o dataset JSON pelo PKG_KV_EXPORT, sobre os dados da carga inicial
-- (antes das demonstracoes da Parte 9). O resultado e um array JSON pronto
-- para "mongoimport --jsonArray" (colecoes "pets" e "veterinarios").
-- No SQL Developer, clique duas vezes na celula do resultado para ver o JSON
-- completo. Os arquivos export/kuravet_pets.json e
-- export/kuravet_veterinarios.json do repositorio foram gerados por estas
-- mesmas funcoes (sql/06_export_json.sql, via SQLcl).
SET LONG 1000000
SET LONGCHUNKSIZE 1000000

PROMPT ===== JSON: colecao pets =====
SELECT PKG_KV_EXPORT.FN_EXPORTAR_PETS(NULL) AS JSON_PETS FROM DUAL;

PROMPT ===== JSON: colecao veterinarios =====
SELECT PKG_KV_EXPORT.FN_EXPORTAR_VETERINARIOS(NULL) AS JSON_VETERINARIOS FROM DUAL;


-- #############################################################################
-- PARTE 9 - EVIDENCIAS: SUCESSO + EXCECAO TRATADA DE CADA ROTINA
-- #############################################################################
-- Demonstracao e EVIDENCIAS (feedback Sprint 3)
--
-- Para CADA funcao e procedimento publico: 1 execucao com sucesso e pelo
-- menos 1 excecao efetivamente tratada. Cada secao EV-xx corresponde a um
-- print no documento de evidencias (docs/ROTEIRO_EVIDENCIAS.md).
--
-- Os blocos que esperam erro capturam a excecao PELO NOME
-- (PKG_KV_UTIL.e_...), o que comprova o codigo do catalogo. Se aparecer
-- outro erro, ele NAO e capturado e fica visivel na saida (sinal de defeito).
--
-- Pre-requisito: Partes 1 a 6 executadas (base recem-criada).
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


-- #############################################################################
-- PARTE 10 - VERIFICACAO FINAL
-- #############################################################################
-- Verificacao do schema (rodar ao final; tudo deve estar VALID
-- e USER_ERRORS deve voltar sem linhas)
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

-- As verificacoes consideram apenas os objetos deste projeto: objetos de
-- outras atividades que existam no mesmo schema nao interferem.
PROMPT === Objetos INVALIDOS do projeto (esperado: nenhuma linha) ===
SELECT OBJECT_TYPE, OBJECT_NAME
  FROM USER_OBJECTS
 WHERE (OBJECT_NAME LIKE 'PKG_KV%'
        OR OBJECT_NAME LIKE 'SEQ_KV%'
        OR OBJECT_NAME IN ('TRG_AUDITORIA_CONSULTA', 'TUTOR', 'VETERINARIO', 'PET', 'CONSULTA',
                           'FATO_PAGAMENTO', 'AUDITORIA_LOG', 'LOG_ERRO_CARGA'))
   AND STATUS <> 'VALID';

PROMPT === Erros de compilacao do projeto (esperado: nenhuma linha) ===
SELECT NAME, TYPE, LINE, POSITION, TEXT
  FROM USER_ERRORS
 WHERE NAME LIKE 'PKG_KV%' OR NAME = 'TRG_AUDITORIA_CONSULTA'
 ORDER BY NAME, TYPE, SEQUENCE;

PROMPT === Rotinas da Sprint 3 ainda avulsas (esperado: nenhuma linha - tudo empacotado) ===
SELECT OBJECT_TYPE, OBJECT_NAME
  FROM USER_OBJECTS
 WHERE OBJECT_TYPE IN ('FUNCTION', 'PROCEDURE')
   AND OBJECT_NAME IN ('FN_MONTA_JSON', 'FN_CALCULA_IDADE_PET', 'PROC_LISTAR_CONSULTAS_JSON',
                       'PROC_SUBTOTAIS_PAGAMENTO', 'PRC_CARGA_TUTOR', 'PRC_CARGA_VETERINARIO',
                       'PRC_CARGA_PET', 'PRC_CARGA_CONSULTA', 'PRC_CARGA_PAGAMENTO');

PROMPT === Quantidade de registros ===
SELECT 'TUTOR' AS TABELA, COUNT(*) AS QTD FROM TUTOR
UNION ALL SELECT 'VETERINARIO',    COUNT(*) FROM VETERINARIO
UNION ALL SELECT 'PET',            COUNT(*) FROM PET
UNION ALL SELECT 'CONSULTA',       COUNT(*) FROM CONSULTA
UNION ALL SELECT 'FATO_PAGAMENTO', COUNT(*) FROM FATO_PAGAMENTO
UNION ALL SELECT 'AUDITORIA_LOG',  COUNT(*) FROM AUDITORIA_LOG
UNION ALL SELECT 'LOG_ERRO_CARGA', COUNT(*) FROM LOG_ERRO_CARGA;

PROMPT === Consultas por status ===
COLUMN STATUS FORMAT A12
SELECT STATUS, COUNT(*) AS QTD FROM CONSULTA GROUP BY STATUS ORDER BY STATUS;
