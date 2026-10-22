// =============================================================================
// KuraVet - Challenge FIAP 2026 x Clyvo Vet | Sprint 4 | Turma 2TDSPO
// Guilherme Macedo Martins (RM562396) | Pedro Henrique Luiz Alves Duarte (RM563405)
// Henrique Martins Oliveira (RM563620)
// -----------------------------------------------------------------------------
// 03_queries.js - Consultas de demonstracao sobre os dados importados
// Uso: mongosh "<MONGO_URI>" --file mongodb/03_queries.js
// =============================================================================

const kv = db.getSiblingDB('kuravet');

function titulo(t) {
  print('\n' + '='.repeat(78) + '\n' + t + '\n' + '='.repeat(78));
}

// -----------------------------------------------------------------------------
titulo('Q1 - App do tutor: pets e historico de um tutor (busca por CPF)');
printjson(
  kv.pets.find(
    { 'tutor.cpf': '111.222.333-44' },
    { nome: 1, especie: 1, categoria_etaria: 1, 'consultas.data_consulta': 1,
      'consultas.tipo': 1, 'consultas.status': 1, 'consultas.diagnostico': 1 }
  ).toArray()
);

// -----------------------------------------------------------------------------
titulo('Q2 - Portal da clinica: consultas SOLICITADAS/AGENDADAS a partir de hoje');
printjson(
  kv.pets.aggregate([
    { $unwind: '$consultas' },
    { $match: {
        'consultas.status': { $in: ['SOLICITADA', 'AGENDADA'] },
        'consultas.data_consulta': { $gte: new Date(new Date().setHours(0, 0, 0, 0)) }
    } },
    { $project: {
        _id: 0,
        pet: '$nome',
        tutor: '$tutor.nome',
        id_consulta: '$consultas.id_consulta',
        data: '$consultas.data_consulta',
        tipo: '$consultas.tipo',
        status: '$consultas.status',
        veterinario: '$consultas.veterinario.nome'
    } },
    { $sort: { data: 1 } }
  ]).toArray()
);

// -----------------------------------------------------------------------------
titulo('Q3 - Faturamento por clinica e tipo de pagamento (espelho do PRC_SUBTOTAIS_PAGAMENTO)');
printjson(
  kv.pets.aggregate([
    { $unwind: '$consultas' },
    { $unwind: '$consultas.pagamentos' },
    { $group: {
        _id: { clinica: '$consultas.pagamentos.clinica', tipo: '$consultas.pagamentos.tipo' },
        valor: { $sum: '$consultas.pagamentos.valor' }
    } },
    { $sort: { '_id.clinica': 1, '_id.tipo': 1 } },
    { $group: {
        _id: '$_id.clinica',
        tipos: { $push: { tipo: '$_id.tipo', valor: '$valor' } },
        sub_total: { $sum: '$valor' }
    } },
    { $sort: { _id: 1 } }
  ]).toArray()
);
const total = kv.pets.aggregate([
  { $unwind: '$consultas' },
  { $unwind: '$consultas.pagamentos' },
  { $group: { _id: null, total_geral: { $sum: '$consultas.pagamentos.valor' } } }
]).toArray();
print('Total Geral: ' + (total.length ? total[0].total_geral : 0));

// -----------------------------------------------------------------------------
titulo('Q4 - Atendimentos por especialidade do veterinario e status');
printjson(
  kv.pets.aggregate([
    { $unwind: '$consultas' },
    { $group: {
        _id: { especialidade: '$consultas.veterinario.especialidade', status: '$consultas.status' },
        quantidade: { $sum: 1 }
    } },
    { $sort: { '_id.especialidade': 1, quantidade: -1 } }
  ]).toArray()
);

// -----------------------------------------------------------------------------
titulo('Q5 - Pets idosos com consulta de cardiologia realizada ($elemMatch)');
printjson(
  kv.pets.find(
    {
      categoria_etaria: 'Idoso',
      consultas: { $elemMatch: { tipo: 'Cardiologia', status: 'REALIZADA' } }
    },
    { nome: 1, especie: 1, raca: 1, 'tutor.nome': 1 }
  ).toArray()
);

// -----------------------------------------------------------------------------
titulo('Q6 - Veterinarios e pets atendidos ($lookup entre as colecoes)');
printjson(
  kv.veterinarios.aggregate([
    { $lookup: {
        from: 'pets',
        localField: '_id',
        foreignField: 'consultas.veterinario.id_veterinario',
        as: 'pets_atendidos'
    } },
    { $project: {
        _id: 0,
        nome: 1,
        especialidade: 1,
        consultas_realizadas: '$estatisticas.consultas_realizadas',
        pets: '$pets_atendidos.nome'
    } },
    { $sort: { nome: 1 } }
  ]).toArray()
);

// -----------------------------------------------------------------------------
titulo('Q7 - Validador: documento invalido e rejeitado (sexo "X", sem tutor)');
try {
  kv.pets.insertOne({ _id: 99999, nome: 'Invalido', especie: 'Cachorro', sexo: 'X',
                      data_nascimento: new Date(), consultas: [] });
  print('ATENCAO: documento invalido foi aceito (validador nao esta ativo)');
} catch (e) {
  print('Rejeitado pelo $jsonSchema -> codigo ' + e.code + ': ' + e.message);
}
