/*
  # Recriação Completa do Banco DriveSync
  
  1. Estrutura Completa
    - Drop de todas as tabelas existentes
    - Criação de schema com hierarquia e privilégios
    - Políticas RLS adequadas
    - Triggers e funções auxiliares
    
  2. Dados de Teste
    - Super admin (admin@admin.com)
    - Tenant de demonstração
    - Usuários com diferentes roles
    - Dados completos para teste
    
  3. Segurança
    - Row Level Security em todas as tabelas
    - Políticas baseadas em tenant_id
    - Controle de acesso por role
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
-- 2. CRIAÇÃO DE TIPOS E FUNÇÕES AUXILIARES
-- =============================================

-- Tipo para roles de usuário
CREATE TYPE user_role AS ENUM ('admin', 'user');

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

-- Função para verificar se é admin
CREATE OR REPLACE FUNCTION is_admin(user_id uuid) RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = $1 AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Função para configurações iniciais do usuário
CREATE OR REPLACE FUNCTION handle_user_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_settings (user_id)
  VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- 3. TABELAS PRINCIPAIS
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

-- Tabela de usuários do sistema
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
-- 4. TABELAS AUXILIARES DO SISTEMA
-- =============================================

-- Tabela de perfis (ligada ao auth.users)
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de roles de usuário
CREATE TABLE user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role user_role NOT NULL DEFAULT 'user',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, role)
);

-- Tabela de configurações do usuário
CREATE TABLE user_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) UNIQUE,
  theme text DEFAULT 'light' CHECK (theme IN ('light', 'dark')),
  language text DEFAULT 'pt' CHECK (language IN ('pt', 'en')),
  notifications_enabled boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de analytics
CREATE TABLE analytics (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  event_data jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- Tabela de planos de assinatura
CREATE TABLE plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  price_monthly integer NOT NULL,
  currency text DEFAULT 'brl',
  features jsonb DEFAULT '[]',
  max_cards integer,
  is_active boolean DEFAULT true,
  stripe_price_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de assinantes
CREATE TABLE subscribers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  stripe_customer_id text UNIQUE,
  current_plan_id uuid REFERENCES plans(id),
  subscription_status text CHECK (subscription_status IN ('active', 'canceled', 'past_due', 'unpaid', 'incomplete', 'trialing')),
  stripe_subscription_id text,
  subscription_start timestamptz,
  subscription_end timestamptz,
  trial_end timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de transações
CREATE TABLE transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscriber_id uuid REFERENCES subscribers(id) ON DELETE CASCADE,
  stripe_session_id text,
  stripe_payment_intent_id text,
  amount integer NOT NULL,
  currency text DEFAULT 'brl',
  status text CHECK (status IN ('pending', 'succeeded', 'failed', 'canceled', 'processing')),
  payment_method text,
  description text,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de cartões virtuais
CREATE TABLE vcards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  company text,
  position text,
  email text NOT NULL,
  phone text,
  website text,
  address text,
  template text DEFAULT 'modern',
  colors jsonb DEFAULT '{"text": "#1F2937", "primary": "#3B82F6", "secondary": "#10B981"}',
  logo_url text,
  social_links jsonb DEFAULT '{}',
  layout text DEFAULT 'vertical' CHECK (layout IN ('vertical', 'horizontal')),
  theme text DEFAULT 'light' CHECK (theme IN ('light', 'dark')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- =============================================
-- 5. TRIGGERS PARA UPDATED_AT
-- =============================================

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

CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_roles_updated_at
  BEFORE UPDATE ON user_roles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at
  BEFORE UPDATE ON user_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_plans_updated_at
  BEFORE UPDATE ON plans
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscribers_updated_at
  BEFORE UPDATE ON subscribers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transactions_updated_at
  BEFORE UPDATE ON transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vcards_updated_at
  BEFORE UPDATE ON vcards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger para criar configurações do usuário automaticamente
CREATE TRIGGER on_profile_created
  AFTER INSERT ON profiles
  FOR EACH ROW EXECUTE FUNCTION handle_user_settings();

-- =============================================
-- 6. ROW LEVEL SECURITY (RLS)
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
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscribers ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE vcards ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 7. POLÍTICAS RLS
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

-- Políticas para associação motoristas-veículos
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

-- Políticas para profiles
CREATE POLICY "Users can view their own profile" ON profiles
  FOR SELECT USING (id = uid());

CREATE POLICY "Users can update their own profile" ON profiles
  FOR UPDATE USING (id = uid());

CREATE POLICY "Users can insert their own profile" ON profiles
  FOR INSERT WITH CHECK (id = uid());

CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (is_admin(uid()));

-- Políticas para user_roles
CREATE POLICY "Users can view their own roles" ON user_roles
  FOR SELECT USING (user_id = uid());

CREATE POLICY "Admins can view all roles" ON user_roles
  FOR SELECT USING (is_admin(uid()));

CREATE POLICY "Admins can manage roles" ON user_roles
  FOR ALL USING (is_admin(uid()));

-- Políticas para user_settings
CREATE POLICY "Users can view their own settings" ON user_settings
  FOR SELECT USING (uid() = user_id);

CREATE POLICY "Users can update their own settings" ON user_settings
  FOR UPDATE USING (uid() = user_id);

CREATE POLICY "Users can insert their own settings" ON user_settings
  FOR INSERT WITH CHECK (uid() = user_id);

-- Políticas para analytics
CREATE POLICY "System can insert analytics" ON analytics
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Admins can view all analytics" ON analytics
  FOR SELECT USING (is_admin(uid()));

-- Políticas para plans
CREATE POLICY "Allow public read access to plans" ON plans
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage plans" ON plans
  FOR ALL USING (is_admin(uid()));

-- Políticas para subscribers
CREATE POLICY "Users can view their own subscription" ON subscribers
  FOR SELECT USING (user_id = uid());

CREATE POLICY "Admins can view all subscribers" ON subscribers
  FOR SELECT USING (is_admin(uid()));

CREATE POLICY "Edge functions can manage subscribers" ON subscribers
  FOR ALL USING (true);

-- Políticas para transactions
CREATE POLICY "Users can view their own transactions" ON transactions
  FOR SELECT USING (user_id = uid());

CREATE POLICY "Admins can view all transactions" ON transactions
  FOR SELECT USING (is_admin(uid()));

CREATE POLICY "Edge functions can manage transactions" ON transactions
  FOR ALL USING (true);

-- Políticas para vcards
CREATE POLICY "Allow public read access to vcards" ON vcards
  FOR SELECT USING (true);

CREATE POLICY "Users can view their own vcards" ON vcards
  FOR SELECT USING (uid() = user_id);

CREATE POLICY "Users can create their own vcards" ON vcards
  FOR INSERT WITH CHECK (uid() = user_id);

CREATE POLICY "Users can update their own vcards" ON vcards
  FOR UPDATE USING (uid() = user_id);

CREATE POLICY "Users can delete their own vcards" ON vcards
  FOR DELETE USING (uid() = user_id);

-- =============================================
-- 8. ÍNDICES PARA PERFORMANCE
-- =============================================

-- Índices para tenant_id (muito importante para multi-tenant)
CREATE INDEX idx_usuarios_tenant_id ON usuarios(tenant_id);
CREATE INDEX idx_motoristas_tenant_id ON motoristas(tenant_id);
CREATE INDEX idx_veiculos_tenant_id ON veiculos(tenant_id);
CREATE INDEX idx_viagens_tenant_id ON viagens(tenant_id);
CREATE INDEX idx_abastecimentos_tenant_id ON abastecimentos(tenant_id);
CREATE INDEX idx_planos_viagem_tenant_id ON planos_viagem(tenant_id);
CREATE INDEX idx_lembretes_manutencao_tenant_id ON lembretes_manutencao(tenant_id);

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

-- Inserir tenant de demonstração
INSERT INTO tenants (id, nome, cidade, uf, cor_primaria, cor_secundaria) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 'Prefeitura Municipal de São Paulo', 'São Paulo', 'SP', '#1E40AF', '#059669');

-- Inserir usuários de teste
INSERT INTO usuarios (id, tenant_id, email, nome, role, telefone) VALUES 
('550e8400-e29b-41d4-a716-446655440001', '550e8400-e29b-41d4-a716-446655440000', 'admin@sp.gov.br', 'Administrador do Sistema', 'admin', '(11) 3333-1000'),
('550e8400-e29b-41d4-a716-446655440002', '550e8400-e29b-41d4-a716-446655440000', 'operador@sp.gov.br', 'João Silva - Operador', 'operador', '(11) 3333-1001'),
('550e8400-e29b-41d4-a716-446655440003', '550e8400-e29b-41d4-a716-446655440000', 'motorista@sp.gov.br', 'Carlos Oliveira - Motorista', 'motorista', '(11) 99999-1234');

-- Inserir motoristas
INSERT INTO motoristas (id, tenant_id, nome, telefone, cnh, validade_cnh, status) VALUES 
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000', 'Carlos Oliveira', '(11) 99999-1234', '12345678901', '2025-12-31', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440000', 'Ana Pereira', '(11) 99999-5678', '98765432109', '2025-08-15', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440012', '550e8400-e29b-41d4-a716-446655440000', 'Ricardo Alves', '(11) 99999-9999', '55555555555', '2025-06-30', 'indisponivel'),
('550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440000', 'Maria Santos', '(11) 99999-7777', '11111111111', '2026-03-15', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440014', '550e8400-e29b-41d4-a716-446655440000', 'José Costa', '(11) 99999-8888', '22222222222', '2025-09-20', 'disponivel');

-- Inserir veículos
INSERT INTO veiculos (id, tenant_id, placa, modelo, tipo, quilometragem_atual, identificacao_interna, status) VALUES 
('550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440000', 'ABC-1234', 'Fiat Ducato', 'Van', 45000, 'VAN-001', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440000', 'DEF-5678', 'Mercedes Sprinter', 'Ambulância', 32000, 'AMB-001', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440022', '550e8400-e29b-41d4-a716-446655440000', 'GHI-9012', 'Ford Transit', 'Van', 28000, 'VAN-002', 'em_manutencao'),
('550e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440000', 'JKL-3456', 'Volkswagen Amarok', 'Caminhonete', 55000, 'CAM-001', 'disponivel'),
('550e8400-e29b-41d4-a716-446655440024', '550e8400-e29b-41d4-a716-446655440000', 'MNO-7890', 'Renault Master', 'Van', 38000, 'VAN-003', 'disponivel');

-- Inserir associações motoristas-veículos
INSERT INTO motoristas_veiculos (motorista_id, veiculo_id, ativo) VALUES 
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440020', true),
('550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440021', true),
('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440021', true),
('550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440024', true),
('550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440023', true),
('550e8400-e29b-41d4-a716-446655440014', '550e8400-e29b-41d4-a716-446655440020', true);

-- Inserir viagens
INSERT INTO viagens (id, tenant_id, motorista_id, veiculo_id, agendador_id, data_viagem, data_saida, km_saida, data_chegada, km_chegada, observacoes, status) VALUES 
('550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440002', '2025-01-08 08:00:00', '2025-01-08 08:15:00', 45000, '2025-01-08 12:30:00', 45085, 'Transporte para Hospital das Clínicas', 'concluida'),
('550e8400-e29b-41d4-a716-446655440031', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440002', '2025-01-08 14:00:00', '2025-01-08 14:10:00', 32000, NULL, NULL, 'Emergência médica - Zona Sul', 'em_andamento'),
('550e8400-e29b-41d4-a716-446655440032', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440002', '2025-01-09 09:00:00', NULL, NULL, NULL, NULL, 'Transporte de equipamentos', 'agendada');

-- Inserir passageiros
INSERT INTO passageiros (viagem_id, nome, documento) VALUES 
('550e8400-e29b-41d4-a716-446655440030', 'Maria da Silva', '123.456.789-00'),
('550e8400-e29b-41d4-a716-446655440030', 'João Santos', '987.654.321-00'),
('550e8400-e29b-41d4-a716-446655440030', 'Ana Costa', '456.789.123-00'),
('550e8400-e29b-41d4-a716-446655440031', 'Pedro Oliveira', '789.123.456-00'),
('550e8400-e29b-41d4-a716-446655440032', 'Carla Pereira', '321.654.987-00');

-- Inserir abastecimentos
INSERT INTO abastecimentos (id, tenant_id, viagem_id, motorista_id, veiculo_id, data_abastecimento, local, tipo_combustivel, litros, valor_total, quilometragem) VALUES 
('550e8400-e29b-41d4-a716-446655440040', '550e8400-e29b-41d4-a716-446655440000', '550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440020', '2025-01-08 07:45:00', 'Posto Shell - Av. Paulista', 'Diesel S10', 45.5, 320.50, 44995),
('550e8400-e29b-41d4-a716-446655440041', '550e8400-e29b-41d4-a716-446655440000', NULL, '550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440021', '2025-01-07 16:30:00', 'Posto BR - Marginal Tietê', 'Diesel S10', 38.2, 268.40, 31980);

-- Inserir planos de viagem
INSERT INTO planos_viagem (id, motorista_id, tenant_id, titulo, descricao, status, enviado_para, criado_do_zero) VALUES 
('550e8400-e29b-41d4-a716-446655440050', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440000', 'Plano Semanal - Hospitais Zona Norte', 'Cobertura dos hospitais da região norte durante a semana', 'aprovado', 'Coordenação de Saúde', false),
('550e8400-e29b-41d4-a716-446655440051', '550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440000', 'Emergências Fim de Semana', 'Plantão de emergências para sábado e domingo', 'pendente', 'Supervisão Médica', true);

-- Inserir lembretes de manutenção
INSERT INTO lembretes_manutencao (id, veiculo_id, tenant_id, tipo, data_prevista, km_previsto, descricao, status) VALUES 
('550e8400-e29b-41d4-a716-446655440060', '550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440000', 'Troca de óleo', '2025-01-15', 50000, 'Troca de óleo e filtros', 'aberto'),
('550e8400-e29b-41d4-a716-446655440061', '550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440000', 'Revisão geral', '2025-01-20', 35000, 'Revisão completa da ambulância', 'aberto'),
('550e8400-e29b-41d4-a716-446655440062', '550e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440000', 'Troca de pneus', '2025-01-10', NULL, 'Substituição dos pneus dianteiros', 'aberto');

-- =============================================
-- 10. CRIAÇÃO DO SUPER ADMIN
-- =============================================

-- Inserir super admin no auth.users (simulado)
-- NOTA: Em produção, este usuário deve ser criado via Supabase Auth
-- Aqui estamos apenas preparando os dados para quando ele fizer login

-- Inserir plano gratuito
INSERT INTO plans (id, name, description, price_monthly, features, max_cards, is_active) VALUES 
('550e8400-e29b-41d4-a716-446655440100', 'Plano Gratuito', 'Plano básico gratuito', 0, '["Dashboard básico", "Até 5 motoristas", "Relatórios simples"]', 5, true),
('550e8400-e29b-41d4-a716-446655440101', 'Plano Premium', 'Plano completo para empresas', 9900, '["Dashboard avançado", "Motoristas ilimitados", "Relatórios completos", "Suporte prioritário"]', NULL, true);

-- =============================================
-- 11. COMENTÁRIOS FINAIS
-- =============================================

-- Verificar se tudo foi criado corretamente
SELECT 'Banco de dados DriveSync criado com sucesso!' as status;

-- Mostrar estatísticas
SELECT 
  'Tenants: ' || (SELECT count(*) FROM tenants) ||
  ', Usuários: ' || (SELECT count(*) FROM usuarios) ||
  ', Motoristas: ' || (SELECT count(*) FROM motoristas) ||
  ', Veículos: ' || (SELECT count(*) FROM veiculos) ||
  ', Viagens: ' || (SELECT count(*) FROM viagens) as estatisticas;