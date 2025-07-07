# Guia de Manutenção - DriveSync

## 📋 Índice

1. [Manutenção Preventiva](#manutenção-preventiva)
2. [Monitoramento do Sistema](#monitoramento-do-sistema)
3. [Backup e Recuperação](#backup-e-recuperação)
4. [Atualizações e Patches](#atualizações-e-patches)
5. [Resolução de Problemas](#resolução-de-problemas)
6. [Performance e Otimização](#performance-e-otimização)
7. [Segurança](#segurança)
8. [Logs e Auditoria](#logs-e-auditoria)

---

## 🔧 Manutenção Preventiva

### Tarefas Diárias

#### 1. Verificação de Status do Sistema
```bash
# Verificar se a aplicação está respondendo
curl -f https://seu-drivesync.com/health || echo "Sistema fora do ar!"

# Verificar logs de erro recentes
tail -n 100 /var/log/nginx/error.log | grep -i error
```

#### 2. Monitoramento de Recursos
```sql
-- Verificar conexões ativas no banco
SELECT count(*) as conexoes_ativas 
FROM pg_stat_activity 
WHERE state = 'active';

-- Verificar tamanho do banco
SELECT 
  pg_size_pretty(pg_database_size('postgres')) as tamanho_banco;
```

#### 3. Verificação de Alertas
- CNHs vencendo em 30 dias
- Manutenções pendentes
- Abastecimentos fora do padrão
- Usuários inativos há mais de 90 dias

### Tarefas Semanais

#### 1. Limpeza de Dados Temporários
```sql
-- Limpar sessões expiradas (executar semanalmente)
DELETE FROM auth.sessions 
WHERE expires_at < now() - interval '7 days';

-- Limpar logs antigos de sistema (se implementado)
DELETE FROM system_logs 
WHERE created_at < now() - interval '30 days';
```

#### 2. Verificação de Performance
```sql
-- Queries mais lentas da semana
SELECT 
  query,
  calls,
  total_time,
  mean_time,
  rows
FROM pg_stat_statements
WHERE last_call > now() - interval '7 days'
ORDER BY mean_time DESC
LIMIT 10;
```

#### 3. Backup de Configurações
```bash
# Backup das variáveis de ambiente
cp .env .env.backup.$(date +%Y%m%d)

# Backup da configuração do Nginx (se aplicável)
cp /etc/nginx/sites-available/drivesync /backup/nginx.$(date +%Y%m%d)
```

### Tarefas Mensais

#### 1. Análise de Crescimento
```sql
-- Crescimento de dados por mês
SELECT 
  DATE_TRUNC('month', created_at) as mes,
  COUNT(*) as novos_registros
FROM viagens
WHERE created_at >= now() - interval '12 months'
GROUP BY mes
ORDER BY mes;
```

#### 2. Otimização do Banco
```sql
-- Atualizar estatísticas
ANALYZE;

-- Verificar fragmentação de índices
SELECT 
  schemaname,
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexrelid)) as tamanho
FROM pg_stat_user_indexes
ORDER BY pg_relation_size(indexrelid) DESC;
```

#### 3. Auditoria de Segurança
- Revisar usuários ativos
- Verificar permissões RLS
- Analisar tentativas de login falhadas
- Verificar certificados SSL

### Tarefas Trimestrais

#### 1. Revisão de Capacidade
- Análise de crescimento de dados
- Projeção de necessidades futuras
- Avaliação de performance
- Planejamento de upgrades

#### 2. Teste de Recuperação
```bash
# Teste de backup e restore
pg_dump -h host -U user -d database > test_backup.sql
createdb test_restore
psql -h host -U user -d test_restore < test_backup.sql
```

#### 3. Atualização de Dependências
```bash
# Verificar atualizações disponíveis
npm outdated

# Atualizar dependências (com cuidado)
npm update
npm audit fix
```

---

## 📊 Monitoramento do Sistema

### Métricas Importantes

#### 1. Performance da Aplicação
```javascript
// Implementar no frontend
const performanceMonitor = {
  // Tempo de carregamento das páginas
  pageLoadTime: performance.now(),
  
  // Tempo de resposta das APIs
  apiResponseTime: (startTime) => performance.now() - startTime,
  
  // Erros JavaScript
  errorCount: 0,
  
  // Uso de memória
  memoryUsage: performance.memory?.usedJSHeapSize || 0
};
```

#### 2. Métricas do Banco de Dados
```sql
-- Dashboard de monitoramento
CREATE VIEW dashboard_metrics AS
SELECT 
  (SELECT count(*) FROM tenants) as total_tenants,
  (SELECT count(*) FROM usuarios) as total_usuarios,
  (SELECT count(*) FROM motoristas WHERE status = 'disponivel') as motoristas_ativos,
  (SELECT count(*) FROM veiculos WHERE status = 'disponivel') as veiculos_disponiveis,
  (SELECT count(*) FROM viagens WHERE data_viagem::date = CURRENT_DATE) as viagens_hoje,
  (SELECT avg(extract(epoch from (data_chegada - data_saida))/60) 
   FROM viagens 
   WHERE data_chegada IS NOT NULL 
   AND data_saida IS NOT NULL 
   AND created_at > now() - interval '30 days') as tempo_medio_viagem_minutos;
```

#### 3. Alertas Automáticos
```sql
-- Função para verificar alertas
CREATE OR REPLACE FUNCTION check_system_alerts()
RETURNS TABLE(
  tipo_alerta text,
  descricao text,
  severidade text,
  tenant_id uuid
) AS $$
BEGIN
  -- CNHs vencendo
  RETURN QUERY
  SELECT 
    'CNH_VENCENDO'::text,
    'CNH de ' || nome || ' vence em ' || (validade_cnh - CURRENT_DATE) || ' dias',
    CASE 
      WHEN validade_cnh - CURRENT_DATE <= 7 THEN 'CRITICO'
      WHEN validade_cnh - CURRENT_DATE <= 30 THEN 'ALTO'
      ELSE 'MEDIO'
    END,
    m.tenant_id
  FROM motoristas m
  WHERE validade_cnh <= CURRENT_DATE + interval '30 days'
  AND validade_cnh > CURRENT_DATE;
  
  -- Manutenções atrasadas
  RETURN QUERY
  SELECT 
    'MANUTENCAO_ATRASADA'::text,
    'Manutenção ' || tipo || ' atrasada para veículo ' || v.placa,
    'ALTO'::text,
    lm.tenant_id
  FROM lembretes_manutencao lm
  JOIN veiculos v ON lm.veiculo_id = v.id
  WHERE lm.data_prevista < CURRENT_DATE
  AND lm.status = 'aberto';
  
  -- Veículos com alta quilometragem sem manutenção
  RETURN QUERY
  SELECT 
    'ALTA_QUILOMETRAGEM'::text,
    'Veículo ' || placa || ' com ' || quilometragem_atual || ' km sem manutenção recente',
    'MEDIO'::text,
    tenant_id
  FROM veiculos v
  WHERE quilometragem_atual > 50000
  AND NOT EXISTS (
    SELECT 1 FROM lembretes_manutencao lm
    WHERE lm.veiculo_id = v.id
    AND lm.created_at > now() - interval '90 days'
  );
END;
$$ LANGUAGE plpgsql;
```

### Ferramentas de Monitoramento

#### 1. Supabase Dashboard
- Métricas de uso da API
- Logs de autenticação
- Performance de queries
- Uso de storage

#### 2. Monitoramento Customizado
```typescript
// src/utils/monitoring.ts
export class SystemMonitor {
  private static instance: SystemMonitor;
  
  static getInstance() {
    if (!this.instance) {
      this.instance = new SystemMonitor();
    }
    return this.instance;
  }
  
  async checkSystemHealth() {
    const checks = await Promise.allSettled([
      this.checkDatabaseConnection(),
      this.checkAuthService(),
      this.checkStorageService(),
    ]);
    
    return {
      database: checks[0].status === 'fulfilled',
      auth: checks[1].status === 'fulfilled',
      storage: checks[2].status === 'fulfilled',
      timestamp: new Date().toISOString()
    };
  }
  
  private async checkDatabaseConnection() {
    const { error } = await supabase.from('tenants').select('count');
    if (error) throw error;
  }
  
  private async checkAuthService() {
    const { error } = await supabase.auth.getSession();
    if (error) throw error;
  }
  
  private async checkStorageService() {
    const { error } = await supabase.storage.listBuckets();
    if (error) throw error;
  }
}
```

#### 3. Alertas por Email/WhatsApp
```typescript
// src/utils/alerts.ts
export class AlertManager {
  async sendAlert(alert: {
    type: string;
    message: string;
    severity: 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL';
    tenantId?: string;
  }) {
    // Enviar por email
    await this.sendEmailAlert(alert);
    
    // Enviar por WhatsApp se crítico
    if (alert.severity === 'CRITICAL') {
      await this.sendWhatsAppAlert(alert);
    }
    
    // Registrar no banco
    await this.logAlert(alert);
  }
  
  private async sendEmailAlert(alert: any) {
    // Implementar envio de email
  }
  
  private async sendWhatsAppAlert(alert: any) {
    // Implementar envio via WhatsApp
  }
  
  private async logAlert(alert: any) {
    await supabase.from('system_alerts').insert([{
      type: alert.type,
      message: alert.message,
      severity: alert.severity,
      tenant_id: alert.tenantId,
      created_at: new Date().toISOString()
    }]);
  }
}
```

---

## 💾 Backup e Recuperação

### Estratégia de Backup

#### 1. Backup Automático (Supabase)
- **Frequência**: Diário
- **Retenção**: 7 dias (plano gratuito), 30 dias (plano pago)
- **Tipo**: Point-in-time recovery disponível

#### 2. Backup Manual
```bash
#!/bin/bash
# backup_script.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/drivesync"
DB_NAME="postgres"

# Criar diretório se não existir
mkdir -p $BACKUP_DIR

# Backup do banco de dados
pg_dump -h seu-host.supabase.co \
        -U postgres \
        -d $DB_NAME \
        --no-password \
        -f "$BACKUP_DIR/drivesync_$DATE.sql"

# Compactar backup
gzip "$BACKUP_DIR/drivesync_$DATE.sql"

# Remover backups antigos (manter últimos 30 dias)
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete

echo "Backup concluído: drivesync_$DATE.sql.gz"
```

#### 3. Backup de Arquivos
```bash
#!/bin/bash
# backup_files.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/drivesync"

# Backup de configurações
tar -czf "$BACKUP_DIR/config_$DATE.tar.gz" \
    .env \
    nginx.conf \
    docker-compose.yml

# Backup de uploads (se houver)
tar -czf "$BACKUP_DIR/uploads_$DATE.tar.gz" \
    uploads/

echo "Backup de arquivos concluído"
```

### Procedimentos de Recuperação

#### 1. Recuperação Completa
```bash
#!/bin/bash
# restore_script.sh

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Uso: $0 <arquivo_backup.sql.gz>"
    exit 1
fi

# Descompactar backup
gunzip -c $BACKUP_FILE > restore_temp.sql

# Confirmar recuperação
read -p "Isso irá SOBRESCREVER todos os dados. Continuar? (y/N): " confirm
if [ "$confirm" != "y" ]; then
    echo "Operação cancelada"
    exit 1
fi

# Fazer backup atual antes de restaurar
pg_dump -h seu-host.supabase.co -U postgres -d postgres > backup_before_restore.sql

# Restaurar backup
psql -h seu-host.supabase.co -U postgres -d postgres < restore_temp.sql

# Limpar arquivo temporário
rm restore_temp.sql

echo "Recuperação concluída"
```

#### 2. Recuperação Parcial
```sql
-- Recuperar apenas uma tabela específica
-- 1. Fazer backup da tabela atual
CREATE TABLE motoristas_backup AS SELECT * FROM motoristas;

-- 2. Restaurar dados específicos
-- (executar apenas as linhas INSERT da tabela desejada do backup)

-- 3. Verificar integridade
SELECT count(*) FROM motoristas;
SELECT count(*) FROM motoristas_backup;
```

#### 3. Recuperação Point-in-Time
```bash
# Via Supabase CLI (se disponível)
supabase db reset --db-url "postgresql://..." --timestamp "2025-01-07T10:30:00Z"
```

### Testes de Recuperação

#### 1. Teste Mensal
```bash
#!/bin/bash
# test_restore.sh

# Criar banco de teste
createdb test_restore_$(date +%Y%m%d)

# Restaurar último backup
LATEST_BACKUP=$(ls -t /backup/drivesync/*.sql.gz | head -1)
gunzip -c $LATEST_BACKUP | psql -d test_restore_$(date +%Y%m%d)

# Verificar integridade
psql -d test_restore_$(date +%Y%m%d) -c "
SELECT 
  'tenants' as tabela, count(*) as registros FROM tenants
UNION ALL
SELECT 
  'usuarios' as tabela, count(*) as registros FROM usuarios
UNION ALL
SELECT 
  'motoristas' as tabela, count(*) as registros FROM motoristas;
"

# Limpar banco de teste
dropdb test_restore_$(date +%Y%m%d)

echo "Teste de recuperação concluído com sucesso"
```

---

## 🔄 Atualizações e Patches

### Processo de Atualização

#### 1. Ambiente de Staging
```bash
# Criar branch para atualização
git checkout -b update/dependencies-$(date +%Y%m%d)

# Atualizar dependências
npm update
npm audit fix

# Testar aplicação
npm run test
npm run build

# Verificar se tudo funciona
npm run preview
```

#### 2. Atualizações de Segurança
```bash
# Verificar vulnerabilidades
npm audit

# Corrigir automaticamente
npm audit fix

# Corrigir manualmente se necessário
npm audit fix --force
```

#### 3. Atualizações do Sistema
```bash
# Atualizar sistema operacional (Ubuntu/Debian)
sudo apt update
sudo apt upgrade

# Atualizar Node.js (via nvm)
nvm install --lts
nvm use --lts

# Atualizar npm
npm install -g npm@latest
```

### Versionamento

#### 1. Semantic Versioning
```json
{
  "version": "1.2.3",
  "scripts": {
    "version:patch": "npm version patch",
    "version:minor": "npm version minor", 
    "version:major": "npm version major"
  }
}
```

#### 2. Changelog Automático
```bash
# Instalar conventional-changelog
npm install -g conventional-changelog-cli

# Gerar changelog
conventional-changelog -p angular -i CHANGELOG.md -s
```

#### 3. Tags de Release
```bash
# Criar tag de release
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3

# Listar tags
git tag -l
```

### Rollback

#### 1. Rollback de Código
```bash
# Voltar para versão anterior
git checkout v1.2.2

# Ou reverter commit específico
git revert <commit-hash>

# Deploy da versão anterior
npm run build
npm run deploy
```

#### 2. Rollback de Banco
```sql
-- Se houver migrações, reverter manualmente
-- Exemplo: remover coluna adicionada
ALTER TABLE motoristas DROP COLUMN IF EXISTS nova_coluna;

-- Ou restaurar backup anterior
-- (seguir procedimento de recuperação)
```

---

## 🚨 Resolução de Problemas

### Problemas Comuns

#### 1. Sistema Lento
**Diagnóstico:**
```sql
-- Verificar queries lentas
SELECT 
  query,
  calls,
  total_time,
  mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;

-- Verificar locks
SELECT 
  blocked_locks.pid AS blocked_pid,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_statement,
  blocking_activity.query AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;
```

**Soluções:**
- Adicionar índices necessários
- Otimizar queries problemáticas
- Aumentar recursos do servidor
- Implementar cache

#### 2. Erro de Conexão
**Diagnóstico:**
```bash
# Testar conectividade
ping seu-host.supabase.co
telnet seu-host.supabase.co 5432

# Verificar logs
tail -f /var/log/nginx/error.log
```

**Soluções:**
- Verificar configuração de rede
- Verificar certificados SSL
- Verificar limites de conexão
- Reiniciar serviços

#### 3. RLS Bloqueando Dados
**Diagnóstico:**
```sql
-- Verificar políticas ativas
SELECT * FROM pg_policies WHERE tablename = 'motoristas';

-- Testar sem RLS (temporário)
SET row_security = off;
SELECT * FROM motoristas;
SET row_security = on;
```

**Soluções:**
- Verificar JWT claims
- Ajustar políticas RLS
- Verificar tenant_id no contexto

#### 4. Erro de Autenticação
**Diagnóstico:**
```typescript
// Verificar token
const session = await supabase.auth.getSession();
console.log('Session:', session);

// Verificar expiração
const token = session.data.session?.access_token;
if (token) {
  const payload = JSON.parse(atob(token.split('.')[1]));
  console.log('Token expires:', new Date(payload.exp * 1000));
}
```

**Soluções:**
- Renovar token
- Verificar configuração de auth
- Limpar cache do navegador

### Procedimentos de Emergência

#### 1. Sistema Fora do Ar
```bash
#!/bin/bash
# emergency_restart.sh

echo "Iniciando procedimento de emergência..."

# Verificar status dos serviços
systemctl status nginx
systemctl status postgresql

# Reiniciar serviços se necessário
sudo systemctl restart nginx
sudo systemctl restart postgresql

# Verificar logs
tail -n 50 /var/log/nginx/error.log
tail -n 50 /var/log/postgresql/postgresql.log

# Testar conectividade
curl -f https://seu-drivesync.com/health

echo "Procedimento de emergência concluído"
```

#### 2. Banco de Dados Corrompido
```bash
#!/bin/bash
# emergency_db_recovery.sh

echo "Iniciando recuperação de emergência do banco..."

# Parar aplicação
sudo systemctl stop nginx

# Verificar integridade
pg_dump --schema-only postgres > schema_check.sql

# Restaurar último backup válido
LATEST_BACKUP=$(ls -t /backup/drivesync/*.sql.gz | head -1)
echo "Restaurando backup: $LATEST_BACKUP"

# Confirmar antes de prosseguir
read -p "Continuar com a restauração? (y/N): " confirm
if [ "$confirm" = "y" ]; then
    gunzip -c $LATEST_BACKUP | psql postgres
    echo "Banco restaurado"
else
    echo "Operação cancelada"
fi

# Reiniciar aplicação
sudo systemctl start nginx

echo "Recuperação concluída"
```

#### 3. Ataque de Segurança
```bash
#!/bin/bash
# security_lockdown.sh

echo "Iniciando bloqueio de segurança..."

# Bloquear IPs suspeitos
iptables -A INPUT -s IP_SUSPEITO -j DROP

# Alterar senhas críticas
echo "ALTERE IMEDIATAMENTE:"
echo "1. Senha do banco de dados"
echo "2. Chaves da API"
echo "3. Certificados SSL"

# Verificar logs de acesso
tail -n 100 /var/log/nginx/access.log | grep -E "(404|500|403)"

# Fazer backup de emergência
pg_dump postgres > emergency_backup_$(date +%Y%m%d_%H%M%S).sql

echo "Bloqueio ativado. Revise logs e altere credenciais."
```

---

## ⚡ Performance e Otimização

### Otimização do Banco de Dados

#### 1. Índices Essenciais
```sql
-- Índices para queries frequentes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_motoristas_tenant_status 
ON motoristas(tenant_id, status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_viagens_data_tenant 
ON viagens(data_viagem, tenant_id);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_veiculos_tenant_status 
ON veiculos(tenant_id, status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_abastecimentos_data 
ON abastecimentos(data_abastecimento);

-- Índice para busca de texto
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_motoristas_nome_gin 
ON motoristas USING gin(to_tsvector('portuguese', nome));
```

#### 2. Particionamento (para grandes volumes)
```sql
-- Particionar tabela de viagens por data (se necessário)
CREATE TABLE viagens_2025 PARTITION OF viagens
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE viagens_2024 PARTITION OF viagens
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');
```

#### 3. Configurações do PostgreSQL
```sql
-- Configurações recomendadas (ajustar conforme recursos)
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
ALTER SYSTEM SET checkpoint_completion_target = 0.9;
ALTER SYSTEM SET wal_buffers = '16MB';
ALTER SYSTEM SET default_statistics_target = 100;

-- Aplicar configurações
SELECT pg_reload_conf();
```

### Otimização do Frontend

#### 1. Code Splitting
```typescript
// Lazy loading de componentes
const MotoristasList = lazy(() => import('./components/MotoristasList'));
const ViagensList = lazy(() => import('./components/ViagensList'));

// Uso com Suspense
<Suspense fallback={<LoadingSpinner />}>
  <MotoristasList />
</Suspense>
```

#### 2. Memoização
```typescript
// Memoizar componentes pesados
const MemoizedMotoristaCard = memo(({ motorista }: { motorista: Motorista }) => {
  return <div>{motorista.nome}</div>;
});

// Memoizar cálculos
const expensiveCalculation = useMemo(() => {
  return motoristas.filter(m => m.status === 'disponivel').length;
}, [motoristas]);
```

#### 3. Otimização de Queries
```typescript
// Usar select específico
const { data: motoristas } = await supabase
  .from('motoristas')
  .select('id, nome, status') // Apenas campos necessários
  .eq('status', 'disponivel')
  .limit(20); // Limitar resultados

// Paginação
const { data: motoristas } = await supabase
  .from('motoristas')
  .select('*')
  .range(page * pageSize, (page + 1) * pageSize - 1);
```

### Cache

#### 1. Cache no Frontend
```typescript
// Cache simples com Map
class SimpleCache {
  private cache = new Map();
  private ttl = 5 * 60 * 1000; // 5 minutos

  set(key: string, value: any) {
    this.cache.set(key, {
      value,
      timestamp: Date.now()
    });
  }

  get(key: string) {
    const item = this.cache.get(key);
    if (!item) return null;

    if (Date.now() - item.timestamp > this.ttl) {
      this.cache.delete(key);
      return null;
    }

    return item.value;
  }
}
```

#### 2. Cache de Queries
```typescript
// Hook com cache
function useCachedData<T>(key: string, fetcher: () => Promise<T>) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const cached = cache.get(key);
    if (cached) {
      setData(cached);
      setLoading(false);
      return;
    }

    fetcher().then(result => {
      cache.set(key, result);
      setData(result);
      setLoading(false);
    });
  }, [key]);

  return { data, loading };
}
```

---

## 🔒 Segurança

### Auditoria de Segurança

#### 1. Verificação de Usuários
```sql
-- Usuários ativos por tenant
SELECT 
  t.nome as tenant,
  COUNT(u.id) as usuarios_ativos,
  COUNT(CASE WHEN u.role = 'admin' THEN 1 END) as admins
FROM tenants t
LEFT JOIN usuarios u ON t.id = u.tenant_id
GROUP BY t.id, t.nome;

-- Últimos logins
SELECT 
  u.email,
  u.nome,
  last_sign_in_at
FROM auth.users au
JOIN usuarios u ON au.id::text = u.id::text
ORDER BY last_sign_in_at DESC;
```

#### 2. Verificação de Permissões
```sql
-- Verificar políticas RLS
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Verificar tabelas sem RLS
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND rowsecurity = false;
```

#### 3. Log de Atividades Suspeitas
```sql
-- Criar tabela de logs de segurança
CREATE TABLE IF NOT EXISTS security_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  user_id uuid,
  ip_address inet,
  user_agent text,
  details jsonb,
  created_at timestamptz DEFAULT now()
);

-- Função para log de eventos
CREATE OR REPLACE FUNCTION log_security_event(
  p_event_type text,
  p_user_id uuid DEFAULT NULL,
  p_ip_address inet DEFAULT NULL,
  p_user_agent text DEFAULT NULL,
  p_details jsonb DEFAULT NULL
) RETURNS void AS $$
BEGIN
  INSERT INTO security_logs (
    event_type,
    user_id,
    ip_address,
    user_agent,
    details
  ) VALUES (
    p_event_type,
    p_user_id,
    p_ip_address,
    p_user_agent,
    p_details
  );
END;
$$ LANGUAGE plpgsql;
```

### Hardening

#### 1. Configurações de Segurança
```sql
-- Configurações recomendadas
ALTER SYSTEM SET ssl = on;
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_statement = 'mod'; -- Log INSERT, UPDATE, DELETE
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1s

SELECT pg_reload_conf();
```

#### 2. Validação de Entrada
```typescript
// Validação no frontend
const validateMotorista = (data: any) => {
  const errors: any = {};

  if (!data.nome || data.nome.length < 2) {
    errors.nome = 'Nome deve ter pelo menos 2 caracteres';
  }

  if (data.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email)) {
    errors.email = 'Email inválido';
  }

  if (data.cnh && !/^\d{11}$/.test(data.cnh)) {
    errors.cnh = 'CNH deve ter 11 dígitos';
  }

  return errors;
};
```

#### 3. Rate Limiting
```typescript
// Rate limiting simples
class RateLimiter {
  private requests = new Map();
  private limit = 100; // requests per minute
  private window = 60 * 1000; // 1 minute

  isAllowed(identifier: string): boolean {
    const now = Date.now();
    const userRequests = this.requests.get(identifier) || [];
    
    // Remove requests outside window
    const validRequests = userRequests.filter(
      (time: number) => now - time < this.window
    );
    
    if (validRequests.length >= this.limit) {
      return false;
    }
    
    validRequests.push(now);
    this.requests.set(identifier, validRequests);
    return true;
  }
}
```

---

## 📝 Logs e Auditoria

### Sistema de Logs

#### 1. Logs de Aplicação
```typescript
// Logger customizado
class Logger {
  private static instance: Logger;
  
  static getInstance() {
    if (!this.instance) {
      this.instance = new Logger();
    }
    return this.instance;
  }
  
  async log(level: 'info' | 'warn' | 'error', message: string, meta?: any) {
    const logEntry = {
      level,
      message,
      meta,
      timestamp: new Date().toISOString(),
      user_id: this.getCurrentUserId(),
      tenant_id: this.getCurrentTenantId()
    };
    
    // Log no console (desenvolvimento)
    console.log(logEntry);
    
    // Salvar no banco (produção)
    if (import.meta.env.PROD) {
      await this.saveToDatabase(logEntry);
    }
  }
  
  private async saveToDatabase(logEntry: any) {
    await supabase.from('application_logs').insert([logEntry]);
  }
  
  private getCurrentUserId() {
    return supabase.auth.user()?.id;
  }
  
  private getCurrentTenantId() {
    return supabase.auth.user()?.user_metadata?.tenant_id;
  }
}
```

#### 2. Auditoria de Mudanças
```sql
-- Tabela de auditoria
CREATE TABLE audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name text NOT NULL,
  operation text NOT NULL, -- INSERT, UPDATE, DELETE
  record_id uuid NOT NULL,
  old_values jsonb,
  new_values jsonb,
  user_id uuid,
  tenant_id uuid,
  created_at timestamptz DEFAULT now()
);

-- Trigger de auditoria genérico
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO audit_log (
    table_name,
    operation,
    record_id,
    old_values,
    new_values,
    user_id,
    tenant_id
  ) VALUES (
    TG_TABLE_NAME,
    TG_OP,
    COALESCE(NEW.id, OLD.id),
    CASE WHEN TG_OP = 'DELETE' OR TG_OP = 'UPDATE' THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN to_jsonb(NEW) END,
    auth.uid(),
    COALESCE(NEW.tenant_id, OLD.tenant_id)
  );
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger nas tabelas importantes
CREATE TRIGGER audit_motoristas
  AFTER INSERT OR UPDATE OR DELETE ON motoristas
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_viagens
  AFTER INSERT OR UPDATE OR DELETE ON viagens
  FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();
```

#### 3. Relatórios de Auditoria
```sql
-- Relatório de atividades por usuário
CREATE VIEW user_activity_report AS
SELECT 
  u.nome as usuario,
  al.table_name as tabela,
  al.operation as operacao,
  COUNT(*) as quantidade,
  DATE_TRUNC('day', al.created_at) as data
FROM audit_log al
JOIN usuarios u ON al.user_id = u.id
WHERE al.created_at >= now() - interval '30 days'
GROUP BY u.nome, al.table_name, al.operation, DATE_TRUNC('day', al.created_at)
ORDER BY data DESC, quantidade DESC;

-- Relatório de mudanças críticas
CREATE VIEW critical_changes_report AS
SELECT 
  al.*,
  u.nome as usuario_nome,
  u.email as usuario_email
FROM audit_log al
JOIN usuarios u ON al.user_id = u.id
WHERE al.table_name IN ('usuarios', 'tenants')
OR (al.table_name = 'motoristas' AND al.operation = 'DELETE')
ORDER BY al.created_at DESC;
```

### Retenção de Logs

#### 1. Política de Retenção
```sql
-- Função para limpeza automática de logs
CREATE OR REPLACE FUNCTION cleanup_old_logs()
RETURNS void AS $$
BEGIN
  -- Manter logs de auditoria por 2 anos
  DELETE FROM audit_log 
  WHERE created_at < now() - interval '2 years';
  
  -- Manter logs de aplicação por 90 dias
  DELETE FROM application_logs 
  WHERE created_at < now() - interval '90 days';
  
  -- Manter logs de segurança por 1 ano
  DELETE FROM security_logs 
  WHERE created_at < now() - interval '1 year';
  
  -- Log da limpeza
  INSERT INTO application_logs (level, message, meta) VALUES (
    'info',
    'Limpeza automática de logs executada',
    jsonb_build_object('timestamp', now())
  );
END;
$$ LANGUAGE plpgsql;

-- Agendar limpeza mensal (via cron ou similar)
-- 0 2 1 * * /usr/bin/psql -c "SELECT cleanup_old_logs();"
```

#### 2. Arquivamento
```bash
#!/bin/bash
# archive_logs.sh

DATE=$(date +%Y%m%d)
ARCHIVE_DIR="/archive/drivesync"

mkdir -p $ARCHIVE_DIR

# Exportar logs antigos
psql -c "COPY (
  SELECT * FROM audit_log 
  WHERE created_at < now() - interval '1 year'
) TO STDOUT WITH CSV HEADER" > "$ARCHIVE_DIR/audit_log_$DATE.csv"

# Compactar arquivo
gzip "$ARCHIVE_DIR/audit_log_$DATE.csv"

echo "Logs arquivados: audit_log_$DATE.csv.gz"
```

---

## 📞 Contatos de Emergência

### Equipe Técnica
- **Desenvolvedor Principal**: Daniel Charao Machado
- **Email**: daniel.charao@email.com
- **Telefone**: +55 (11) 99999-9999

### Fornecedores
- **Supabase Support**: support@supabase.io
- **Hospedagem**: suporte@provedor.com

### Procedimentos de Escalação
1. **Nível 1**: Problemas menores - Resolver internamente
2. **Nível 2**: Problemas críticos - Contatar desenvolvedor
3. **Nível 3**: Sistema fora do ar - Contatar todos + fornecedores

---

**Última atualização**: Janeiro 2025  
**Versão do documento**: 1.0  
**Próxima revisão**: Abril 2025