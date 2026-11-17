-- RotaLog - Migration: tabela de alertas de manutenção preventiva em frotas.alertas_manutencao
-- Este script é idempotente (pode ser executado múltiplas vezes).
-- Em bancos já existentes (volume pgdata criado), execute manualmente:
--   docker exec -i <container-postgres> psql -U rotalog_admin -d rotalog < tools/scripts/10-add-alertas-manutencao.sql
-- Obrigatório ANTES de subir a api-frotas com a entidade AlertaManutencao (ddl-auto=validate).

SET search_path TO frotas;

CREATE TABLE IF NOT EXISTS alertas_manutencao (
    id BIGSERIAL PRIMARY KEY,
    veiculo_id BIGINT NOT NULL REFERENCES veiculos (id),
    placa VARCHAR(7) NOT NULL,
    motivo VARCHAR(30) NOT NULL,
    mensagem VARCHAR(500) NOT NULL,
    status VARCHAR(20) NOT NULL,
    detalhe_erro VARCHAR(500),
    tentativas INTEGER NOT NULL DEFAULT 0,
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_envio TIMESTAMP,
    CONSTRAINT ck_alertas_manutencao_status CHECK (status IN ('PENDENTE', 'ENVIADO', 'FALHA')),
    CONSTRAINT ck_alertas_manutencao_motivo CHECK (motivo IN ('QUILOMETRAGEM', 'TEMPO', 'QUILOMETRAGEM_E_TEMPO'))
);

-- Listagem por status (mais recentes primeiro) e checagem de duplicidade por veículo
CREATE INDEX IF NOT EXISTS idx_alertas_manutencao_status_criacao ON alertas_manutencao (status, data_criacao DESC);
CREATE INDEX IF NOT EXISTS idx_alertas_manutencao_veiculo ON alertas_manutencao (veiculo_id, data_criacao);

-- Consulta da última manutenção concluída por veículo (usada para calcular a elegibilidade)
CREATE INDEX IF NOT EXISTS idx_manutencoes_veiculo_status_data ON manutencoes (veiculo_id, status, data_manutencao DESC);
