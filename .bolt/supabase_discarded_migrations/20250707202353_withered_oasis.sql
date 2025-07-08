/*
  # Drop e Recriação Completa do Schema DriveSync

  Este arquivo remove completamente o schema existente e recria todas as tabelas,
  funções, triggers e políticas RLS do sistema DriveSync.

  ## Estrutura:
  1. Drop de todas as tabelas existentes
  2. Criação de tipos customizados
  3. Criação de todas as tabelas
  4. Configuração de RLS e políticas
  5. Criação de funções e triggers
  6. Inserção de dados de teste

  ATENÇÃO: Este script irá APAGAR TODOS OS DADOS existentes!
*/

-- =============================================
-- 1. DROP DE TODAS AS TABELAS EXISTENTES
-- =============================================

DROP TABLE IF EXISTS planos_viagem_alteracoes CASCADE;
DROP TABLE IF EXISTS planos_viagem_custom_trajetos CASCADE;
DROP TABLE IF EXISTS planos_viagem_viagens CASCADE;
DROP TABLE IF EXISTS planos_viagem CASCADE;
DROP TABLE IF EXISTS lembretes_manutencao CASCADE;
DROP TABLE IF EXISTS abastecimentos CASCADE;
DROP TABLE IF EXISTS passageiros CASCADE;
DROP TABLE IF EXISTS viagens CASCADE;
DROP TABLE IF EXISTS motoristas_veiculos CASCADE;
DROP TABLE IF EXISTS veiculos CASCADE;
DROP TABLE IF EXISTS motoristas CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;

-- Drop de tabelas do sistema de autenticação (se existirem)
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS analytics CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS subscribers CASCADE;
DROP TABLE IF EXISTS plans CASCADE;
DROP TABLE IF EXISTS vcards CASCADE;

-- Drop de tipos customizados
DROP TYPE IF EXISTS user_role CASCADE;

-- Drop de funções
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS handle_user_settings() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS is_admin(uuid) CASCADE;
DROP FUNCTION IF EXISTS uid() CASCADE;

-- =============================================
-- 2. CRIAÇÃO DE TIPOS CUSTOMIZADOS
-- =============================================

CREATE TYPE user_role AS ENUM ('admin', 'operador', 'motorista');

-- =============================================
-- 3. CRIAÇÃO DE FUNÇÕES AUXILIARES
-- =============================================

-- Função para obter o ID do usuário atual
CREATE OR REPLACE FUNCTION uid() RETURNS uuid AS $$
  SELECT auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Função para verificar se é admin
CREATE OR REPLACE FUNCTION is_admin(user_id uuid) RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM usuarios 
    WHERE id = user_id AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 4. CRIAÇÃO DAS TABELAS PRINCIPAIS
-- =============================================

-- Tabela de tenants (clientes/empresas)
CREATE TABLE tenants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome text NOT NULL,
  cidade text,
  uf text,
  logo_url text,
  cor_primaria text DEFAULT '#1E40AF',
  cor_secundaria text DEFAULT '#059669',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de usuários
CREATE TABLE usuarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  nome text NOT NULL,
  role text DEFAULT 'operador' CHECK (role IN ('admin', 'operador', 'motorista')),
  avatar_url text,
  telefone text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de motoristas
