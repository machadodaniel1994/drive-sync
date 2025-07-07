# Wiki do DriveSync - Documentação Técnica

## 📚 Índice

1. [Arquitetura do Sistema](#arquitetura-do-sistema)
2. [Configuração do Ambiente](#configuração-do-ambiente)
3. [Estrutura do Banco de Dados](#estrutura-do-banco-de-dados)
4. [Row Level Security (RLS)](#row-level-security-rls)
5. [Autenticação e Autorização](#autenticação-e-autorização)
6. [API e Endpoints](#api-e-endpoints)
7. [Componentes React](#componentes-react)
8. [Manutenção e Monitoramento](#manutenção-e-monitoramento)
9. [Troubleshooting](#troubleshooting)
10. [Desenvolvimento](#desenvolvimento)

---

## 🏗️ Arquitetura do Sistema

### Visão Geral
O DriveSync é construído com uma arquitetura moderna e escalável:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Supabase      │    │   Hospedagem    │
│   React + TS    │◄──►│   PostgreSQL    │    │   Vercel/       │
│   Tailwind CSS  │    │   Auth + RLS    │    │   Netlify       │
│   Vite          │    │   Edge Functions│    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Tecnologias Principais

| Camada | Tecnologia | Versão | Propósito |
|--------|------------|--------|-----------|
| Frontend | React | 18+ | Interface do usuário |
| Linguagem | TypeScript | 5+ | Tipagem estática |
| Estilização | Tailwind CSS | 3+ | CSS utilitário |
| Build | Vite | 5+ | Bundler moderno |
| Backend | Supabase | Latest | BaaS completo |
| Banco | PostgreSQL | 15+ | Banco relacional |
| Auth | Supabase Auth | Latest | Autenticação |
| Ícones | Lucide React | Latest | Ícones SVG |

### Padrões Arquiteturais

#### 1. Multi-Tenant (SaaS)
- **Isolamento por tenant_id**: Cada cliente possui dados completamente isolados
- **Row Level Security**: Políticas automáticas no banco de dados
- **White Label**: Personalização visual por cliente

#### 2. Component-Based Architecture
```
src/
├── components/          # Componentes reutilizáveis
│   ├── Layout.tsx      # Layout principal
│   ├── Dashboard.tsx   # Dashboard
│   └── ...
├── hooks/              # Custom hooks
│   └── useAuth.ts      # Hook de autenticação
├── lib/                # Utilitários
│   └── supabase.ts     # Cliente Supabase
└── types/              # Definições TypeScript
```

#### 3. Security-First Design
- **RLS em todas as tabelas**: Segurança no nível do banco
- **JWT-based auth**: Tokens seguros
- **Validação client + server**: Dupla validação

---

## ⚙️ Configuração do Ambiente

### Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto:

```env
# Supabase Configuration
VITE_SUPABASE_URL=https://seu-projeto.supabase.co
VITE_SUPABASE_ANON_KEY=sua-chave-anonima

# Opcional: Para desenvolvimento
VITE_APP_ENV=development
VITE_DEBUG=true
```

### Configuração do Supabase

#### 1. Criar Projeto
```bash
# Via dashboard: https://supabase.com/dashboard
# Ou via CLI:
npx supabase init
npx supabase start
```

#### 2. Configurar Autenticação
No dashboard do Supabase:
1. Vá para **Authentication > Settings**
2. Configure **Site URL**: `http://localhost:5173` (dev) ou sua URL de produção
3. Desabilite **Email Confirmations** para desenvolvimento
4. Configure **JWT expiry**: 3600 (1 hora)

#### 3. Executar Migrações
```sql
-- Execute no SQL Editor do Supabase
-- Conteúdo do arquivo: supabase/migrations/001_drop_and_recreate_schema.sql
```

### Configuração do Projeto

#### 1. Instalação
```bash
git clone https://github.com/seu-usuario/drivesync.git
cd drivesync
npm install
```

#### 2. Configuração TypeScript
O projeto já vem configurado com:
- **tsconfig.json**: Configuração principal
- **tsconfig.app.json**: Configuração da aplicação
- **tsconfig.node.json**: Configuração do Node.js

#### 3. Configuração Tailwind
```javascript
// tailwind.config.js
module.exports = {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: 'var(--color-primary)',
        secondary: 'var(--color-secondary)',
      }
    },
  },
  plugins: [],
}
```

---

## 🗄️ Estrutura do Banco de Dados

### Diagrama ER Simplificado

```
tenants (1) ──── (N) usuarios
   │                   │
   │                   │
   └── (N) motoristas  │
   │                   │
   └── (N) veiculos    │
   │                   │
   └── (N) viagens ────┘
           │
           └── (N) passageiros
           └── (N) abastecimentos
```

### Tabelas Principais

#### 1. Tenants (Clientes)
```sql
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
```

**Índices importantes:**
- Primary key em `id`
- Índice em `nome` para busca

#### 2. Usuários
```sql
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
```

**Índices importantes:**
- Primary key em `id`
- Unique em `email`
- Índice em `tenant_id`
- Índice em `role`

#### 3. Motoristas
```sql
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
```

**Índices importantes:**
- Primary key em `id`
- Índice em `tenant_id`
- Índice em `status`
- Índice em `validade_cnh` (para alertas)

### Relacionamentos Importantes

#### 1. Motoristas ↔ Veículos (N:N)
```sql
CREATE TABLE motoristas_veiculos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  motorista_id uuid REFERENCES motoristas(id) ON DELETE CASCADE,
  veiculo_id uuid REFERENCES veiculos(id) ON DELETE CASCADE,
  ativo boolean DEFAULT true,
  created_at timestamptz DEFAULT now()
);
```

#### 2. Viagens → Passageiros (1:N)
```sql
CREATE TABLE passageiros (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  viagem_id uuid REFERENCES viagens(id) ON DELETE CASCADE,
  nome text NOT NULL,
  documento text,
  created_at timestamptz DEFAULT now()
);
```

### Triggers Automáticos

#### 1. Updated At
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicado em todas as tabelas principais
CREATE TRIGGER update_tenants_updated_at
  BEFORE UPDATE ON tenants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## 🔒 Row Level Security (RLS)

### Conceito
O RLS garante que cada tenant veja apenas seus próprios dados, aplicando filtros automáticos em todas as consultas.

### Implementação

#### 1. Habilitação
```sql
-- Habilitar RLS em todas as tabelas
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE motoristas ENABLE ROW LEVEL SECURITY;
-- ... todas as outras tabelas
```

#### 2. Políticas Básicas
```sql
-- Política para tenants
CREATE POLICY "Tenants podem ver apenas seus dados" ON tenants
  FOR ALL USING (id = ((jwt() ->> 'tenant_id')::uuid));

-- Política para usuários
CREATE POLICY "Usuários podem ver dados do seu tenant" ON usuarios
  FOR ALL USING (tenant_id = ((jwt() ->> 'tenant_id')::uuid));
```

#### 3. Políticas Complexas
```sql
-- Política para passageiros (através de viagens)
CREATE POLICY "Passageiros por viagem do tenant" ON passageiros
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM viagens v 
      WHERE v.id = passageiros.viagem_id 
      AND v.tenant_id = ((jwt() ->> 'tenant_id')::uuid)
    )
  );
```

### Funções Auxiliares

#### 1. Obter User ID
```sql
CREATE OR REPLACE FUNCTION uid() RETURNS uuid AS $$
  SELECT auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;
```

#### 2. Verificar Admin
```sql
CREATE OR REPLACE FUNCTION is_admin(user_id uuid) RETURNS boolean AS $$
  SELECT EXISTS (
    SELECT 1 FROM usuarios 
    WHERE id = user_id AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;
```

### Testando RLS

#### 1. Teste Manual
```sql
-- Simular usuário específico
SELECT set_config('request.jwt.claims', '{"tenant_id": "550e8400-e29b-41d4-a716-446655440000"}', true);

-- Testar consulta
SELECT * FROM motoristas; -- Deve retornar apenas motoristas do tenant
```

#### 2. Teste via Aplicação
```typescript
// No frontend, verificar se os dados estão filtrados
const { data: motoristas } = await supabase
  .from('motoristas')
  .select('*');

console.log('Motoristas:', motoristas); // Apenas do tenant atual
```

---

## 🔐 Autenticação e Autorização

### Fluxo de Autenticação

```
1. Usuário faz login → 2. Supabase valida → 3. JWT gerado → 4. RLS aplicado
```

### Implementação no Frontend

#### 1. Hook de Autenticação
```typescript
// src/hooks/useAuth.ts
export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Verificar sessão atual
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setLoading(false);
    });

    // Escutar mudanças
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user ?? null);
        setLoading(false);
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  return { user, loading, signIn, signOut };
}
```

#### 2. Proteção de Rotas
```typescript
// src/App.tsx
function App() {
  const { user, loading } = useAuth();

  if (loading) return <LoadingSpinner />;
  if (!user) return <LoginForm />;
  
  return <Layout>{/* App content */}</Layout>;
}
```

### Roles e Permissões

#### 1. Tipos de Usuário
```typescript
type UserRole = 'admin' | 'operador' | 'motorista';

interface Usuario {
  id: string;
  tenant_id: string;
  email: string;
  nome: string;
  role: UserRole;
}
```

#### 2. Verificação de Permissões
```typescript
// Verificar se é admin
const isAdmin = (user: Usuario) => user.role === 'admin';

// Verificar se pode editar motoristas
const canEditMotoristas = (user: Usuario) => 
  ['admin', 'operador'].includes(user.role);

// Verificar se pode ver apenas próprios dados
const canViewOwnData = (user: Usuario, motorista_id: string) =>
  user.role === 'motorista' ? user.id === motorista_id : true;
```

### JWT Claims Customizados

#### 1. Configuração no Supabase
```sql
-- Função para adicionar claims customizados
CREATE OR REPLACE FUNCTION auth.jwt_claims_custom(user_id uuid)
RETURNS jsonb
LANGUAGE sql
AS $$
  SELECT jsonb_build_object(
    'tenant_id', u.tenant_id,
    'role', u.role,
    'nome', u.nome
  )
  FROM usuarios u
  WHERE u.id = user_id;
$$;
```

#### 2. Uso no Frontend
```typescript
// Acessar claims do JWT
const user = supabase.auth.user();
const tenantId = user?.user_metadata?.tenant_id;
const role = user?.user_metadata?.role;
```

---

## 🔌 API e Endpoints

### Cliente Supabase

#### 1. Configuração
```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
```

#### 2. Tipos TypeScript
```typescript
// src/lib/types.ts
export interface Tenant {
  id: string;
  nome: string;
  cidade?: string;
  uf?: string;
  logo_url?: string;
  cor_primaria: string;
  cor_secundaria: string;
  created_at: string;
  updated_at: string;
}

export interface Motorista {
  id: string;
  tenant_id: string;
  nome: string;
  telefone?: string;
  cnh?: string;
  validade_cnh?: string;
  status: 'disponivel' | 'indisponivel';
  created_at: string;
  updated_at: string;
}
```

### Operações CRUD

#### 1. Listar Motoristas
```typescript
const fetchMotoristas = async () => {
  const { data, error } = await supabase
    .from('motoristas')
    .select('*')
    .order('nome');
    
  if (error) throw error;
  return data;
};
```

#### 2. Criar Motorista
```typescript
const createMotorista = async (motorista: Omit<Motorista, 'id' | 'created_at' | 'updated_at'>) => {
  const { data, error } = await supabase
    .from('motoristas')
    .insert([motorista])
    .select()
    .single();
    
  if (error) throw error;
  return data;
};
```

#### 3. Atualizar Motorista
```typescript
const updateMotorista = async (id: string, updates: Partial<Motorista>) => {
  const { data, error } = await supabase
    .from('motoristas')
    .update(updates)
    .eq('id', id)
    .select()
    .single();
    
  if (error) throw error;
  return data;
};
```

#### 4. Deletar Motorista
```typescript
const deleteMotorista = async (id: string) => {
  const { error } = await supabase
    .from('motoristas')
    .delete()
    .eq('id', id);
    
  if (error) throw error;
};
```

### Consultas Complexas

#### 1. Viagens com Relacionamentos
```typescript
const fetchViagensCompletas = async () => {
  const { data, error } = await supabase
    .from('viagens')
    .select(`
      *,
      motorista:motoristas(nome, telefone),
      veiculo:veiculos(placa, modelo),
      agendador:usuarios(nome),
      passageiros(nome, documento)
    `)
    .order('data_viagem', { ascending: false });
    
  if (error) throw error;
  return data;
};
```

#### 2. Dashboard com Estatísticas
```typescript
const fetchDashboardStats = async () => {
  // Motoristas ativos
  const { count: motoristasAtivos } = await supabase
    .from('motoristas')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'disponivel');

  // Veículos disponíveis
  const { count: veiculosDisponiveis } = await supabase
    .from('veiculos')
    .select('*', { count: 'exact', head: true })
    .eq('status', 'disponivel');

  // Viagens hoje
  const hoje = new Date().toISOString().split('T')[0];
  const { count: viagensHoje } = await supabase
    .from('viagens')
    .select('*', { count: 'exact', head: true })
    .gte('data_viagem', `${hoje}T00:00:00`)
    .lt('data_viagem', `${hoje}T23:59:59`);

  return {
    motoristasAtivos,
    veiculosDisponiveis,
    viagensHoje
  };
};
```

### Real-time Subscriptions

#### 1. Escutar Mudanças
```typescript
const subscribeToViagens = (callback: (payload: any) => void) => {
  const subscription = supabase
    .channel('viagens-changes')
    .on('postgres_changes', 
      { 
        event: '*', 
        schema: 'public', 
        table: 'viagens' 
      }, 
      callback
    )
    .subscribe();

  return () => subscription.unsubscribe();
};
```

#### 2. Uso em Componente
```typescript
const ViagensList = () => {
  const [viagens, setViagens] = useState<Viagem[]>([]);

  useEffect(() => {
    // Carregar dados iniciais
    fetchViagens().then(setViagens);

    // Escutar mudanças
    const unsubscribe = subscribeToViagens((payload) => {
      if (payload.eventType === 'INSERT') {
        setViagens(prev => [...prev, payload.new]);
      } else if (payload.eventType === 'UPDATE') {
        setViagens(prev => prev.map(v => 
          v.id === payload.new.id ? payload.new : v
        ));
      } else if (payload.eventType === 'DELETE') {
        setViagens(prev => prev.filter(v => v.id !== payload.old.id));
      }
    });

    return unsubscribe;
  }, []);

  return (
    <div>
      {viagens.map(viagem => (
        <ViagemCard key={viagem.id} viagem={viagem} />
      ))}
    </div>
  );
};
```

---

## ⚛️ Componentes React

### Estrutura de Componentes

```
src/components/
├── Layout.tsx          # Layout principal
├── Dashboard.tsx       # Dashboard
├── LoginForm.tsx       # Formulário de login
├── MotoristasList.tsx  # Lista de motoristas
├── ViagensList.tsx     # Lista de viagens
├── VeiculosList.tsx    # Lista de veículos
└── common/             # Componentes reutilizáveis
    ├── Button.tsx
    ├── Modal.tsx
    ├── Table.tsx
    └── LoadingSpinner.tsx
```

### Componentes Base

#### 1. Layout Principal
```typescript
// src/components/Layout.tsx
interface LayoutProps {
  children: React.ReactNode;
  tenant?: Tenant;
}

export function Layout({ children, tenant }: LayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const { signOut } = useAuth();

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar 
        tenant={tenant} 
        isOpen={sidebarOpen} 
        onClose={() => setSidebarOpen(false)} 
      />
      <main className="flex-1 overflow-auto">
        <Header onMenuClick={() => setSidebarOpen(true)} />
        {children}
      </main>
    </div>
  );
}
```

#### 2. Componente de Lista Genérico
```typescript
// src/components/common/Table.tsx
interface TableProps<T> {
  data: T[];
  columns: Column<T>[];
  loading?: boolean;
  onEdit?: (item: T) => void;
  onDelete?: (item: T) => void;
}

export function Table<T extends { id: string }>({ 
  data, 
  columns, 
  loading, 
  onEdit, 
  onDelete 
}: TableProps<T>) {
  if (loading) return <LoadingSpinner />;

  return (
    <div className="overflow-x-auto">
      <table className="min-w-full bg-white">
        <thead>
          <tr>
            {columns.map(column => (
              <th key={column.key} className="px-6 py-3 text-left">
                {column.title}
              </th>
            ))}
            <th className="px-6 py-3 text-right">Ações</th>
          </tr>
        </thead>
        <tbody>
          {data.map(item => (
            <tr key={item.id}>
              {columns.map(column => (
                <td key={column.key} className="px-6 py-4">
                  {column.render ? column.render(item) : item[column.key]}
                </td>
              ))}
              <td className="px-6 py-4 text-right">
                {onEdit && (
                  <button onClick={() => onEdit(item)}>
                    <Edit className="w-4 h-4" />
                  </button>
                )}
                {onDelete && (
                  <button onClick={() => onDelete(item)}>
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

### Hooks Customizados

#### 1. Hook para Dados
```typescript
// src/hooks/useData.ts
export function useData<T>(
  table: string,
  select: string = '*',
  dependencies: any[] = []
) {
  const [data, setData] = useState<T[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true);
        const { data: result, error } = await supabase
          .from(table)
          .select(select);

        if (error) throw error;
        setData(result || []);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Erro desconhecido');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, dependencies);

  return { data, loading, error, refetch: () => fetchData() };
}
```

#### 2. Hook para Formulários
```typescript
// src/hooks/useForm.ts
export function useForm<T>(
  initialValues: T,
  onSubmit: (values: T) => Promise<void>
) {
  const [values, setValues] = useState<T>(initialValues);
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<Partial<Record<keyof T, string>>>({});

  const handleChange = (field: keyof T, value: any) => {
    setValues(prev => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: undefined }));
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setLoading(true);
      await onSubmit(values);
    } catch (error) {
      console.error('Erro no formulário:', error);
    } finally {
      setLoading(false);
    }
  };

  return {
    values,
    errors,
    loading,
    handleChange,
    handleSubmit,
    setValues,
    setErrors
  };
}
```

### Padrões de Estado

#### 1. Estado Local vs Global
```typescript
// Estado local para componentes simples
const [isOpen, setIsOpen] = useState(false);

// Estado global para dados compartilhados
const { user } = useAuth();
const { tenant } = useTenant();
```

#### 2. Gerenciamento de Loading
```typescript
const [loading, setLoading] = useState(false);

const handleAction = async () => {
  try {
    setLoading(true);
    await performAction();
  } finally {
    setLoading(false);
  }
};
```

---

## 🔧 Manutenção e Monitoramento

### Logs e Auditoria

#### 1. Logs de Sistema
```sql
-- Tabela de logs (opcional)
CREATE TABLE system_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid REFERENCES tenants(id),
  user_id uuid,
  action text NOT NULL,
  table_name text,
  record_id uuid,
  old_values jsonb,
  new_values jsonb,
  created_at timestamptz DEFAULT now()
);
```

#### 2. Trigger de Auditoria
```sql
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO system_logs (
    tenant_id,
    user_id,
    action,
    table_name,
    record_id,
    old_values,
    new_values
  ) VALUES (
    COALESCE(NEW.tenant_id, OLD.tenant_id),
    auth.uid(),
    TG_OP,
    TG_TABLE_NAME,
    COALESCE(NEW.id, OLD.id),
    CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE NULL END,
    CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN to_jsonb(NEW) ELSE NULL END
  );
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;
```

### Monitoramento de Performance

#### 1. Queries Lentas
```sql
-- Identificar queries lentas
SELECT 
  query,
  calls,
  total_time,
  mean_time,
  rows
FROM pg_stat_statements
WHERE mean_time > 100
ORDER BY mean_time DESC;
```

#### 2. Índices Não Utilizados
```sql
-- Encontrar índices não utilizados
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch
FROM pg_stat_user_indexes
WHERE idx_scan = 0;
```

### Backup e Recuperação

#### 1. Backup Automático (Supabase)
- Backups diários automáticos
- Retenção de 7 dias (plano gratuito)
- Point-in-time recovery (planos pagos)

#### 2. Backup Manual
```bash
# Via pg_dump (se tiver acesso direto)
pg_dump -h seu-host -U postgres -d seu-banco > backup.sql

# Via Supabase CLI
supabase db dump -f backup.sql
```

#### 3. Restauração
```bash
# Via psql
psql -h seu-host -U postgres -d seu-banco < backup.sql

# Via Supabase CLI
supabase db reset
```

### Manutenção Preventiva

#### 1. Limpeza de Dados
```sql
-- Limpar logs antigos (executar mensalmente)
DELETE FROM system_logs 
WHERE created_at < now() - interval '90 days';

-- Limpar sessões expiradas
DELETE FROM auth.sessions 
WHERE expires_at < now();
```

#### 2. Análise de Tabelas
```sql
-- Atualizar estatísticas
ANALYZE;

-- Reindexar se necessário
REINDEX INDEX CONCURRENTLY nome_do_indice;
```

#### 3. Verificação de Integridade
```sql
-- Verificar constraints
SELECT 
  conname,
  contype,
  conrelid::regclass
FROM pg_constraint
WHERE NOT convalidated;

-- Verificar foreign keys órfãs
SELECT 'motoristas' as tabela, count(*) as orfaos
FROM motoristas m
LEFT JOIN tenants t ON m.tenant_id = t.id
WHERE t.id IS NULL;
```

---

## 🚨 Troubleshooting

### Problemas Comuns

#### 1. Erro de Conexão Supabase
**Sintoma**: `Failed to fetch` ou timeout
**Causas**:
- URL ou chave incorreta
- Projeto pausado/inativo
- Problemas de rede

**Solução**:
```typescript
// Verificar configuração
console.log('Supabase URL:', import.meta.env.VITE_SUPABASE_URL);
console.log('Supabase Key:', import.meta.env.VITE_SUPABASE_ANON_KEY);

// Testar conexão
const testConnection = async () => {
  try {
    const { data, error } = await supabase.from('tenants').select('count');
    console.log('Conexão OK:', data);
  } catch (error) {
    console.error('Erro de conexão:', error);
  }
};
```

#### 2. RLS Bloqueando Dados
**Sintoma**: Consultas retornam vazio mesmo com dados
**Causas**:
- JWT sem tenant_id
- Políticas RLS incorretas
- Usuário não autenticado

**Solução**:
```sql
-- Verificar JWT
SELECT auth.jwt();

-- Verificar políticas
SELECT * FROM pg_policies WHERE tablename = 'motoristas';

-- Testar sem RLS (temporário)
ALTER TABLE motoristas DISABLE ROW LEVEL SECURITY;
```

#### 3. Erro de Permissão
**Sintoma**: `permission denied` ou `access denied`
**Causas**:
- Role insuficiente
- Política RLS restritiva
- Tenant_id incorreto

**Solução**:
```typescript
// Verificar usuário atual
const user = supabase.auth.user();
console.log('User:', user);

// Verificar claims
console.log('Claims:', user?.user_metadata);

// Verificar tenant
const { data: tenant } = await supabase
  .from('tenants')
  .select('*')
  .single();
console.log('Tenant:', tenant);
```

#### 4. Performance Lenta
**Sintoma**: Queries demoram muito
**Causas**:
- Falta de índices
- Consultas complexas
- Muitos dados

**Solução**:
```sql
-- Adicionar índices
CREATE INDEX CONCURRENTLY idx_motoristas_tenant_status 
ON motoristas(tenant_id, status);

-- Otimizar consulta
EXPLAIN ANALYZE SELECT * FROM motoristas WHERE tenant_id = '...';

-- Paginar resultados
SELECT * FROM motoristas 
ORDER BY nome 
LIMIT 20 OFFSET 0;
```

### Debugging

#### 1. Logs do Frontend
```typescript
// Habilitar logs detalhados
if (import.meta.env.VITE_DEBUG === 'true') {
  console.log('Debug mode enabled');
  
  // Log todas as queries
  supabase.auth.onAuthStateChange((event, session) => {
    console.log('Auth event:', event, session);
  });
}
```

#### 2. Logs do Supabase
```sql
-- Habilitar log de queries (se tiver acesso)
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();

-- Ver logs recentes
SELECT * FROM pg_stat_activity 
WHERE state = 'active';
```

#### 3. Network Debugging
```javascript
// Interceptar requests
const originalFetch = window.fetch;
window.fetch = function(...args) {
  console.log('Fetch:', args);
  return originalFetch.apply(this, args)
    .then(response => {
      console.log('Response:', response);
      return response;
    });
};
```

### Ferramentas de Debug

#### 1. React Developer Tools
- Instalar extensão do navegador
- Inspecionar componentes e estado
- Profiling de performance

#### 2. Supabase Dashboard
- SQL Editor para queries diretas
- Auth para gerenciar usuários
- Logs para ver atividade

#### 3. Browser DevTools
- Network tab para requests
- Console para logs
- Application tab para localStorage

---

## 💻 Desenvolvimento

### Configuração do Ambiente de Dev

#### 1. Variáveis de Desenvolvimento
```env
# .env.development
VITE_SUPABASE_URL=http://localhost:54321
VITE_SUPABASE_ANON_KEY=sua-chave-local
VITE_APP_ENV=development
VITE_DEBUG=true
```

#### 2. Scripts de Desenvolvimento
```json
{
  "scripts": {
    "dev": "vite",
    "dev:debug": "VITE_DEBUG=true vite",
    "build": "vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx",
    "lint:fix": "eslint . --ext ts,tsx --fix",
    "type-check": "tsc --noEmit"
  }
}
```

### Padrões de Código

#### 1. Estrutura de Arquivos
```
src/
├── components/
│   ├── common/         # Componentes reutilizáveis
│   ├── forms/          # Formulários
│   ├── layout/         # Layout e navegação
│   └── pages/          # Páginas específicas
├── hooks/              # Custom hooks
├── lib/                # Utilitários e configurações
├── types/              # Definições TypeScript
├── utils/              # Funções auxiliares
└── constants/          # Constantes da aplicação
```

#### 2. Convenções de Nomenclatura
```typescript
// Componentes: PascalCase
export function MotoristasList() {}

// Hooks: camelCase com 'use'
export function useMotoristas() {}

// Tipos: PascalCase
export interface Motorista {}

// Constantes: UPPER_SNAKE_CASE
export const API_ENDPOINTS = {};

// Funções: camelCase
export function formatDate() {}
```

#### 3. Estrutura de Componentes
```typescript
// Imports
import React, { useState, useEffect } from 'react';
import { supabase } from '../lib/supabase';

// Types
interface Props {
  // ...
}

// Component
export function ComponentName({ prop1, prop2 }: Props) {
  // State
  const [state, setState] = useState();
  
  // Effects
  useEffect(() => {
    // ...
  }, []);
  
  // Handlers
  const handleAction = () => {
    // ...
  };
  
  // Render
  return (
    <div>
      {/* JSX */}
    </div>
  );
}
```

### Testing

#### 1. Configuração de Testes
```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
  },
});
```

#### 2. Testes de Componentes
```typescript
// src/components/__tests__/MotoristasList.test.tsx
import { render, screen } from '@testing-library/react';
import { MotoristasList } from '../MotoristasList';

describe('MotoristasList', () => {
  it('should render motoristas list', () => {
    render(<MotoristasList />);
    expect(screen.getByText('Motoristas')).toBeInTheDocument();
  });
});
```

#### 3. Testes de Hooks
```typescript
// src/hooks/__tests__/useAuth.test.ts
import { renderHook } from '@testing-library/react';
import { useAuth } from '../useAuth';

describe('useAuth', () => {
  it('should return user when authenticated', () => {
    const { result } = renderHook(() => useAuth());
    expect(result.current.user).toBeDefined();
  });
});
```

### CI/CD

#### 1. GitHub Actions
```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run lint
      - run: npm run type-check
      - run: npm run test
      - run: npm run build
```

#### 2. Deploy Automático
```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run build
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

### Versionamento

#### 1. Semantic Versioning
- **Major** (1.0.0): Breaking changes
- **Minor** (0.1.0): New features
- **Patch** (0.0.1): Bug fixes

#### 2. Changelog
```markdown
# Changelog

## [1.2.0] - 2025-01-07
### Added
- Sistema de planos de viagem
- Integração WhatsApp

### Changed
- Melhorias na interface do dashboard

### Fixed
- Correção no cálculo de quilometragem
```

---

## 📚 Recursos Adicionais

### Documentação Oficial
- [React](https://react.dev/)
- [TypeScript](https://www.typescriptlang.org/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Supabase](https://supabase.com/docs)
- [Vite](https://vitejs.dev/)

### Ferramentas Recomendadas
- **IDE**: VS Code com extensões React/TypeScript
- **Database**: Supabase Dashboard ou pgAdmin
- **API Testing**: Postman ou Insomnia
- **Design**: Figma para mockups

### Comunidade
- [Discord do Supabase](https://discord.supabase.com/)
- [GitHub Discussions](https://github.com/seu-usuario/drivesync/discussions)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/supabase)

---

**Última atualização**: Janeiro 2025  
**Versão da documentação**: 1.0  
**Autor**: Daniel Charao Machado