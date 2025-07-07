# Guia de Erros Comuns - DriveSync

## 📋 Índice

1. [Erros de Conexão](#erros-de-conexão)
2. [Erros de Autenticação](#erros-de-autenticação)
3. [Erros de RLS (Row Level Security)](#erros-de-rls-row-level-security)
4. [Erros de Banco de Dados](#erros-de-banco-de-dados)
5. [Erros de Frontend](#erros-de-frontend)
6. [Erros de Performance](#erros-de-performance)
7. [Erros de Deploy](#erros-de-deploy)
8. [Erros de Configuração](#erros-de-configuração)

---

## 🔌 Erros de Conexão

### Erro: "Failed to fetch" ou "Network Error"

**Sintomas:**
- Aplicação não carrega dados
- Erro no console: `Failed to fetch`
- Timeout nas requisições

**Causas Possíveis:**
1. URL do Supabase incorreta
2. Projeto Supabase pausado/inativo
3. Problemas de rede/firewall
4. CORS mal configurado

**Soluções:**

#### 1. Verificar Configuração
```typescript
// Verificar variáveis de ambiente
console.log('Supabase URL:', import.meta.env.VITE_SUPABASE_URL);
console.log('Supabase Key:', import.meta.env.VITE_SUPABASE_ANON_KEY);

// Testar conexão básica
const testConnection = async () => {
  try {
    const { data, error } = await supabase
      .from('tenants')
      .select('count');
    
    if (error) {
      console.error('Erro de conexão:', error);
    } else {
      console.log('Conexão OK');
    }
  } catch (err) {
    console.error('Erro de rede:', err);
  }
};
```

#### 2. Verificar Status do Projeto
```bash
# Verificar se o projeto está ativo
curl -I https://seu-projeto.supabase.co/rest/v1/

# Deve retornar 200 OK
```

#### 3. Configurar CORS (se necessário)
No dashboard do Supabase:
1. Vá para **Settings > API**
2. Adicione sua URL em **CORS origins**
3. Para desenvolvimento: `http://localhost:5173`

---

## 🔐 Erros de Autenticação

### Erro: "Invalid login credentials"

**Sintomas:**
- Login falha com credenciais corretas
- Erro: `Invalid login credentials`

**Causas Possíveis:**
1. Email/senha incorretos
2. Usuário não existe na tabela `auth.users`
3. Confirmação de email pendente

**Soluções:**

#### 1. Verificar Usuário no Auth
```sql
-- Verificar se usuário existe
SELECT 
  id,
  email,
  email_confirmed_at,
  last_sign_in_at
FROM auth.users 
WHERE email = 'admin@sp.gov.br';
```

#### 2. Criar Usuário de Teste
```sql
-- Inserir usuário diretamente (apenas para desenvolvimento)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'admin@sp.gov.br',
  crypt('demo123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{}',
  false,
  '',
  '',
  '',
  ''
);
```

#### 3. Desabilitar Confirmação de Email
No dashboard do Supabase:
1. **Authentication > Settings**
2. Desmarcar **Enable email confirmations**

### Erro: "JWT expired" ou "Invalid JWT"

**Sintomas:**
- Usuário é deslogado automaticamente
- Erro: `JWT expired`
- Requisições retornam 401

**Soluções:**

#### 1. Renovar Token Automaticamente
```typescript
// Hook para renovar token
useEffect(() => {
  const { data: { subscription } } = supabase.auth.onAuthStateChange(
    async (event, session) => {
      if (event === 'TOKEN_REFRESHED') {
        console.log('Token renovado');
      }
      
      if (event === 'SIGNED_OUT') {
        // Redirecionar para login
        window.location.href = '/login';
      }
    }
  );

  return () => subscription.unsubscribe();
}, []);
```

#### 2. Verificar Expiração do Token
```typescript
const checkTokenExpiry = () => {
  const session = supabase.auth.getSession();
  const token = session.data.session?.access_token;
  
  if (token) {
    const payload = JSON.parse(atob(token.split('.')[1]));
    const expiry = new Date(payload.exp * 1000);
    console.log('Token expira em:', expiry);
    
    if (expiry < new Date()) {
      console.log('Token expirado, renovando...');
      supabase.auth.refreshSession();
    }
  }
};
```

---

## 🛡️ Erros de RLS (Row Level Security)

### Erro: Consultas retornam vazio mesmo com dados

**Sintomas:**
- Queries retornam array vazio
- Dados existem no banco mas não aparecem
- Sem mensagens de erro

**Causas Possíveis:**
1. JWT não contém `tenant_id`
2. Políticas RLS muito restritivas
3. Usuário não autenticado

**Soluções:**

#### 1. Verificar JWT Claims
```typescript
const debugJWT = async () => {
  const { data: { session } } = await supabase.auth.getSession();
  
  if (session?.access_token) {
    const payload = JSON.parse(atob(session.access_token.split('.')[1]));
    console.log('JWT Payload:', payload);
    console.log('Tenant ID:', payload.tenant_id);
  }
};
```

#### 2. Testar Sem RLS (Temporário)
```sql
-- ATENÇÃO: Apenas para debug, nunca em produção!
ALTER TABLE motoristas DISABLE ROW LEVEL SECURITY;

-- Testar query
SELECT * FROM motoristas;

-- Reabilitar RLS
ALTER TABLE motoristas ENABLE ROW LEVEL SECURITY;
```

#### 3. Verificar Políticas
```sql
-- Listar políticas ativas
SELECT 
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'motoristas';

-- Testar política manualmente
SELECT * FROM motoristas 
WHERE tenant_id = '550e8400-e29b-41d4-a716-446655440000';
```

#### 4. Corrigir JWT Claims
```sql
-- Função para adicionar tenant_id ao JWT
CREATE OR REPLACE FUNCTION auth.jwt_claims_custom(user_id uuid)
RETURNS jsonb
LANGUAGE sql
AS $$
  SELECT jsonb_build_object(
    'tenant_id', u.tenant_id,
    'role', u.role
  )
  FROM usuarios u
  WHERE u.id = user_id;
$$;
```

### Erro: "permission denied for table"

**Sintomas:**
- Erro: `permission denied for table motoristas`
- Operações CRUD falham

**Soluções:**

#### 1. Verificar Políticas de Escrita
```sql
-- Política para INSERT
CREATE POLICY "Usuários podem inserir motoristas" ON motoristas
  FOR INSERT 
  WITH CHECK (tenant_id = ((jwt() ->> 'tenant_id')::uuid));

-- Política para UPDATE
CREATE POLICY "Usuários podem atualizar motoristas" ON motoristas
  FOR UPDATE 
  USING (tenant_id = ((jwt() ->> 'tenant_id')::uuid))
  WITH CHECK (tenant_id = ((jwt() ->> 'tenant_id')::uuid));

-- Política para DELETE
CREATE POLICY "Usuários podem deletar motoristas" ON motoristas
  FOR DELETE 
  USING (tenant_id = ((jwt() ->> 'tenant_id')::uuid));
```

---

## 🗄️ Erros de Banco de Dados

### Erro: "relation does not exist"

**Sintomas:**
- Erro: `relation "motoristas" does not exist`
- Tabelas não encontradas

**Soluções:**

#### 1. Executar Migrações
```sql
-- Verificar se tabelas existem
SELECT tablename FROM pg_tables WHERE schemaname = 'public';

-- Se não existirem, executar migração completa
-- Conteúdo do arquivo: supabase/migrations/001_drop_and_recreate_schema.sql
```

#### 2. Verificar Schema
```sql
-- Verificar schema atual
SELECT current_schema();

-- Listar schemas disponíveis
SELECT schema_name FROM information_schema.schemata;
```

### Erro: "duplicate key value violates unique constraint"

**Sintomas:**
- Erro ao inserir dados
- Violação de constraint única

**Soluções:**

#### 1. Verificar Dados Duplicados
```sql
-- Encontrar duplicatas
SELECT email, COUNT(*) 
FROM usuarios 
GROUP BY email 
HAVING COUNT(*) > 1;
```

#### 2. Limpar Duplicatas
```sql
-- Remover duplicatas (manter o mais recente)
DELETE FROM usuarios 
WHERE id NOT IN (
  SELECT DISTINCT ON (email) id 
  FROM usuarios 
  ORDER BY email, created_at DESC
);
```

### Erro: "foreign key constraint violation"

**Sintomas:**
- Erro ao inserir/deletar dados
- Violação de chave estrangeira

**Soluções:**

#### 1. Verificar Relacionamentos
```sql
-- Verificar se tenant existe
SELECT id FROM tenants WHERE id = '550e8400-e29b-41d4-a716-446655440000';

-- Verificar registros órfãos
SELECT m.id, m.nome 
FROM motoristas m
LEFT JOIN tenants t ON m.tenant_id = t.id
WHERE t.id IS NULL;
```

#### 2. Corrigir Dados
```sql
-- Remover registros órfãos
DELETE FROM motoristas 
WHERE tenant_id NOT IN (SELECT id FROM tenants);

-- Ou criar tenant faltante
INSERT INTO tenants (id, nome) VALUES 
('550e8400-e29b-41d4-a716-446655440000', 'Tenant Padrão');
```

---

## ⚛️ Erros de Frontend

### Erro: "Cannot read property of undefined"

**Sintomas:**
- Erro JavaScript no console
- Aplicação quebra/tela branca

**Soluções:**

#### 1. Verificar Dados Antes de Usar
```typescript
// ❌ Erro comum
const motorista = data.motoristas[0];
const nome = motorista.nome; // Erro se data.motoristas for undefined

// ✅ Verificação segura
const motorista = data?.motoristas?.[0];
const nome = motorista?.nome || 'Nome não disponível';

// ✅ Com loading state
if (loading) return <div>Carregando...</div>;
if (!data) return <div>Sem dados</div>;
```

#### 2. Usar Optional Chaining
```typescript
// ✅ Boas práticas
const telefone = motorista?.telefone ?? 'Não informado';
const validadeCNH = motorista?.validade_cnh ? 
  new Date(motorista.validade_cnh) : null;
```

### Erro: "Hydration failed" (Next.js)

**Sintomas:**
- Erro de hidratação
- Diferenças entre servidor e cliente

**Soluções:**

#### 1. Verificar Renderização Condicional
```typescript
// ❌ Problema comum
const Component = () => {
  return (
    <div>
      {new Date().toLocaleString()} {/* Diferente no servidor/cliente */}
    </div>
  );
};

// ✅ Solução
const Component = () => {
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => {
    setMounted(true);
  }, []);
  
  if (!mounted) return null;
  
  return (
    <div>
      {new Date().toLocaleString()}
    </div>
  );
};
```

### Erro: "Maximum update depth exceeded"

**Sintomas:**
- Loop infinito de re-renders
- Aplicação trava

**Soluções:**

#### 1. Verificar Dependencies do useEffect
```typescript
// ❌ Problema
useEffect(() => {
  setData(processData(data)); // Causa loop infinito
}, [data]);

// ✅ Solução
useEffect(() => {
  setData(processData(initialData));
}, []); // Dependências corretas

// ✅ Ou usar useMemo
const processedData = useMemo(() => {
  return processData(data);
}, [data]);
```

---

## ⚡ Erros de Performance

### Erro: Aplicação lenta/travando

**Sintomas:**
- Interface lenta para responder
- Queries demoram muito
- Alto uso de CPU/memória

**Soluções:**

#### 1. Otimizar Queries
```typescript
// ❌ Query ineficiente
const { data } = await supabase
  .from('viagens')
  .select(`
    *,
    motorista:motoristas(*),
    veiculo:veiculos(*),
    passageiros(*)
  `); // Busca TODOS os dados

// ✅ Query otimizada
const { data } = await supabase
  .from('viagens')
  .select(`
    id,
    data_viagem,
    status,
    motorista:motoristas(nome),
    veiculo:veiculos(placa)
  `)
  .limit(20)
  .order('data_viagem', { ascending: false });
```

#### 2. Implementar Paginação
```typescript
const usePaginatedData = (table: string, pageSize = 20) => {
  const [page, setPage] = useState(0);
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);

  const loadPage = async (pageNum: number) => {
    setLoading(true);
    const { data: result } = await supabase
      .from(table)
      .select('*')
      .range(pageNum * pageSize, (pageNum + 1) * pageSize - 1);
    
    setData(result || []);
    setLoading(false);
  };

  useEffect(() => {
    loadPage(page);
  }, [page]);

  return { data, loading, page, setPage, loadPage };
};
```

#### 3. Memoizar Componentes
```typescript
// Memoizar componentes pesados
const MotoristaCard = memo(({ motorista }: { motorista: Motorista }) => {
  return (
    <div className="card">
      <h3>{motorista.nome}</h3>
      <p>{motorista.telefone}</p>
    </div>
  );
});

// Memoizar cálculos
const Dashboard = ({ motoristas }: { motoristas: Motorista[] }) => {
  const stats = useMemo(() => ({
    total: motoristas.length,
    ativos: motoristas.filter(m => m.status === 'disponivel').length,
    inativos: motoristas.filter(m => m.status === 'indisponivel').length
  }), [motoristas]);

  return <div>{/* Render stats */}</div>;
};
```

### Erro: Memory leak

**Sintomas:**
- Uso de memória cresce continuamente
- Aplicação fica lenta com o tempo

**Soluções:**

#### 1. Limpar Subscriptions
```typescript
useEffect(() => {
  const subscription = supabase
    .channel('viagens')
    .on('postgres_changes', { 
      event: '*', 
      schema: 'public', 
      table: 'viagens' 
    }, handleChange)
    .subscribe();

  // ✅ IMPORTANTE: Limpar subscription
  return () => {
    subscription.unsubscribe();
  };
}, []);
```

#### 2. Limpar Timers
```typescript
useEffect(() => {
  const interval = setInterval(() => {
    // Fazer algo periodicamente
  }, 5000);

  // ✅ IMPORTANTE: Limpar timer
  return () => {
    clearInterval(interval);
  };
}, []);
```

---

## 🚀 Erros de Deploy

### Erro: "Build failed"

**Sintomas:**
- Deploy falha na etapa de build
- Erros de TypeScript/ESLint

**Soluções:**

#### 1. Verificar Localmente
```bash
# Testar build local
npm run build

# Verificar erros de tipo
npm run type-check

# Verificar linting
npm run lint
```

#### 2. Corrigir Erros Comuns
```typescript
// ❌ Erro de tipo
const motorista: Motorista = data; // data pode ser null

// ✅ Correção
const motorista: Motorista | null = data;
if (motorista) {
  // Usar motorista
}

// ❌ Import não usado
import { useState, useEffect, useMemo } from 'react'; // useMemo não usado

// ✅ Correção
import { useState, useEffect } from 'react';
```

### Erro: "Environment variables not found"

**Sintomas:**
- Variáveis de ambiente undefined em produção
- Erro: `VITE_SUPABASE_URL is not defined`

**Soluções:**

#### 1. Configurar no Vercel
```bash
# Via CLI
vercel env add VITE_SUPABASE_URL
vercel env add VITE_SUPABASE_ANON_KEY

# Ou no dashboard: Settings > Environment Variables
```

#### 2. Configurar no Netlify
```bash
# Via CLI
netlify env:set VITE_SUPABASE_URL "sua-url"
netlify env:set VITE_SUPABASE_ANON_KEY "sua-chave"

# Ou no dashboard: Site settings > Environment variables
```

### Erro: "404 Not Found" em rotas

**Sintomas:**
- Páginas funcionam localmente mas não em produção
- Erro 404 ao acessar rotas diretas

**Soluções:**

#### 1. Configurar Redirects (Netlify)
```toml
# netlify.toml
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

#### 2. Configurar Redirects (Vercel)
```json
{
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ]
}
```

---

## ⚙️ Erros de Configuração

### Erro: "CORS policy blocked"

**Sintomas:**
- Erro de CORS no console
- Requisições bloqueadas pelo navegador

**Soluções:**

#### 1. Configurar CORS no Supabase
No dashboard:
1. **Settings > API**
2. Adicionar URLs em **CORS origins**:
   - `http://localhost:5173` (desenvolvimento)
   - `https://seu-dominio.com` (produção)

#### 2. Verificar Headers
```typescript
// Verificar se headers estão corretos
const response = await fetch(url, {
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  }
});
```

### Erro: "Invalid API key"

**Sintomas:**
- Erro: `Invalid API key`
- Autenticação falha

**Soluções:**

#### 1. Verificar Chaves
```typescript
// Verificar se chaves estão corretas
console.log('URL:', import.meta.env.VITE_SUPABASE_URL);
console.log('Key:', import.meta.env.VITE_SUPABASE_ANON_KEY);

// Verificar no dashboard do Supabase:
// Settings > API > Project URL e anon/public key
```

#### 2. Regenerar Chaves (se necessário)
No dashboard do Supabase:
1. **Settings > API**
2. **Reset API keys** (se comprometidas)
3. Atualizar em todas as aplicações

### Erro: Configuração de SSL/HTTPS

**Sintomas:**
- Certificado SSL inválido
- Avisos de segurança no navegador

**Soluções:**

#### 1. Verificar Certificado
```bash
# Verificar certificado
openssl s_client -connect seu-dominio.com:443 -servername seu-dominio.com

# Verificar expiração
echo | openssl s_client -connect seu-dominio.com:443 2>/dev/null | openssl x509 -noout -dates
```

#### 2. Renovar Certificado (Let's Encrypt)
```bash
# Renovar certificado
sudo certbot renew

# Verificar renovação automática
sudo systemctl status certbot.timer
```

---

## 🔍 Ferramentas de Debug

### Console do Navegador

#### 1. Logs Úteis
```typescript
// Debug de autenticação
console.log('User:', supabase.auth.user());
console.log('Session:', await supabase.auth.getSession());

// Debug de queries
const { data, error } = await supabase.from('motoristas').select('*');
console.log('Data:', data);
console.log('Error:', error);

// Debug de RLS
console.log('JWT:', await supabase.auth.getSession());
```

#### 2. Network Tab
- Verificar requisições HTTP
- Analisar headers e responses
- Identificar requests falhando

### React Developer Tools

#### 1. Inspecionar Estado
- Ver props e state dos componentes
- Identificar re-renders desnecessários
- Analisar performance

#### 2. Profiler
- Medir tempo de renderização
- Identificar componentes lentos
- Otimizar performance

### Supabase Dashboard

#### 1. SQL Editor
```sql
-- Testar queries diretamente
SELECT * FROM motoristas WHERE tenant_id = '...';

-- Verificar políticas RLS
SELECT * FROM pg_policies WHERE tablename = 'motoristas';
```

#### 2. Auth
- Ver usuários cadastrados
- Verificar sessões ativas
- Analisar logs de autenticação

#### 3. Logs
- Ver logs de API
- Analisar erros de banco
- Monitorar performance

---

## 📞 Quando Pedir Ajuda

### Informações para Incluir

#### 1. Contexto
- O que você estava tentando fazer
- Passos para reproduzir o erro
- Quando o erro começou a acontecer

#### 2. Logs e Erros
```typescript
// Capturar informações do sistema
const debugInfo = {
  userAgent: navigator.userAgent,
  url: window.location.href,
  timestamp: new Date().toISOString(),
  user: supabase.auth.user()?.id,
  error: error.message,
  stack: error.stack
};

console.log('Debug Info:', debugInfo);
```

#### 3. Configuração
- Versão do Node.js
- Versão das dependências
- Ambiente (desenvolvimento/produção)
- Navegador e versão

### Canais de Suporte

1. **GitHub Issues**: Para bugs e melhorias
2. **Email**: daniel.charao@email.com
3. **Discord**: Comunidade Supabase
4. **Stack Overflow**: Perguntas técnicas

---

**Última atualização**: Janeiro 2025  
**Versão do documento**: 1.0  
**Autor**: Daniel Charao Machado