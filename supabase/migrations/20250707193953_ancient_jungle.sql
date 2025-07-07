/*
  # Esquema inicial do DriveSync

  1. Tabelas principais
    - `tenants` - Clientes (prefeituras, empresas)
    - `usuarios` - Usuários do sistema
    - `motoristas` - Motoristas vinculados aos tenants
    - `veiculos` - Veículos da frota
    - `motoristas_veiculos` - Associação motorista-veículo
    - `viagens` - Viagens agendadas e realizadas
    - `passageiros` - Passageiros das viagens
    - `abastecimentos` - Registro de abastecimentos
    - `planos_viagem` - Planos de viagem
    - `planos_viagem_viagens` - Associação plano-viagem
    - `planos_viagem_custom_trajetos` - Trajetos customizados
    - `planos_viagem_alteracoes` - Histórico de alterações
    - `lembretes_manutencao` - Lembretes de manutenção

  2. Segurança
    - Todas as tabelas têm RLS habilitado
    - Políticas baseadas em tenant_id para isolamento
    - Autenticação via Supabase Auth
*/

-- Tabela de tenants (clientes)
CREATE TABLE IF NOT EXISTS tenants (
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
CREATE TABLE IF NOT EXISTS usuarios (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  nome text NOT NULL,
  role text NOT NULL DEFAULT 'operador' CHECK (role IN ('admin', 'operador', 'motorista')),
  avatar_url text,
  telefone text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tabela de motoristas
CREATE TABLE IF NOT EXISTS motoristas (
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
CREATE TABLE IF NOT EXISTS veiculos (
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

-- Tabela de associação motorista-veículo
CREATE TABLE IF NOT EXISTS motoristas_veiculos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  motorista_id uuid REFERENCES motoristas(id) ON DELETE CASCADE,
  veiculo_id uuid REFERENCES veiculos(id) ON DELETE CASCADE,
  ativo boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);

-- Tabela de viagens
CREATE TABLE IF NOT EXISTS viagens (
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
CREATE TABLE IF NOT EXISTS passageiros (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  viagem_id uuid REFERENCES viagens(id) ON DELETE CASCADE,
  nome text NOT NULL,
  documento text,
  created_at timestamptz DEFAULT now()
);

-- Tabela de abastecimentos
CREATE TABLE IF NOT EXISTS abastecimentos (
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
CREATE TABLE IF NOT EXISTS planos_viagem (
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

-- Tabela de associação plano-viagem
CREATE TABLE IF NOT EXISTS planos_viagem_viagens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plano_id uuid REFERENCES planos_viagem(id) ON DELETE CASCADE,
  viagem_id uuid REFERENCES viagens(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- Tabela de trajetos customizados
CREATE TABLE IF NOT EXISTS planos_viagem_custom_trajetos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plano_id uuid REFERENCES planos_viagem(id) ON DELETE CASCADE,
  data_viagem date NOT NULL,
  destino text NOT NULL,
  km_estimado integer,
  observacoes text,
  created_at timestamptz DEFAULT now()
);

-- Tabela de alterações nos planos
CREATE TABLE IF NOT EXISTS planos_viagem_alteracoes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plano_id uuid REFERENCES planos_viagem(id) ON DELETE CASCADE,
  motorista_id uuid REFERENCES motoristas(id),
  data_alteracao timestamptz DEFAULT now(),
  justificativa text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Tabela de lembretes de manutenção
CREATE TABLE IF NOT EXISTS lembretes_manutencao (
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

-- Políticas RLS para isolamento por tenant
CREATE POLICY "Tenants podem ver apenas seus dados" ON tenants
  FOR ALL TO authenticated
  USING (id = (auth.jwt() ->> 'tenant_id')::uuid);

CREATE POLICY "Usuários podem ver dados do seu tenant" ON usuarios
  FOR ALL TO authenticated
  USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

CREATE POLICY "Motoristas podem ver dados do seu tenant" ON motoristas
  FOR ALL TO authenticated
  USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

CREATE POLICY "Veículos podem ver dados do seu tenant" ON veiculos
  FOR ALL TO authenticated
  USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

CREATE POLICY "Associações motorista-veículo por tenant" ON motoristas_veiculos
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM motoristas m 
      WHERE m.id = motorista_id 
      AND m.tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
    )
  );

CREATE POLICY "Viagens podem ver dados do seu tenant" ON viagens
  FOR ALL TO authenticated
  USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

CREATE POLICY "Passageiros por viagem do tenant" ON passageiros
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM viagens v 
      WHERE v.id = viagem_id 
      AND v.tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
    )
  );

CREATE POLICY "Abastecimentos podem ver dados do seu tenant" ON abastecimentos
  FOR ALL TO authenticated
  USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

CREATE POLICY "Planos de viagem podem ver dados do seu tenant" ON planos_viagem
  FOR ALL TO authenticated
  USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

CREATE POLICY "Planos-viagens por tenant" ON planos_viagem_viagens
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM planos_viagem p 
      WHERE p.id = plano_id 
      AND p.tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
    )
  );

CREATE POLICY "Trajetos customizados por tenant" ON planos_viagem_custom_trajetos
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM planos_viagem p 
      WHERE p.id = plano_id 
      AND p.tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
    )
  );

