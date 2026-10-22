// =============================================================================
// KuraVet - Challenge FIAP 2026 x Clyvo Vet | Sprint 4 | Turma 2TDSPO
// Guilherme Macedo Martins (RM562396) | Pedro Henrique Luiz Alves Duarte (RM563405)
// Henrique Martins Oliveira (RM563620)
// -----------------------------------------------------------------------------
// 01_create.js - Criacao do banco "kuravet", colecoes com validacao
// ($jsonSchema) e indices.
// Uso: mongosh "<MONGO_URI>" --file mongodb/01_create.js
//
// Modelagem orientada a documentos (dados gerados por PKG_KV_EXPORT):
//   pets          -> 1 documento por pet, com o tutor resumido embutido e o
//                    historico de consultas embutido (cada consulta com o
//                    veterinario resumido e seus pagamentos). E exatamente o
//                    que o app do tutor le de uma vez: "meu pet e seu historico".
//   veterinarios  -> cadastro do veterinario com contato e estatisticas.
//                    Os pets guardam so um resumo do veterinario (padrao
//                    "extended reference"); o cadastro completo fica aqui.
// =============================================================================

const kv = db.getSiblingDB('kuravet');

['pets', 'veterinarios'].forEach((nome) => {
  if (kv.getCollectionNames().includes(nome)) {
    kv.getCollection(nome).drop();
    print(`Colecao ${nome} removida`);
  }
});

const inteiro = { bsonType: ['int', 'long'] };
const texto = { bsonType: 'string', minLength: 1 };
const textoOpcional = { bsonType: ['string', 'null'] };
const data = { bsonType: 'date' };

kv.createCollection('pets', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      title: 'Pet com tutor e historico de consultas',
      required: ['_id', 'nome', 'especie', 'sexo', 'data_nascimento', 'tutor', 'consultas'],
      properties: {
        _id: { ...inteiro, description: 'ID_PET no Oracle' },
        nome: texto,
        especie: texto,
        raca: textoOpcional,
        sexo: { enum: ['M', 'F'], description: 'M ou F' },
        data_nascimento: data,
        categoria_etaria: { enum: ['Filhote', 'Adulto', 'Idoso'] },
        tutor: {
          bsonType: 'object',
          required: ['id_tutor', 'nome', 'cpf'],
          properties: {
            id_tutor: inteiro,
            nome: texto,
            cpf: { bsonType: 'string', pattern: '^[0-9.\\-]{11,14}$' },
            telefone: textoOpcional,
            email: textoOpcional
          }
        },
        consultas: {
          bsonType: 'array',
          items: {
            bsonType: 'object',
            required: ['id_consulta', 'data_consulta', 'tipo', 'status', 'veterinario', 'pagamentos'],
            properties: {
              id_consulta: inteiro,
              data_solicitacao: data,
              data_consulta: data,
              tipo: texto,
              status: { enum: ['SOLICITADA', 'AGENDADA', 'REALIZADA', 'CANCELADA', 'RECUSADA'] },
              diagnostico: textoOpcional,
              motivo_recusa: textoOpcional,
              veterinario: {
                bsonType: 'object',
                required: ['id_veterinario', 'nome', 'crmv'],
                properties: {
                  id_veterinario: inteiro,
                  nome: texto,
                  crmv: texto,
                  especialidade: textoOpcional
                }
              },
              pagamentos: {
                bsonType: 'array',
                items: {
                  bsonType: 'object',
                  required: ['id_pagamento', 'clinica', 'tipo', 'valor', 'data_pagamento'],
                  properties: {
                    id_pagamento: inteiro,
                    clinica: texto,
                    tipo: { enum: ['Pix', 'Cartao de Credito', 'Cartao de Debito', 'Dinheiro'] },
                    valor: { bsonType: 'number', minimum: 0, exclusiveMinimum: true },
                    data_pagamento: data
                  }
                }
              }
            }
          }
        }
      }
    }
  },
  validationLevel: 'strict',
  validationAction: 'error'
});

kv.createCollection('veterinarios', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      title: 'Veterinario',
      required: ['_id', 'nome', 'crmv'],
      properties: {
        _id: { ...inteiro, description: 'ID_VETERINARIO no Oracle' },
        nome: texto,
        crmv: texto,
        especialidade: textoOpcional,
        contato: {
          bsonType: 'object',
          properties: {
            telefone: textoOpcional,
            email: textoOpcional
          }
        },
        estatisticas: {
          bsonType: 'object',
          properties: {
            total_consultas: { bsonType: 'number', minimum: 0 },
            consultas_realizadas: { bsonType: 'number', minimum: 0 }
          }
        }
      }
    }
  },
  validationLevel: 'strict',
  validationAction: 'error'
});

// Indices alinhados as consultas do app e do portal (03_queries.js)
kv.pets.createIndex({ 'tutor.cpf': 1 }, { name: 'ix_pets_tutor_cpf' });
kv.pets.createIndex({ especie: 1, raca: 1 }, { name: 'ix_pets_especie_raca' });
kv.pets.createIndex({ 'consultas.status': 1, 'consultas.data_consulta': 1 }, { name: 'ix_pets_consultas_status_data' });
kv.pets.createIndex({ 'consultas.veterinario.id_veterinario': 1 }, { name: 'ix_pets_consultas_vet' });
kv.veterinarios.createIndex({ crmv: 1 }, { name: 'ux_veterinarios_crmv', unique: true });
kv.veterinarios.createIndex({ especialidade: 1 }, { name: 'ix_veterinarios_especialidade' });

print('Colecoes criadas:');
kv.getCollectionInfos().forEach((c) => {
  print(` - ${c.name} (validador: ${c.options && c.options.validator ? 'sim' : 'nao'})`);
});
print('Indices de pets: ' + kv.pets.getIndexes().map((i) => i.name).join(', '));
print('Indices de veterinarios: ' + kv.veterinarios.getIndexes().map((i) => i.name).join(', '));
