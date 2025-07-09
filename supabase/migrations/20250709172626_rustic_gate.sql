/*
  # DriveSync - Sistema de Gestão de Frotas
  
  Migração inicial com estrutura completa do banco de dados.
  
  ## Tabelas Principais
  
  1. **system_config** - Configurações do sistema
  2. **users** - Usuários do sistema
  3. **drivers** - Motoristas
  4. **vehicles** - Veículos da frota
  5. **trips** - Viagens agendadas/realizadas
  6. **passengers** - Passageiros das viagens
  7. **fuel_records** - Registros de abastecimento
  8. **maintenance_reminders** - Lembretes de manutenção
  
  ## Segurança
  
  - Row Level Security (RLS) habilitado em todas as tabelas
  - Políticas de acesso baseadas em autenticação
  - Triggers para updated_at automático
*/

-- =============================================
-- 1. EXTENSÕES E FUNÇÕES AUXILIARES
-- =============================================

-- Função para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 2. TABELAS PRINCIPAIS
-- =============================================

-- Configurações do sistema
CREATE TABLE system_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_name text NOT NULL DEFAULT 'DriveSync',
  city text,
  state text,
  logo_url text,
  primary_color text DEFAULT '#2563EB',
  secondary_color text DEFAULT '#059669',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Usuários do sistema
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  name text NOT NULL,
  role text DEFAULT 'operator' CHECK (role IN ('admin', 'operator', 'driver')),
  avatar_url text,
  phone text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Motoristas
CREATE TABLE drivers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  phone text,
  license_number text,
  license_expiry date,
  status text DEFAULT 'available' CHECK (status IN ('available', 'unavailable')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Veículos
CREATE TABLE vehicles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  license_plate text NOT NULL,
  model text NOT NULL,
  type text NOT NULL,
  current_mileage integer DEFAULT 0,
  internal_id text,
  status text DEFAULT 'available' CHECK (status IN ('available', 'maintenance')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Viagens
CREATE TABLE trips (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid REFERENCES drivers(id),
  vehicle_id uuid REFERENCES vehicles(id),
  scheduler_id uuid REFERENCES users(id),
  trip_date timestamptz NOT NULL,
  departure_time timestamptz,
  departure_mileage integer,
  arrival_time timestamptz,
  arrival_mileage integer,
  notes text,
  status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Passageiros
CREATE TABLE passengers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id uuid REFERENCES trips(id) ON DELETE CASCADE,
  name text NOT NULL,
  document text,
  created_at timestamptz DEFAULT now()
);

-- Registros de abastecimento
CREATE TABLE fuel_records (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id uuid REFERENCES trips(id),
  driver_id uuid REFERENCES drivers(id),
  vehicle_id uuid REFERENCES vehicles(id),
  fuel_date timestamptz NOT NULL,
  location text NOT NULL,
  fuel_type text NOT NULL,
  liters numeric NOT NULL,
  total_amount numeric NOT NULL,
  mileage integer,
  receipt_url text,
  created_at timestamptz DEFAULT now()
);

-- Lembretes de manutenção
CREATE TABLE maintenance_reminders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_id uuid REFERENCES vehicles(id) ON DELETE CASCADE,
  type text NOT NULL,
  due_date date,
  due_mileage integer,
  description text,
  status text DEFAULT 'open' CHECK (status IN ('open', 'completed', 'cancelled')),
  completion_date date,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- =============================================
-- 3. TRIGGERS PARA UPDATED_AT
-- =============================================

CREATE TRIGGER update_system_config_updated_at
  BEFORE UPDATE ON system_config
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_drivers_updated_at
  BEFORE UPDATE ON drivers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vehicles_updated_at
  BEFORE UPDATE ON vehicles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_trips_updated_at
  BEFORE UPDATE ON trips
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_maintenance_reminders_updated_at
  BEFORE UPDATE ON maintenance_reminders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- 4. ROW LEVEL SECURITY (RLS)
-- =============================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE system_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE fuel_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_reminders ENABLE ROW LEVEL SECURITY;

-- =============================================
-- 5. POLÍTICAS RLS
-- =============================================

-- Configurações do sistema (leitura para todos, escrita apenas para admins)
CREATE POLICY "Anyone can read system config" ON system_config
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Only admins can modify system config" ON system_config
  FOR ALL TO authenticated USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id::text = auth.uid()::text 
      AND role = 'admin'
    )
  );

-- Usuários (todos podem ver, apenas admins podem modificar)
CREATE POLICY "Authenticated users can read users" ON users
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Only admins can modify users" ON users
  FOR ALL TO authenticated USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id::text = auth.uid()::text 
      AND role = 'admin'
    )
  );