CREATE TABLE motoristas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  nome text NOT NULL,
  telefone text,
  cnh text,
  validade_cnh date,
  status text DEFAULT 'disponivel' CHECK (status IN ('disponivel', 'indisponivel')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de veículos
CREATE TABLE veiculos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  placa text NOT NULL,
  modelo text NOT NULL,
  tipo text NOT NULL,
  quilometragem_atual integer DEFAULT 0,
  identificacao_interna text,
  status text DEFAULT 'disponivel' CHECK (status IN ('disponivel', 'em_manutencao')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de associação motoristas-veículos (muitos para muitos)
CREATE TABLE motoristas_veiculos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  motorista_id uuid REFERENCES motoristas(id) ON DELETE CASCADE,
  veiculo_id uuid REFERENCES veiculos(id) ON DELETE CASCADE,
  ativo boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Tabela de viagens
CREATE TABLE viagens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  motorista_id uuid REFERENCES motoristas(id),
  veiculo_id uuid REFERENCES veiculos(id),
  agendador_id uuid REFERENCES usuarios(id),
  data_viagem timestamptz NOT NULL,
  data_saida timestamptz,
  km_saida integer,
  data_chegada timestamptz,
  km_chegada integer,
  observacoes text,
  status text DEFAULT 'agendada' CHECK (status IN ('agendada', 'em_andamento', 'concluida', 'cancelada')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de passageiros
CREATE TABLE passageiros (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  viagem_id uuid REFERENCES viagens(id) ON DELETE CASCADE,
  nome text NOT NULL,
  documento text,
  created_at timestamptz DEFAULT now()
);

-- Tabela de abastecimentos
CREATE TABLE abastecimentos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  viagem_id uuid REFERENCES viagens(id),
  motorista_id uuid REFERENCES motoristas(id),
  veiculo_id uuid REFERENCES veiculos(id),
  data_abastecimento timestamptz NOT NULL,
  local text NOT NULL,
  tipo_combustivel text NOT NULL,
  litros numeric NOT NULL,
  valor_total numeric NOT NULL,
  quilometragem integer,
  comprovante_url text,
  created_at timestamptz DEFAULT now()
);

-- Tabela de planos de viagem
CREATE TABLE planos_viagem (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  motorista_id uuid REFERENCES motoristas(id),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  titulo text NOT NULL,
  descricao text,
  data_criacao timestamptz DEFAULT now(),
  status text DEFAULT 'pendente' CHECK (status IN ('pendente', 'aprovado', 'rejeitado')),
  enviado_para text,
  criado_do_zero boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de viagens associadas aos planos
CREATE TABLE planos_viagem_viagens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plano_id uuid REFERENCES planos_viagem(id) ON DELETE CASCADE,
  viagem_id uuid REFERENCES viagens(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- Tabela de trajetos customizados nos planos
CREATE TABLE planos_viagem_custom_trajetos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plano_id uuid REFERENCES planos_viagem(id) ON DELETE CASCADE,
  data_viagem date NOT NULL,
  destino text NOT NULL,
  km_estimado integer,
  observacoes text,
  created_at timestamptz DEFAULT now()
);

-- Tabela de alterações nos planos
CREATE TABLE planos_viagem_alteracoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plano_id uuid REFERENCES planos_viagem(id) ON DELETE CASCADE,
  motorista_id uuid REFERENCES motoristas(id),
  data_alteracao timestamptz DEFAULT now(),
  justificativa text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Tabela de lembretes de manutenção
CREATE TABLE lembretes_manutencao (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  veiculo_id uuid REFERENCES veiculos(id) ON DELETE CASCADE,
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  tipo text NOT NULL,
  data_prevista date,
  km_previsto integer,
  descricao text,
  status text DEFAULT 'aberto' CHECK (status IN ('aberto', 'concluido', 'cancelado')),
  data_conclusao date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- =============================================
-- 5. CONFIGURAÇÃO DE ROW LEVEL SECURITY (RLS)
-- =============================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE motoristas ENABLE ROW LEVEL SECURITY;
ALTER TABLE veiculos ENABLE ROW LEVEL SECURITY;
ALTER TABLE motoristas_veiculos ENABLE ROW LEVEL SECURITY;
ALTER TABLE viagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE passageiros ENABLE ROW LEVEL SECURITY;
ALTER TABLE abastecimentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE planos_viagem ENABLE ROW LEVEL SECURITY;
ALTER TABLE planos_viagem_viagens ENABLE ROW LEVEL SECURITY;
ALTER TABLE planos_viagem_custom_trajetos ENABLE ROW LEVEL SECURITY;
ALTER TABLE planos_viagem_alteracoes ENABLE ROW LEVEL SECURITY;
ALTER TABLE lembretes_manutencao ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 6. CRIAÇÃO DE POLÍTICAS RLS
-- =============================================

-- Políticas para tenants
CREATE POLICY "Tenants podem ver apenas seus dados" ON tenants
  FOR ALL USING (id = ((jwt() ->> 'tenant_id')::uuid));

-- Políticas para usuários
CREATE POLICY "Usuários podem ver dados do seu tenant" ON usuarios
  FOR ALL USING (tenant_id = ((jwt() ->> 'tenant_id')::uuid));

-- Políticas para motoristas
CREATE POLICY "Motoristas podem ver dados do seu tenant" ON motoristas
  FOR ALL USING (tenant_id = ((jwt() ->> 'tenant_id')::uuid));

-- Políticas para veículos
CREATE POLICY "Veículos podem ver dados do seu tenant" ON veiculos
  FOR ALL USING (tenant_id = ((jwt() ->> 'tenant_id')::uuid));

-- Políticas para associações motorista-veículo
CREATE POLICY "Associações motorista-veículo por tenant" ON motoristas_veiculos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM motoristas m 
      WHERE m.id = motoristas_veiculos.motorista_id 
      AND m.tenant_id = ((jwt() ->> 'tenant_id')::uuid)
    )
  );

-- Políticas para viagens
CREATE POLICY "Viagens podem ver dados do seu tenant" ON viagens
  FOR ALL USING (tenant_id = ((jwt() ->> 'tenant_id')::uuid));

-- Políticas para passageiros
CREATE POLICY "Passageiros por viagem do tenant" ON passageiros
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM viagens v 
      WHERE v.id = passageiros.viagem_id 
      AND v.tenant_id = ((jwt() ->> 'tenant_id')::uuid)
    )
  );

