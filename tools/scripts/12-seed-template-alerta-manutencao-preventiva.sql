-- RotaLog - Seed: template de e-mail do alerta de manutenção preventiva (api-notificacoes)
-- Este script é idempotente (pode ser executado múltiplas vezes).
-- Em bancos já existentes (volume pgdata criado), execute manualmente:
--   docker exec -i <container-postgres> psql -U rotalog_admin -d rotalog < tools/scripts/12-seed-template-alerta-manutencao-preventiva.sql

SET search_path TO notificacoes;

INSERT INTO templates_notificacao (tipo, canal, assunto_template, corpo_template, ativo)
SELECT 'ALERTA_MANUTENCAO_PREVENTIVA', 'email',
       'ALERTA: Manutenção preventiva - Veículo {{placa}}',
       E'{{mensagem}}\n\nVeículo: {{placa}}\nCritério: {{motivo}}\n\nEquipe RotaLog',
       true
WHERE NOT EXISTS (
    SELECT 1 FROM templates_notificacao WHERE tipo = 'ALERTA_MANUTENCAO_PREVENTIVA' AND canal = 'email'
);