-- Motoristas (todos autenticados podem ver e modificar)
CREATE POLICY "Authenticated users can access drivers" ON drivers
  FOR ALL TO authenticated USING (true);

-- Veículos (todos autenticados podem ver e modificar)
CREATE POLICY "Authenticated users can access vehicles" ON vehicles
  FOR ALL TO authenticated USING (true);

-- Viagens (todos autenticados podem ver e modificar)
CREATE POLICY "Authenticated users can access trips" ON trips
  FOR ALL TO authenticated USING (true);

-- Passageiros (todos autenticados podem ver e modificar)
CREATE POLICY "Authenticated users can access passengers" ON passengers
  FOR ALL TO authenticated USING (true);

-- Registros de abastecimento (todos autenticados podem ver e modificar)
CREATE POLICY "Authenticated users can access fuel records" ON fuel_records
  FOR ALL TO authenticated USING (true);

-- Lembretes de manutenção (todos autenticados podem ver e modificar)
CREATE POLICY "Authenticated users can access maintenance reminders" ON maintenance_reminders
  FOR ALL TO authenticated USING (true);

-- =============================================
-- 6. ÍNDICES PARA PERFORMANCE
-- =============================================

-- Índices para status e datas
CREATE INDEX idx_drivers_status ON drivers(status);
CREATE INDEX idx_vehicles_status ON vehicles(status);
CREATE INDEX idx_trips_status ON trips(status);
CREATE INDEX idx_trips_date ON trips(trip_date);
CREATE INDEX idx_maintenance_status ON maintenance_reminders(status);
CREATE INDEX idx_maintenance_due_date ON maintenance_reminders(due_date);

-- Índices para relacionamentos
CREATE INDEX idx_trips_driver_id ON trips(driver_id);
CREATE INDEX idx_trips_vehicle_id ON trips(vehicle_id);
CREATE INDEX idx_passengers_trip_id ON passengers(trip_id);
CREATE INDEX idx_fuel_records_trip_id ON fuel_records(trip_id);
CREATE INDEX idx_fuel_records_vehicle_id ON fuel_records(vehicle_id);
CREATE INDEX idx_maintenance_vehicle_id ON maintenance_reminders(vehicle_id);

-- =============================================
-- 7. DADOS INICIAIS
-- =============================================

-- Configuração inicial do sistema
INSERT INTO system_config (organization_name, city, state, primary_color, secondary_color) VALUES 
('Prefeitura Municipal de Manoel Viana', 'Manoel Viana', 'RS', '#2563EB', '#059669');

-- Usuários de teste
INSERT INTO users (id, email, name, role, phone) VALUES 
('550e8400-e29b-41d4-a716-446655440001', 'admin@manoelviana.rs.gov.br', 'Administrador do Sistema', 'admin', '(55) 3256-1000'),
('550e8400-e29b-41d4-a716-446655440002', 'operador@manoelviana.rs.gov.br', 'João Silva - Operador', 'operator', '(55) 3256-1001'),
('550e8400-e29b-41d4-a716-446655440003', 'motorista@manoelviana.rs.gov.br', 'Carlos Oliveira - Motorista', 'driver', '(55) 99999-1234');

-- Motoristas
INSERT INTO drivers (id, name, phone, license_number, license_expiry, status) VALUES 
('550e8400-e29b-41d4-a716-446655440010', 'Carlos Oliveira', '(55) 99999-1234', '12345678901', '2025-12-31', 'available'),
('550e8400-e29b-41d4-a716-446655440011', 'Ana Pereira', '(55) 99999-5678', '98765432109', '2025-08-15', 'available'),
('550e8400-e29b-41d4-a716-446655440012', 'Ricardo Alves', '(55) 99999-9999', '55555555555', '2025-06-30', 'unavailable'),
('550e8400-e29b-41d4-a716-446655440013', 'Maria Santos', '(55) 99999-7777', '11111111111', '2026-03-15', 'available'),
('550e8400-e29b-41d4-a716-446655440014', 'José Costa', '(55) 99999-8888', '22222222222', '2025-09-20', 'available');