-- Políticas para abastecimentos
CREATE POLICY "Abastecimentos podem ver dados do seu tenant" ON abastecimentos
  FOR ALL USING (tenant_id = ((jwt() ->> 'tenant_id')::uuid));

-- Políticas para planos de viagem
CREATE POLICY "Planos de viagem podem ver dados do seu tenant" ON planos_viagem
  FOR ALL USING (tenant_id = ((jwt() ->> 'tenant_id')::uuid));

-- Políticas para planos-viagens
CREATE POLICY "Planos-viagens por tenant" ON planos_viagem_viagens
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM planos_viagem p 
      WHERE p.id = planos_viagem_viagens.plano_id 
      AND p.tenant_id = ((jwt() ->> 'tenant_id')::uuid)
    )
  );

-- Políticas para trajetos customizados
CREATE POLICY "Trajetos customizados por tenant" ON planos_viagem_custom_trajetos
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM planos_viagem p 
      WHERE p.id = planos_viagem_custom_trajetos.plano_id 
      AND p.tenant_id = ((jwt() ->> 'tenant_id')::uuid)
    )
  );

-- Políticas para alterações
CREATE POLICY "Alterações por tenant" ON planos_viagem_alteracoes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM planos_viagem p 
      WHERE p.id = planos_viagem_alteracoes.plano_id 
      AND p.tenant_id = ((jwt() ->> 'tenant_id')::uuid)
    )
  );

-- Políticas para lembretes de manutenção
CREATE POLICY "Lembretes de manutenção por tenant" ON lembretes_manutencao
  FOR ALL USING (tenant_id = ((jwt() ->> 'tenant_id')::uuid));

-- =============================================
-- 7. CRIAÇÃO DE TRIGGERS
-- =============================================

-- Triggers para atualizar updated_at automaticamente
CREATE TRIGGER update_tenants_updated_at
  BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_usuarios_updated_at
  BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_motoristas_updated_at
  BEFORE UPDATE ON motoristas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_veiculos_updated_at
  BEFORE UPDATE ON veiculos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_viagens_updated_at
  BEFORE UPDATE ON viagens
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_planos_viagem_updated_at
  BEFORE UPDATE ON planos_viagem
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lembretes_manutencao_updated_at
  BEFORE UPDATE ON lembretes_manutencao
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 8. INSERÇÃO DE DADOS DE TESTE
-- =============================================

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

-- =============================================
-- 9. COMENTÁRIOS FINAIS
-- =============================================

-- Schema criado com sucesso!
-- Todas as tabelas possuem RLS habilitado
-- Dados de teste inseridos
-- Sistema pronto para uso

COMMENT ON SCHEMA public IS 'Schema principal do DriveSync - Sistema de Gestão de Frotas';