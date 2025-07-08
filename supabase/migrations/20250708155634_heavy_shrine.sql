-- =============================================
-- ATUALIZAÇÃO DO TENANT PARA MANOEL VIANA
-- =============================================

-- Atualizar tenant existente para Manoel Viana
UPDATE tenants 
SET 
  nome = 'Prefeitura Municipal de Manoel Viana',
  cidade = 'Manoel Viana',
  uf = 'RS',
  cor_primaria = '#2563EB',
  cor_secundaria = '#059669'
WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Atualizar emails dos usuários para refletir o novo município
UPDATE usuarios 
SET 
  email = CASE 
    WHEN email = 'admin@sp.gov.br' THEN 'admin@manoelviana.rs.gov.br'
    WHEN email = 'operador@sp.gov.br' THEN 'operador@manoelviana.rs.gov.br'
    WHEN email = 'motorista@sp.gov.br' THEN 'motorista@manoelviana.rs.gov.br'
    ELSE email
  END,
  telefone = CASE 
    WHEN telefone = '(11) 3333-1000' THEN '(55) 3256-1000'
    WHEN telefone = '(11) 3333-1001' THEN '(55) 3256-1001'
    WHEN telefone = '(11) 99999-1234' THEN '(55) 99999-1234'
    ELSE telefone
  END
WHERE tenant_id = '550e8400-e29b-41d4-a716-446655440000';

-- Atualizar telefones dos motoristas para DDD do RS
UPDATE motoristas 
SET 
  telefone = CASE 
    WHEN telefone = '(11) 99999-1234' THEN '(55) 99999-1234'
    WHEN telefone = '(11) 99999-5678' THEN '(55) 99999-5678'
    WHEN telefone = '(11) 99999-9999' THEN '(55) 99999-9999'
    WHEN telefone = '(11) 99999-7777' THEN '(55) 99999-7777'
    WHEN telefone = '(11) 99999-8888' THEN '(55) 99999-8888'
    ELSE telefone
  END
WHERE tenant_id = '550e8400-e29b-41d4-a716-446655440000';

-- Atualizar observações das viagens para refletir locais de Manoel Viana/região
UPDATE viagens 
SET 
  observacoes = CASE 
    WHEN observacoes = 'Transporte para Hospital das Clínicas' THEN 'Transporte para Hospital Regional de Alegrete'
    WHEN observacoes = 'Emergência médica - Zona Sul' THEN 'Emergência médica - Centro da cidade'
    WHEN observacoes = 'Transporte de equipamentos' THEN 'Transporte de equipamentos para UBS'
    ELSE observacoes
  END
WHERE tenant_id = '550e8400-e29b-41d4-a716-446655440000';

-- Atualizar locais de abastecimento
UPDATE abastecimentos 
SET 
  local = CASE 
    WHEN local = 'Posto Shell - Av. Paulista' THEN 'Posto Ipiranga - Centro'
    WHEN local = 'Posto BR - Marginal Tietê' THEN 'Posto BR - RS-377'
    ELSE local
  END
WHERE tenant_id = '550e8400-e29b-41d4-a716-446655440000';

-- Atualizar títulos dos planos de viagem
UPDATE planos_viagem 
SET 
  titulo = CASE 
    WHEN titulo = 'Plano Semanal - Hospitais Zona Norte' THEN 'Plano Semanal - Cobertura Regional'
    WHEN titulo = 'Emergências Fim de Semana' THEN 'Plantão Emergencial - Final de Semana'
    ELSE titulo
  END,
  descricao = CASE 
    WHEN descricao = 'Cobertura dos hospitais da região norte durante a semana' THEN 'Cobertura dos serviços de saúde da região durante a semana'
    WHEN descricao = 'Plantão de emergências para sábado e domingo' THEN 'Plantão de emergências para final de semana'
    ELSE descricao
  END,
  enviado_para = CASE 
    WHEN enviado_para = 'Coordenação de Saúde' THEN 'Secretaria Municipal de Saúde'
    WHEN enviado_para = 'Supervisão Médica' THEN 'Coordenação de Saúde'
    ELSE enviado_para
  END
WHERE tenant_id = '550e8400-e29b-41d4-a716-446655440000';

SELECT 'Tenant atualizado para Prefeitura Municipal de Manoel Viana - RS' as status;