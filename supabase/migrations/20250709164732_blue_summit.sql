/*
  # DriveSync - Single Tenant Architecture
  
  Refatoração para arquitetura single-tenant:
  - Remove tabela tenants
  - Remove tenant_id de todas as tabelas
  - Simplifica políticas RLS
  - Mantém funcionalidades principais
*/

-- =============================================
-- 1. LIMPEZA COMPLETA DO BANCO
-- =============================================

-- Desabilitar RLS temporariamente para limpeza
SET session_replication_role = replica;

-- Drop todas as tabelas em ordem (respeitando foreign keys)
DROP TABLE IF EXISTS planos_viagem_alteracoes CASCADE;
DROP TABLE IF EXISTS planos_viagem_custom_trajetos CASCADE;
DROP TABLE IF EXISTS planos_viagem_viagens CASCADE;
DROP TABLE IF EXISTS lembretes_manutencao CASCADE;
DROP TABLE IF EXISTS abastecimentos CASCADE;
DROP TABLE IF EXISTS passageiros CASCADE;
DROP TABLE IF EXISTS viagens CASCADE;
DROP TABLE IF EXISTS motoristas_veiculos CASCADE;
DROP TABLE IF EXISTS veiculos CASCADE;
DROP TABLE IF EXISTS motoristas CASCADE;
DROP TABLE IF EXISTS planos_viagem CASCADE;
DROP TABLE IF EXISTS user_settings CASCADE;
DROP TABLE IF EXISTS analytics CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS user_roles CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS subscribers CASCADE;
DROP TABLE IF EXISTS plans CASCADE;
DROP TABLE IF EXISTS vcards CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;

-- Drop tipos customizados
DROP TYPE IF EXISTS user_role CASCADE;

-- Drop funções
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS handle_user_settings() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS uid() CASCADE;
DROP FUNCTION IF EXISTS is_admin(uuid) CASCADE;

-- Reabilitar RLS
SET session_replication_role = DEFAULT;

-- =============================================
-- 2. CRIAÇÃO DE TIPOS E FUNÇÕES BÁSICAS
-- =============================================

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Função para obter user ID atual
CREATE OR REPLACE FUNCTION uid() RETURNS uuid AS $$
  SELECT auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- =============================================
-- 3. TABELAS PRINCIPAIS DO DRIVESYNC (SINGLE-TENANT)
-- =============================================