-- Veículos
INSERT INTO vehicles (id, license_plate, model, type, current_mileage, internal_id, status) VALUES 
('550e8400-e29b-41d4-a716-446655440020', 'ABC-1234', 'Fiat Ducato', 'Van', 45000, 'VAN-001', 'available'),
('550e8400-e29b-41d4-a716-446655440021', 'DEF-5678', 'Mercedes Sprinter', 'Ambulância', 32000, 'AMB-001', 'available'),
('550e8400-e29b-41d4-a716-446655440022', 'GHI-9012', 'Ford Transit', 'Van', 28000, 'VAN-002', 'maintenance'),
('550e8400-e29b-41d4-a716-446655440023', 'JKL-3456', 'Volkswagen Amarok', 'Caminhonete', 55000, 'CAM-001', 'available'),
('550e8400-e29b-41d4-a716-446655440024', 'MNO-7890', 'Renault Master', 'Van', 38000, 'VAN-003', 'available');

-- Viagens
INSERT INTO trips (id, driver_id, vehicle_id, scheduler_id, trip_date, departure_time, departure_mileage, arrival_time, arrival_mileage, notes, status) VALUES 
('550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440020', '550e8400-e29b-41d4-a716-446655440002', '2025-01-08 08:00:00', '2025-01-08 08:15:00', 45000, '2025-01-08 12:30:00', 45085, 'Transporte para Hospital Regional de Alegrete', 'completed'),
('550e8400-e29b-41d4-a716-446655440031', '550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440021', '550e8400-e29b-41d4-a716-446655440002', '2025-01-08 14:00:00', '2025-01-08 14:10:00', 32000, NULL, NULL, 'Emergência médica - Centro da cidade', 'in_progress'),
('550e8400-e29b-41d4-a716-446655440032', '550e8400-e29b-41d4-a716-446655440013', '550e8400-e29b-41d4-a716-446655440023', '550e8400-e29b-41d4-a716-446655440002', '2025-01-09 09:00:00', NULL, NULL, NULL, NULL, 'Transporte de equipamentos para UBS', 'scheduled');

-- Passageiros
INSERT INTO passengers (trip_id, name, document) VALUES 
('550e8400-e29b-41d4-a716-446655440030', 'Maria da Silva', '123.456.789-00'),
('550e8400-e29b-41d4-a716-446655440030', 'João Santos', '987.654.321-00'),
('550e8400-e29b-41d4-a716-446655440030', 'Ana Costa', '456.789.123-00'),
('550e8400-e29b-41d4-a716-446655440031', 'Pedro Oliveira', '789.123.456-00'),
('550e8400-e29b-41d4-a716-446655440032', 'Carla Pereira', '321.654.987-00');

-- Registros de abastecimento
INSERT INTO fuel_records (id, trip_id, driver_id, vehicle_id, fuel_date, location, fuel_type, liters, total_amount, mileage) VALUES 
('550e8400-e29b-41d4-a716-446655440040', '550e8400-e29b-41d4-a716-446655440030', '550e8400-e29b-41d4-a716-446655440010', '550e8400-e29b-41d4-a716-446655440020', '2025-01-08 07:45:00', 'Posto Ipiranga - Centro', 'Diesel S10', 45.5, 320.50, 44995),
('550e8400-e29b-41d4-a716-446655440041', NULL, '550e8400-e29b-41d4-a716-446655440011', '550e8400-e29b-41d4-a716-446655440021', '2025-01-07 16:30:00', 'Posto BR - RS-377', 'Diesel S10', 38.2, 268.40, 31980);

-- Lembretes de manutenção
INSERT INTO maintenance_reminders (id, vehicle_id, type, due_date, due_mileage, description, status) VALUES 
('550e8400-e29b-41d4-a716-446655440060', '550e8400-e29b-41d4-a716-446655440020', 'Troca de óleo', '2025-01-15', 50000, 'Troca de óleo e filtros', 'open'),
('550e8400-e29b-41d4-a716-446655440061', '550e8400-e29b-41d4-a716-446655440021', 'Revisão geral', '2025-01-20', 35000, 'Revisão completa da ambulância', 'open'),
('550e8400-e29b-41d4-a716-446655440062', '550e8400-e29b-41d4-a716-446655440023', 'Troca de pneus', '2025-01-10', NULL, 'Substituição dos pneus dianteiros', 'open');

-- =============================================
-- 8. VERIFICAÇÃO FINAL
-- =============================================

-- Verificar se tudo foi criado corretamente
SELECT 'DriveSync database created successfully!' as status;

-- Mostrar estatísticas
SELECT 
  'Users: ' || (SELECT count(*) FROM users) ||
  ', Drivers: ' || (SELECT count(*) FROM drivers) ||
  ', Vehicles: ' || (SELECT count(*) FROM vehicles) ||
  ', Trips: ' || (SELECT count(*) FROM trips) as statistics;