-- RotaLog - Seed: veículos elegíveis para manutenção preventiva
-- Regra (limites padrão da api-frotas: 10.000 km e 6 meses): veículo ATIVO é elegível se rodou mais de
-- 10.000 km OU passou de 6 meses desde a última manutenção CONCLUIDA (ou, sem manutenção, desde o cadastro).
-- As datas são relativas a NOW(), então o resultado vale em qualquer dia em que o script for executado.
-- Este script é idempotente (pode ser executado múltiplas vezes). Executar após o script 10.

SET search_path TO frotas;

-- Veículos
INSERT INTO veiculos (placa, modelo, ano_fabricacao, quilometragem, status, data_cadastro, data_atualizacao) VALUES
-- Elegíveis
('KMA1B23', 'Fiat Fiorino',            2021,  58000, 'ATIVO',   NOW() - INTERVAL '18 months', NOW() - INTERVAL '1 month'),   -- por km: 13.000 km desde a última manutenção
('TMP2C34', 'Mercedes Sprinter',       2020,  20000, 'ATIVO',   NOW() - INTERVAL '24 months', NOW() - INTERVAL '8 months'),  -- por tempo: 8 meses desde a última manutenção
('AMB3D45', 'VW Delivery 11.180',      2019, 140000, 'ATIVO',   NOW() - INTERVAL '30 months', NOW() - INTERVAL '9 months'),  -- por km e por tempo
('NUN4E56', 'Renault Master',          2022,   5000, 'ATIVO',   NOW() - INTERVAL '10 months', NOW() - INTERVAL '10 months'), -- nunca fez manutenção: 10 meses desde o cadastro
-- Não elegíveis (controles)
('OKK5F67', 'Iveco Daily 35S14',       2023,  32000, 'ATIVO',   NOW() - INTERVAL '12 months', NOW() - INTERVAL '1 month'),   -- manutenção recente e poucos km desde então
('INA6G78', 'Scania R450',             2018, 250000, 'INATIVO', NOW() - INTERVAL '40 months', NOW() - INTERVAL '12 months')  -- muito rodado, mas inativo
ON CONFLICT (placa) DO NOTHING;

-- Manutenções concluídas (base para o cálculo de km e de tempo desde a última manutenção)
INSERT INTO manutencoes (veiculo_id, tipo_manutencao, data_manutencao, quilometragem_manutencao, custo, descricao, status, data_criacao, data_atualizacao)
SELECT v.id, 'PREVENTIVA', m.data_manutencao, m.km, m.custo, m.descricao, 'CONCLUIDA', m.data_manutencao, m.data_manutencao
FROM (VALUES
    ('KMA1B23', NOW() - INTERVAL '1 month',  45000, 850.00, 'Seed alerta: preventiva há 1 mês (58.000 km hoje)'),
    ('TMP2C34', NOW() - INTERVAL '8 months', 18000, 700.00, 'Seed alerta: preventiva há 8 meses'),
    ('AMB3D45', NOW() - INTERVAL '9 months', 120000, 1200.00, 'Seed alerta: preventiva há 9 meses (140.000 km hoje)'),
    ('OKK5F67', NOW() - INTERVAL '1 month', 30000, 600.00, 'Seed alerta: preventiva recente, não elegível')
) AS m (placa, data_manutencao, km, custo, descricao)
JOIN veiculos v ON v.placa = m.placa
WHERE NOT EXISTS (
    SELECT 1 FROM manutencoes x WHERE x.veiculo_id = v.id AND x.descricao = m.descricao
);

-- Verificação: veículos ativos e distância (km/meses) desde a última manutenção concluída
SELECT v.placa, v.modelo, v.status, v.quilometragem,
       v.quilometragem - COALESCE(u.km, 0) AS km_desde_ultima,
       ROUND(EXTRACT(EPOCH FROM (NOW() - COALESCE(u.data, v.data_cadastro))) / 2592000) AS meses_desde_ultima,
       (v.status = 'ATIVO'
        AND (v.quilometragem - COALESCE(u.km, 0) > 10000
             OR COALESCE(u.data, v.data_cadastro) < NOW() - INTERVAL '6 months')) AS elegivel
FROM veiculos v
LEFT JOIN LATERAL (
    SELECT m.data_manutencao AS data, m.quilometragem_manutencao AS km
    FROM manutencoes m
    WHERE m.veiculo_id = v.id AND m.status = 'CONCLUIDA' AND m.data_manutencao IS NOT NULL
    ORDER BY m.data_manutencao DESC
    LIMIT 1
) u ON TRUE
ORDER BY v.id;
