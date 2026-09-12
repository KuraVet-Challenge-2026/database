Global Solution: Projeto KuraVet — Banco de Dados
Disciplina

Mastering Relational and Non-Relational Database

Integrantes da Equipe
Guilherme Macedo Martins — RM 562396
Henrique Martins Oliveira — RM 563620
Pedro Henrique Luiz Alves Duarte — RM 563405

Turma: 2TDSPO

Arquivos do Projeto
Arquivo	Conteúdo
2TDSPO_2024_CodigoSql_Integrantes.sql	Script único com todo o DDL, carga de dados, procedures, funções, trigger e blocos de demonstração
2TDSPO_2024_Proj_BD.pdf / .docx	Documentação técnica completa (capa, modelo descritivo, DER/MER, código comentado e evidências de execução)
Visão Geral do Projeto

O KuraVet é uma plataforma de saúde preventiva contínua para pets. O banco de dados centraliza o cadastro de tutores, pets e veterinários, o histórico de consultas e os pagamentos realizados em cada clínica, funcionando como a fonte da verdade (single source of truth) para as APIs de consumo (Java/Spring e .NET). O modelo é relacional, normalizado até a 3ª Forma Normal (3FN), e toda a lógica de negócio crítica — validação de dados, geração de relatórios e auditoria — é implementada em PL/SQL no próprio banco.

Estrutura do Banco de Dados (Tabelas)

O modelo relacional é composto pelas seguintes tabelas:

TUTOR — dados cadastrais dos tutores responsáveis pelos pets (nome, CPF, telefone, e-mail, endereço, data de cadastro). O CPF é UNIQUE.
VETERINARIO — cadastro dos profissionais veterinários (nome, CRMV, especialidade, telefone, e-mail). O CRMV é UNIQUE.
PET — animais cadastrados, cada um vinculado a um único tutor (FK para TUTOR). Guarda espécie, raça, data de nascimento e sexo (CHECK restrito a 'M'/'F').
CONSULTA — histórico clínico: liga um PET a um VETERINARIO, com data, tipo de consulta, diagnóstico e status (CHECK restrito a AGENDADA/REALIZADA/CANCELADA).
FATO_PAGAMENTO — tabela de fato financeira, vinculada a cada CONSULTA. Contém as colunas categóricas CLINICA e TIPO_PAGAMENTO e a coluna numérica VALOR, usadas nos relatórios de sumarização.
AUDITORIA_LOG — tabela de auditoria alimentada automaticamente pela trigger TRG_AUDITORIA_CONSULTA, registrando toda alteração DML em CONSULTA.
LOG_ERRO_CARGA — tabela de log de erros, alimentada pelas procedures de carga sempre que uma regra de negócio ou restrição de integridade é violada.

Todas as tabelas foram carregadas com 10 registros reais e coerentes entre si (acima do mínimo de 5 exigido), respeitando as chaves estrangeiras.

Funcionalidades e Regras de Negócio (PL/SQL)

O script 2TDSPO_2024_CodigoSql_Integrantes.sql implementa, além do DDL, os seguintes blocos de lógica de negócio — todos com no mínimo 3 cláusulas EXCEPTION WHEN distintas (sempre incluindo WHEN OTHERS):

Funções
FN_MONTA_JSON — converte dados relacionais em uma string JSON, montada manualmente por concatenação de texto, sem uso de nenhuma função nativa do Oracle (TO_JSON, JSON_OBJECT, JSON_VALUE etc.).
FN_CALCULA_IDADE_PET — regra de negócio que calcula a idade exata de um pet em anos e meses a partir da data de nascimento.
Procedures de consulta/relatório
PROC_LISTAR_CONSULTAS_JSON — realiza JOIN entre CONSULTA, PET, TUTOR e VETERINARIO e exibe cada linha convertida em JSON pela FN_MONTA_JSON.
PROC_SUBTOTAIS_PAGAMENTO — lê FATO_PAGAMENTO e calcula, de forma 100% manual (sem ROLLUP/CUBE/GROUPING SETS), os subtotais por clínica e o total geral.
Procedures de carga de dados (parametrizadas)

Uma procedure por tabela, recebendo os dados exclusivamente por passagem de parâmetro (sem hard-code), cada uma validando uma regra de negócio antes do INSERT e registrando qualquer falha em LOG_ERRO_CARGA:

Procedure	Regra de negócio validada	Exceção customizada
PRC_CARGA_TUTOR	CPF obrigatório, mínimo 11 dígitos	e_cpf_invalido
PRC_CARGA_VETERINARIO	CRMV obrigatório, mínimo 5 caracteres	e_crmv_invalido
PRC_CARGA_PET	Tutor referenciado precisa existir; data de nascimento não pode ser futura	e_tutor_inexistente, e_data_nasc_futura
PRC_CARGA_CONSULTA	Pet referenciado precisa existir; status deve pertencer ao domínio válido	e_pet_inexistente, e_status_invalido
PRC_CARGA_PAGAMENTO	Consulta referenciada precisa existir; valor deve ser positivo	e_consulta_inexiste, e_valor_invalido