CREATE POLICY "Alterações por tenant" ON planos_viagem_alteracoes
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM planos_viagem p 
      WHERE p.id = plano_id 
      AND p.tenant_id = (auth.jwt() ->> 'tenant_id')::uuid
    )
  );

CREATE POLICY "Lembretes de manutenção por tenant" ON lembretes_manutencao
  FOR ALL TO authenticated
  USING (tenant_id = (auth.jwt() ->> 'tenant_id')::uuid);

-- Inserir dados de exemplo para demonstração
INSERT INTO tenants (nome, cidade, uf, logo_url, cor_primaria, cor_secundaria) VALUES
  ('Prefeitura de São Paulo', 'São Paulo', 'SP', 'https://images.pexels.com/photos/1319854/pexels-photo-1319854.jpeg?auto=compress&cs=tinysrgb&w=100&h=100&dpr=1', '#1E40AF', '#059669'),
  ('Hospital das Clínicas', 'Rio de Janeiro', 'RJ', 'https://images.pexels.com/photos/263402/pexels-photo-263402.jpeg?auto=compress&cs=tinysrgb&w=100&h=100&dpr=1', '#DC2626', '#059669');

-- Inserir usuários de exemplo
INSERT INTO usuarios (tenant_id, email, nome, role) VALUES
  ((SELECT id FROM tenants WHERE nome = 'Prefeitura de São Paulo'), 'admin@sp.gov.br', 'João Silva', 'admin'),
  ((SELECT id FROM tenants WHERE nome = 'Prefeitura de São Paulo'), 'operador@sp.gov.br', 'Maria Santos', 'operador'),
  ((SELECT id FROM tenants WHERE nome = 'Hospital das Clínicas'), 'admin@hc.br', 'Pedro Costa', 'admin');

-- Inserir motoristas de exemplo
INSERT INTO motoristas (tenant_id, nome, telefone, cnh, validade_cnh, status) VALUES
  ((SELECT id FROM tenants WHERE nome = 'Prefeitura de São Paulo'), 'Carlos Oliveira', '(11) 99999-1234', '12345678901', '2025-12-31', 'disponivel'),
  ((SELECT id FROM tenants WHERE nome = 'Prefeitura de São Paulo'), 'Ana Pereira', '(11) 99999-5678', '98765432109', '2025-08-15', 'disponivel'),
  ((SELECT id FROM tenants WHERE nome = 'Hospital das Clínicas'), 'Ricardo Alves', '(21) 99999-9999', '55555555555', '2025-06-30', 'disponivel');

-- Inserir veículos de exemplo
INSERT INTO veiculos (tenant_id, placa, modelo, tipo, quilometragem_atual, identificacao_interna, status) VALUES
  ((SELECT id FROM tenants WHERE nome = 'Prefeitura de São Paulo'), 'ABC-1234', 'Fiat Ducato', 'Van', 45000, 'VAN-001', 'disponivel'),
  ((SELECT id FROM tenants WHERE nome = 'Prefeitura de São Paulo'), 'XYZ-5678', 'Volkswagen Saveiro', 'Utilitário', 32000, 'UT-002', 'disponivel'),
  ((SELECT id FROM tenants WHERE nome = 'Hospital das Clínicas'), 'MED-9999', 'Mercedes Sprinter', 'Ambulância', 78000, 'AMB-001', 'disponivel');