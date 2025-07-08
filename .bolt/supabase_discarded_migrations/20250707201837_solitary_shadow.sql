/*
  # Inserir dados de teste para DriveSync

  1. Dados de Teste
    - Tenant de exemplo (Prefeitura de São Paulo)
    - Usuários de teste com diferentes roles
    - Motoristas de exemplo
    - Veículos de exemplo
    - Dados relacionados para demonstração

  2. Credenciais de Teste
    - admin@sp.gov.br / demo123 (Administrador)
    - operador@sp.gov.br / demo123 (Operador)
    - motorista@sp.gov.br / demo123 (Motorista)

  3. Segurança
    - Senhas são hasheadas pelo Supabase Auth
    - RLS aplicado automaticamente
*/

-- Inserir tenant de exemplo
INSERT INTO tenants (id, nome, cidade, uf, logo_url, cor_primaria, cor_secundaria) VALUES
(
  '550e8400-e29b-41d4-a716-446655440000',
  'Prefeitura Municipal de São Paulo',
  'São Paulo',
  'SP',
  'https://images.pexels.com/photos/8828786/pexels-photo-8828786.jpeg?auto=compress&cs=tinysrgb&w=100&h=100&dpr=2',
  '#1E40AF',
  '#059669'
);

-- Inserir usuários de exemplo
INSERT INTO usuarios (id, tenant_id, email, nome, role, telefone) VALUES
(
  '550e8400-e29b-41d4-a716-446655440001',
  '550e8400-e29b-41d4-a716-446655440000',
  'admin@sp.gov.br',
  'João Silva Santos',
  'admin',
  '(11) 99999-0001'
),
(
  '550e8400-e29b-41d4-a716-446655440002',
  '550e8400-e29b-41d4-a716-446655440000',
  'operador@sp.gov.br',
  'Maria Oliveira Costa',
  'operador',
  '(11) 99999-0002'
),
(
  '550e8400-e29b-41d4-a716-446655440003',
  '550e8400-e29b-41d4-a716-446655440000',
  'motorista@sp.gov.br',
  'Carlos Eduardo Pereira',
  'motorista',
  '(11) 99999-0003'
);

-- Inserir motoristas de exemplo
INSERT INTO motoristas (id, tenant_id, nome, telefone, cnh, validade_cnh, status) VALUES
(
  '550e8400-e29b-41d4-a716-446655440010',
  '550e8400-e29b-41d4-a716-446655440000',
  'Carlos Eduardo Pereira',
  '(11) 99999-1234',
  '12345678901',
  '2025-12-31',
  'disponivel'
),
(
  '550e8400-e29b-41d4-a716-446655440011',
  '550e8400-e29b-41d4-a716-446655440000',
  'Ana Paula Santos',
  '(11) 99999-5678',
  '98765432109',
  '2025-08-15',
  'disponivel'
),
(
  '550e8400-e29b-41d4-a716-446655440012',
  '550e8400-e29b-41d4-a716-446655440000',
  'Ricardo Alves Lima',
  '(11) 99999-9999',
  '55555555555',
  '2025-06-30',
  'indisponivel'
),
(
  '550e8400-e29b-41d4-a716-446655440013',
  '550e8400-e29b-41d4-a716-446655440000',
  'Fernanda Costa Silva',
  '(11) 99999-7777',
  '11111111111',
  '2026-03-20',
  'disponivel'
),
(
  '550e8400-e29b-41d4-a716-446655440014',
  '550e8400-e29b-41d4-a716-446655440000',
  'Roberto Machado Junior',
  '(11) 99999-8888',
  '22222222222',
  '2025-02-28',
  'disponivel'
);

-- Inserir veículos de exemplo
INSERT INTO veiculos (id, tenant_id, placa, modelo, tipo, quilometragem_atual, identificacao_interna, status) VALUES
(
  '550e8400-e29b-41d4-a716-446655440020',
  '550e8400-e29b-41d4-a716-446655440000',
  'ABC-1234',
  'Fiat Ducato 2022',
  'Van',
  45000,
  'VAN-001',
  'disponivel'
),
(
  '550e8400-e29b-41d4-a716-446655440021',
  '550e8400-e29b-41d4-a716-446655440000',
  'DEF-5678',
  'Mercedes Sprinter 2021',
  'Ambulância',
  32000,
  'AMB-001',
  'disponivel'
),
(
  '550e8400-e29b-41d4-a716-446655440022',
  '550e8400-e29b-41d4-a716-446655440000',
  'GHI-9012',
  'Ford Transit 2020',
  'Van',
  67000,
  'VAN-002',
  'em_manutencao'
),
(
  '550e8400-e29b-41d4-a716-446655440023',
  '550e8400-e29b-41d4-a716-446655440000',
  'JKL-3456',
  'Volkswagen Crafter 2023',
  'Van',
  15000,
  'VAN-003',
  'disponivel'
),
(
  '550e8400-e29b-41d4-a716-446655440024',
  '550e8400-e29b-41d4-a716-446655440000',
  'MNO-7890',
  'Iveco Daily 2022',
  'Caminhonete',
  28000,
  'CAM-001',
  'disponivel'
);

-- Inserir associações motorista-veículo
INSERT INTO motoristas_veiculos (motorista_id, veiculo_id, ativo) VALUES
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440020', true),
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440021', true),
('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440021', true),
('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440023', true),
('550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440024', true),
('550e8400-e29b-41d4-a716-446655440014', '550e8400-e29b-41d4-a716-446655440020', true);