As chaves primárias dessas cargas são geradas por sequences dedicadas (SEQ_KV_TUTOR, SEQ_KV_VETERINARIO, SEQ_KV_PET, SEQ_KV_CONSULTA, SEQ_KV_PAGAMENTO), iniciando em 100 para não colidir com a carga inicial.

Trigger de auditoria
TRG_AUDITORIA_CONSULTA — disparada AFTER INSERT OR UPDATE OR DELETE em CONSULTA, FOR EACH ROW. Grava em AUDITORIA_LOG o usuário (USER), a operação, a data/hora (SYSDATE) e os valores :OLD e :NEW concatenados. Possui tratamento de exceção defensivo (VALUE_ERROR, DUP_VAL_ON_INDEX, OTHERS) que relança o erro (RAISE) para nunca mascarar uma falha de auditoria.
Relatórios e Consultas Analíticas
Bloco Anônimo 1 — junta TUTOR, PET, CONSULTA e VETERINARIO para contar consultas por tutor/veterinário, e junta PET, CONSULTA e FATO_PAGAMENTO para somar o faturamento por espécie e clínica (JOIN + GROUP BY + ORDER BY).
Bloco Anônimo 2 — junta VETERINARIO, CONSULTA, PET e TUTOR para contar diagnósticos por veterinário e tipo de consulta (JOIN + GROUP BY + ORDER BY).
Bloco Valor Atual/Anterior/Próximo — lê FATO_PAGAMENTO e exibe, para cada linha, o valor atual, o valor da linha anterior e o valor da próxima linha ('Vazio' quando não existir), usando uma coleção PL/SQL em memória.
Relatório 1 — Classificação etária dos pets — cursor explícito + decisão (IF/ELSIF) que classifica cada pet como Filhote, Adulto ou Idoso.
Relatório 2 — Triagem por status da consulta — cursor explícito + decisão que recomenda uma ação operacional (lembrete, verificação de cancelamento, arquivamento) conforme o status.
Relatório 3 — Classificação de fidelidade do tutor — cursor explícito + decisão que categoriza tutores em Cliente Ouro (2+ pets), Cliente Prata (1 pet) ou Sem pets.
Relatório 4 (completo) — cursor explícito que lista todos os pagamentos, sumariza os subtotais por clínica e apresenta o total geral, com quebra de grupo controlada manualmente (sem funções automáticas de agregação avançada).
Tratamento de Exceções

Todos os blocos nomeados (funções, procedures) e todos os blocos anônimos do projeto possuem no mínimo 3 cláusulas EXCEPTION WHEN distintas, sempre incluindo WHEN OTHERS. Qualquer falha nas procedures de carga é automaticamente registrada em LOG_ERRO_CARGA, com o nome da procedure, o usuário, a data/hora, o código do erro e a mensagem de erro.

Organização do Script

O arquivo é dividido em 15 seções numeradas e comentadas:

Limpeza de objetos existentes (idempotência)
DDL — tabelas core
DML — carga de dados inicial (10 registros por tabela) 3–7. Funções, procedures e trigger herdadas (JSON manual, subtotais, idade do pet, auditoria)
Bloco de demonstração/testes
Tabela de log de erros de carga
Sequences de apoio às procedures de carga
Procedures de carga de dados parametrizadas
Demonstração das procedures de carga (casos de sucesso e de erro)
Blocos anônimos com junções, agrupamento e ordenação
Bloco valor atual/anterior/próximo
Relatórios com cursor explícito e tomada de decisão
Como Executar
Utilize um ambiente Oracle Database (SQL Developer, SQL*Plus ou Oracle Live SQL).
Ative a exibição de saída antes de rodar o script:
sql
   SET SERVEROUTPUT ON;
   SET LINESIZE 200;
Execute o arquivo 2TDSPO_2024_CodigoSql_Integrantes.sql do início ao fim. Ele é idempotente: pode ser executado quantas vezes for necessário, pois remove (DROP) os objetos existentes antes de recriá-los.
Para conferir os erros tratados durante a carga de dados, consulte:
sql
   SELECT * FROM LOG_ERRO_CARGA ORDER BY ID_LOG_ERRO;
Para conferir a auditoria de alterações em CONSULTA, consulte:
sql
   SELECT * FROM AUDITORIA_LOG ORDER BY ID_LOG;
Documentação Complementar

A documentação técnica completa (modelo descritivo, diagrama entidade-relacionamento em notação de Barker, justificativa de normalização até a 3FN, código comentado e prints de execução) está disponível nos arquivos 2TDSPO_2024_Proj_BD.pdf e 2TDSPO_2024_Proj_BD_KuraVet.docx, entregues junto a este repositório.