-- Tabela de usuários do sistema
CREATE TABLE usuarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
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
  placa text NOT NULL,
  modelo text NOT NULL,
  tipo text NOT NULL,
  quilometragem_atual integer DEFAULT 0,
  identificacao_interna text,
  status text DEFAULT 'disponivel' CHECK (status IN ('disponivel', 'em_manutencao')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de relacionamento motoristas-veículos (N:N)
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

-- Tabela de trajetos customizados dos planos
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
-- 4. CONFIGURAÇÕES DO SISTEMA (SINGLE-TENANT)
-- =============================================

-- Tabela de configurações gerais do sistema
CREATE TABLE configuracoes_sistema (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_organizacao text DEFAULT 'DriveSync',
  cidade text,
  uf text,
  logo_url text,
  cor_primaria text DEFAULT '#1E40AF',
  cor_secundaria text DEFAULT '#059669',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- =============================================
-- 5. TRIGGERS PARA UPDATED_AT
-- =============================================

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

CREATE TRIGGER update_configuracoes_sistema_updated_at
  BEFORE UPDATE ON configuracoes_sistema
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 6. ROW LEVEL SECURITY (SIMPLIFICADO)
-- =============================================

-- Habilitar RLS em todas as tabelas
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
ALTER TABLE configuracoes_sistema ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 7. POLÍTICAS RLS SIMPLIFICADAS
-- =============================================

-- Políticas para usuários (apenas usuários autenticados)
CREATE POLICY "Usuários autenticados podem ver todos os dados" ON usuarios
  FOR ALL TO authenticated USING (true);

-- Políticas para motoristas
CREATE POLICY "Usuários autenticados podem ver motoristas" ON motoristas
  FOR ALL TO authenticated USING (true);

-- Políticas para veículos
CREATE POLICY "Usuários autenticados podem ver veículos" ON veiculos
  FOR ALL TO authenticated USING (true);

-- Políticas para associação motoristas-veículos
CREATE POLICY "Usuários autenticados podem ver associações" ON motoristas_veiculos
  FOR ALL TO authenticated USING (true);

-- Políticas para viagens
CREATE POLICY "Usuários autenticados podem ver viagens" ON viagens
  FOR ALL TO authenticated USING (true);

-- Políticas para passageiros
CREATE POLICY "Usuários autenticados podem ver passageiros" ON passageiros
  FOR ALL TO authenticated USING (true);

-- Políticas para abastecimentos
CREATE POLICY "Usuários autenticados podem ver abastecimentos" ON abastecimentos
  FOR ALL TO authenticated USING (true);

-- Políticas para planos de viagem
CREATE POLICY "Usuários autenticados podem ver planos" ON planos_viagem
  FOR ALL TO authenticated USING (true);

-- Políticas para planos-viagens
CREATE POLICY "Usuários autenticados podem ver planos-viagens" ON planos_viagem_viagens
  FOR ALL TO authenticated USING (true);

-- Políticas para trajetos customizados
CREATE POLICY "Usuários autenticados podem ver trajetos" ON planos_viagem_custom_trajetos
  FOR ALL TO authenticated USING (true);

-- Políticas para alterações
CREATE POLICY "Usuários autenticados podem ver alterações" ON planos_viagem_alteracoes
  FOR ALL TO authenticated USING (true);

-- Políticas para lembretes de manutenção
CREATE POLICY "Usuários autenticados podem ver lembretes" ON lembretes_manutencao
  FOR ALL TO authenticated USING (true);

-- Políticas para configurações do sistema
CREATE POLICY "Usuários autenticados podem ver configurações" ON configuracoes_sistema
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Apenas admins podem alterar configurações" ON configuracoes_sistema
  FOR ALL TO authenticated USING (
    EXISTS (
      SELECT 1 FROM usuarios 
      WHERE id::text = auth.uid()::text 
      AND role = 'admin'
    )
  );

-- =============================================
-- 8. ÍNDICES PARA PERFORMANCE
-- =============================================

-- Índices para status e datas
CREATE INDEX idx_motoristas_status ON motoristas(status);
CREATE INDEX idx_veiculos_status ON veiculos(status);
CREATE INDEX idx_viagens_status ON viagens(status);
CREATE INDEX idx_viagens_data_viagem ON viagens(data_viagem);
CREATE INDEX idx_lembretes_manutencao_status ON lembretes_manutencao(status);
CREATE INDEX idx_lembretes_manutencao_data_prevista ON lembretes_manutencao(data_prevista);

-- Índices para relacionamentos
CREATE INDEX idx_motoristas_veiculos_motorista_id ON motoristas_veiculos(motorista_id);
CREATE INDEX idx_motoristas_veiculos_veiculo_id ON motoristas_veiculos(veiculo_id);
CREATE INDEX idx_passageiros_viagem_id ON passageiros(viagem_id);

-- =============================================
-- 9. INSERÇÃO DE DADOS DE TESTE
-- =============================================

-- Inserir configurações do sistema
INSERT INTO configuracoes_sistema (nome_organizacao, cidade, uf, cor_primaria, cor_secundaria) VALUES 
('Prefeitura Municipal de Manoel Viana', 'Manoel Viana', 'RS', '#2563EB', '#059669');

-- Inserir usuários de teste
INSERT INTO usuarios (id, email, nome, role, telefone) VALUES 
('550e8400-e29b-41d4-a716-446655440001', 'admin@manoelviana.rs.gov.br', 'Administrador do Sistema', 'admin', '(55) 3256-1000'),
('550e8400-e29b-41d4-a716-446655440002', 'operador@manoelviana.rs.gov.br', 'João Silva - Operador', 'operador', '(55) 3256-1001'),
('550e8400-e29b-41d4-a716-446655440003', 'motorista@manoelviana.rs.gov.br', 'Carlos Oliveira - Motorista', 'motorista', '(55) 99999-1234');

-- Inserir motoristas
INSERT INTO motoristas (id, nome, telefone, cnh, validade_cnh, status) VALUES 
('550e8400-e29b-41d4-a716-446655440010', 'Carlos Oliveira', '(55) 99999-1234', '12345678901', '2025-12-31', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440011', 'Ana Pereira', '(55) 99999-5678', '98765432109', '2025-08-15', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440012', 'Ricardo Alves', '(55) 99999-9999', '55555555555', '2025-06-30', 'indisponivel'),
('550e8400-e29b-41d4-a716-446655440013', 'Maria Santos', '(55) 99999-7777', '11111111111', '2026-03-15', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440014', 'José Costa', '(55) 99999-8888', '22222222222', '2025-09-20', 'disponivel');

-- Inserir veículos
INSERT INTO veiculos (id, placa, modelo, tipo, quilometragem_atual, identificacao_interna, status) VALUES 
('550e8400-e29b-41d4-a716-446655440020', 'ABC-1234', 'Fiat Ducato', 'Van', 45000, 'VAN-001', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440021', 'DEF-5678', 'Mercedes Sprinter', 'Ambulância', 32000, 'AMB-001', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440022', 'GHI-9012', 'Ford Transit', 'Van', 28000, 'VAN-002', 'em_manutencao'),
('550e8400-e29b-41d4-a716-446655440023', 'JKL-3456', 'Volkswagen Amarok', 'Caminhonete', 55000, 'CAM-001', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440024', 'MNO-7890', 'Renault Master', 'Van', 38000, 'VAN-003', 'disponivel');

-- Inserir associações motoristas-veículos
INSERT INTO motoristas_veiculos (motorista_id, veiculo_id, ativo) VALUES 
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440020', true),
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440021', true),
('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440021', true),
('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440024', true),
('550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440023', true),
('550e8400-e29b-41d4-a716-446655440014', '550e8400-e29b-41d4-a716-446655440020', true);

-- Inserir viagens
INSERT INTO viagens (id, motorista_id, veiculo_id, agendador_id, data_viagem, data_saida, km_saida, data_chegada, km_chegada, observacoes, status) VALUES 
('550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440002', '2025-01-08 08:00:00', '2025-01-08 08:15:00', 45000, '2025-01-08 12:30:00', 45085, 'Transporte para Hospital Regional de Alegrete', 'concluida'),
('550e8400-e29b-41d4-a716-446655440031', '550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440002', '2025-01-08 14:00:00', '2025-01-08 14:10:00', 32000, NULL, NULL, 'Emergência médica - Centro da cidade', 'em_andamento'),
('550e8400-e29b-41d4-a716-446655440032', '550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440002', '2025-01-09 09:00:00', NULL, NULL, NULL, NULL, 'Transporte de equipamentos para UBS', 'agendada');

-- Inserir passageiros
INSERT INTO passageiros (viagem_id, nome, documento) VALUES 
('550e8400-e29b-41d4-a716-446655440030', 'Maria da Silva', '123.456.789-00'),
('550e8400-e29b-41d4-a716-446655440030', 'João Santos', '987.654.321-00'),
('550e8400-e29b-41d4-a716-446655440030', 'Ana Costa', '456.789.123-00'),
('550e8400-e29b-41d4-a716-446655440031', 'Pedro Oliveira', '789.123.456-00'),
('550e8400-e29b-41d4-a716-446655440032', 'Carla Pereira', '321.654.987-00');

-- Inserir abastecimentos
INSERT INTO abastecimentos (id, viagem_id, motorista_id, veiculo_id, data_abastecimento, local, tipo_combustivel, litros, valor_total, quilometragem) VALUES 
('550e8400-e29b-41d4-a716-446655440040', '550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440020', '2025-01-08 07:45:00', 'Posto Ipiranga - Centro', 'Diesel S10', 45.5, 320.50, 44995),
('550e8400-e29b-41d4-a716-446655440041', NULL, '550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440021', '2025-01-07 16:30:00', 'Posto BR - RS-377', 'Diesel S10', 38.2, 268.40, 31980);

-- Inserir planos de viagem
INSERT INTO planos_viagem (id, motorista_id, titulo, descricao, status, enviado_para, criado_do_zero) VALUES 
('550e8400-e29b-41d4-a716-446655440050', '550e8400-e29b-41d4-a716-446655440010', 'Plano Semanal - Cobertura Regional', 'Cobertura dos serviços de saúde da região durante a semana', 'aprovado', 'Secretaria Municipal de Saúde', false),
('550e8400-e29b-41d4-a716-446655440051', '550e8400-e29b-41d4-a716-446655440011', 'Plantão Emergencial - Final de Semana', 'Plantão de emergências para final de semana', 'pendente', 'Coordenação de Saúde', true);

-- Inserir lembretes de manutenção
INSERT INTO lembretes_manutencao (id, veiculo_id, tipo, data_prevista, km_previsto, descricao, status) VALUES 
('550e8400-e29b-41d4-a716-446655440060', '550e8400-e29b-41d4-a716-446655440020', 'Troca de óleo', '2025-01-15', 50000, 'Troca de óleo e filtros', 'aberto'),
('550e8400-e29b-41d4-a716-446655440061', '550e8400-e29b-41d4-a716-446655440021', 'Revisão geral', '2025-01-20', 35000, 'Revisão completa da ambulância', 'aberto'),
('550e8400-e29b-41d4-a716-446655440062', '550e8400-e29b-41d4-a716-446655440023', 'Troca de pneus', '2025-01-10', NULL, 'Substituição dos pneus dianteiros', 'aberto');

-- =============================================
-- 10. VERIFICAÇÃO FINAL
-- =============================================

-- Verificar se tudo foi criado corretamente
SELECT 'Banco de dados DriveSync (Single-Tenant) criado com sucesso!' as status;

-- Mostrar estatísticas
SELECT 
  'Usuários: ' || (SELECT count(*) FROM usuarios) ||
  ', Motoristas: ' || (SELECT count(*) FROM motoristas) ||
  ', Veículos: ' || (SELECT count(*) FROM veiculos) ||
  ', Viagens: ' || (SELECT count(*) FROM viagens) as estatisticas;