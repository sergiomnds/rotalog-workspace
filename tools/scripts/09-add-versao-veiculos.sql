-- RotaLog - Migration: coluna de controle de concorrência otimista (@Version) em frotas.veiculos
-- Este script é idempotente (pode ser executado múltiplas vezes).
-- Em bancos já existentes (volume pgdata criado), execute manualmente:
--   docker exec -i <container-postgres> psql -U rotalog_admin -d rotalog < tools/scripts/09-add-versao-veiculos.sql
-- Obrigatório ANTES de subir a api-frotas com a entidade Veiculo versionada (ddl-auto=validate).

SET search_path TO frotas;

ALTER TABLE veiculos ADD COLUMN IF NOT EXISTS versao BIGINT NOT NULL DEFAULT 0;