-- Inserir viagens de exemplo
INSERT INTO viagens (id, tenant_id, motorista_id, veiculo_id, agendador_id, data_viagem, data_saida, km_saida, data_chegada, km_chegada, observacoes, status) VALUES
(
  '550e8400-e29b-41d4-a716-446655440030',
  '550e8400-e29b-41d4-a716-446655440000',
  '550e8400-e29b-41d4-a716-446655440010',
  '550e8400-e29b-41d4-a716-446655440020',
  '550e8400-e29b-41d4-a716-446655440001',
  '2025-01-07 08:00:00',
  '2025-01-07 08:15:00',
  45000,
  '2025-01-07 12:30:00',
  45085,
  'Transporte para Hospital das Clínicas',
  'concluida'
),
(
  '550e8400-e29b-41d4-a716-446655440031',
  '550e8400-e29b-41d4-a716-446655440000',
  '550e8400-e29b-41d4-a716-446655440011',
  '550e8400-e29b-41d4-a716-446655440021',
  '550e8400-e29b-41d4-a716-446655440002',
  '2025-01-07 14:00:00',
  '2025-01-07 14:10:00',
  32000,
  NULL,
  NULL,
  'Emergência médica - Zona Sul',
  'em_andamento'
),
(
  '550e8400-e29b-41d4-a716-446655440032',
  '550e8400-e29b-41d4-a716-446655440000',
  '550e8400-e29b-41d4-a716-446655440013',
  NULL,
  '550e8400-e29b-41d4-a716-446655440001',
  '2025-01-08 09:00:00',
  NULL,
  NULL,
  NULL,
  NULL,
  'Transporte escolar - Região Norte',
  'agendada'
);

-- Inserir passageiros de exemplo
INSERT INTO passageiros (viagem_id, nome, documento) VALUES
('550e8400-e29b-41d4-a716-446655440030', 'José da Silva', '123.456.789-00'),
('550e8400-e29b-41d4-a716-446655440030', 'Maria Santos', '987.654.321-00'),
('550e8400-e29b-41d4-a716-446655440031', 'Pedro Oliveira', '456.789.123-00'),
('550e8400-e29b-41d4-a716-446655440032', 'Ana Costa', '789.123.456-00'),
('550e8400-e29b-41d4-a716-446655440032', 'Carlos Lima', '321.654.987-00');

-- Inserir abastecimentos de exemplo
INSERT INTO abastecimentos (id, tenant_id, viagem_id, motorista_id, veiculo_id, data_abastecimento, local, tipo_combustivel, litros, valor_total, quilometragem) VALUES
(
  '550e8400-e29b-41d4-a716-446655440040',
  '550e8400-e29b-41d4-a716-446655440000',
  '550e8400-e29b-41d4-a716-446655440030',
  '550e8400-e29b-41d4-a716-446655440010',
  '550e8400-e29b-41d4-a716-446655440020',
  '2025-01-07 10:30:00',
  'Posto Shell - Av. Paulista',
  'Diesel',
  45.5,
  320.50,
  45042
),
(
  '550e8400-e29b-41d4-a716-446655440041',
  '550e8400-e29b-41d4-a716-446655440000',
  NULL,
  '550e8400-e29b-41d4-a716-446655440011',
  '550e8400-e29b-41d4-a716-446655440021',
  '2025-01-06 16:45:00',
  'Posto BR - Marginal Tietê',
  'Gasolina',
  38.2,
  245.80,
  31987
);

-- Inserir lembretes de manutenção
INSERT INTO lembretes_manutencao (id, veiculo_id, tenant_id, tipo, data_prevista, km_previsto, descricao, status) VALUES
(
  '550e8400-e29b-41d4-a716-446655440050',
  '550e8400-e29b-41d4-a716-446655440020',
  '550e8400-e29b-41d4-a716-446655440000',
  'Troca de óleo',
  '2025-01-15',
  50000,
  'Troca de óleo e filtros - manutenção preventiva',
  'aberto'
),
(
  '550e8400-e29b-41d4-a716-446655440051',
  '550e8400-e29b-41d4-a716-446655440022',
  '550e8400-e29b-41d4-a716-446655440000',
  'Revisão geral',
  '2025-01-10',
  NULL,
  'Revisão completa do sistema elétrico',
  'aberto'
),
(
  '550e8400-e29b-41d4-a716-446655440052',
  '550e8400-e29b-41d4-a716-446655440021',
  '550e8400-e29b-41d4-a716-446655440000',
  'Troca de pneus',
  '2025-02-01',
  35000,
  'Substituição dos pneus dianteiros',
  'aberto'
);

-- Inserir planos de viagem de exemplo
INSERT INTO planos_viagem (id, motorista_id, tenant_id, titulo, descricao, status, enviado_para, criado_do_zero) VALUES
(
  '550e8400-e29b-41d4-a716-446655440060',
  '550e8400-e29b-41d4-a716-446655440010',
  '550e8400-e29b-41d4-a716-446655440000',
  'Plano Semanal - Transporte Hospitalar',
  'Planejamento de rotas para atendimento hospitalar na região central',
  'aprovado',
  'Coordenação de Saúde',
  false
),
(
  '550e8400-e29b-41d4-a716-446655440061',
  '550e8400-e29b-41d4-a716-446655440011',
  '550e8400-e29b-41d4-a716-446655440000',
  'Emergências - Zona Sul',
  'Cobertura de emergências médicas na região sul da cidade',
  'pendente',
  'Supervisão Médica',
  true
);