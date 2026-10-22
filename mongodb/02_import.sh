#!/usr/bin/env bash
# =============================================================================
# KuraVet - Challenge FIAP 2026 x Clyvo Vet | Sprint 4 | Turma 2TDSPO
# Guilherme Macedo Martins (RM562396) | Pedro Henrique Luiz Alves Duarte (RM563405)
# Henrique Martins Oliveira (RM563620)
# -----------------------------------------------------------------------------
# 02_import.sh - Cria as colecoes (01_create.js) e importa os JSONs gerados
# pelo Oracle (sql/06_export_json.sql) com mongoimport.
#
# Uso (Linux, macOS ou Git Bash no Windows), a partir da raiz do repositorio:
#   export MONGO_URI="mongodb+srv://usuario:senha@cluster.xxxxx.mongodb.net"
#   bash mongodb/02_import.sh
#
# A URI NAO deve conter o nome do banco (o banco "kuravet" e definido aqui).
# Nunca commite a URI com senha: use variavel de ambiente.
# Requer: mongosh e MongoDB Database Tools (mongoimport).
# =============================================================================
set -euo pipefail

: "${MONGO_URI:?Defina MONGO_URI (ex.: mongodb://localhost:27017)}"

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
ARQ_PETS="$RAIZ/export/kuravet_pets.json"
ARQ_VETS="$RAIZ/export/kuravet_veterinarios.json"

for arq in "$ARQ_PETS" "$ARQ_VETS"; do
  if [ ! -s "$arq" ]; then
    echo "Arquivo nao encontrado ou vazio: $arq"
    echo "Gere os arquivos antes com: sql <usuario>@<host> @sql/06_export_json.sql"
    exit 1
  fi
done

echo ">> Criando colecoes, validadores e indices"
mongosh "$MONGO_URI" --quiet --file "$RAIZ/mongodb/01_create.js"

echo ">> Importando pets"
mongoimport --uri "$MONGO_URI" --db kuravet --collection pets \
  --jsonArray --file "$ARQ_PETS"

echo ">> Importando veterinarios"
mongoimport --uri "$MONGO_URI" --db kuravet --collection veterinarios \
  --jsonArray --file "$ARQ_VETS"

echo ">> Conferencia"
mongosh "$MONGO_URI" --quiet --eval '
  const kv = db.getSiblingDB("kuravet");
  print("pets: " + kv.pets.countDocuments());
  print("veterinarios: " + kv.veterinarios.countDocuments());
  print("tipo de data_nascimento do 1o pet: " + kv.pets.findOne().data_nascimento.constructor.name);
'
