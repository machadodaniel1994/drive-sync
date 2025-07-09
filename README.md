# DriveSync - Sistema de Gestão de Frotas (Next.js)

Sistema completo para gestão de frotas internas, desenvolvido especialmente para prefeituras, órgãos públicos e empresas privadas.

## 🚀 Tecnologias

- **Next.js 14** com App Router
- **TypeScript** para tipagem estática
- **Tailwind CSS** para estilização
- **Supabase** para backend e autenticação
- **Lucide React** para ícones

## 📋 Funcionalidades

- ✅ **Dashboard completo** com métricas em tempo real
- ✅ **Gestão de motoristas** com controle de CNH
- ✅ **Controle de veículos** e manutenção preventiva
- ✅ **Sistema de viagens** com passageiros
- ✅ **Controle de abastecimento** com comprovantes
- ✅ **Landing page moderna** e responsiva
- ✅ **Sistema de autenticação** seguro
- ✅ **Design system** consistente

## ⚙️ Configuração

### 1. Pré-requisitos

- Node.js 18+
- Conta no Supabase

### 2. Instalação

```bash
# Clone o repositório
git clone <repository-url>
cd drivesync-nextjs

# Instale as dependências
npm install
```

### 3. Configuração do Supabase

1. Crie uma conta no [Supabase](https://supabase.com)
2. Crie um novo projeto
3. Vá para **SQL Editor** no dashboard
4. Execute o conteúdo do arquivo `supabase/migrations/20250709172626_rustic_gate.sql`

### 4. Variáveis de Ambiente

Crie um arquivo `.env.local` na raiz do projeto:

```env
# Supabase Configuration
NEXT_PUBLIC_SUPABASE_URL=https://seu-projeto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=sua-chave-anonima

# App Configuration
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

### 5. Executar o Projeto

```bash
npm run dev
```

O sistema estará disponível em `http://localhost:3000`

## 🔑 Credenciais de Teste

Após executar a migração do banco, você pode usar estas credenciais:

| Tipo | Email | Senha | Descrição |
|------|-------|-------|-----------|
| **Administrador** | admin@manoelviana.rs.gov.br | demo123 | Acesso completo ao sistema |
| **Operador** | operador@manoelviana.rs.gov.br | demo123 | Gestão operacional |
| **Motorista** | motorista@manoelviana.rs.gov.br | demo123 | Acesso limitado |

## 📊 Estrutura do Banco de Dados

### Tabelas Principais

- `system_config` - Configurações do sistema
- `users` - Usuários (admin, operator, driver)
- `drivers` - Motoristas
- `vehicles` - Veículos
- `trips` - Viagens
- `passengers` - Passageiros
- `fuel_records` - Abastecimentos
- `maintenance_reminders` - Lembretes de manutenção

### Dados de Demonstração

O sistema vem com dados pré-carregados da **Prefeitura Municipal de Manoel Viana - RS**:
- 3 usuários com diferentes roles
- 5 motoristas com status variados
- 5 veículos (vans, ambulância, caminhonete)
- 3 viagens em diferentes estágios
- 5 passageiros distribuídos nas viagens
- 2 registros de abastecimento
- 3 lembretes de manutenção

## 🎨 Design System

### Componentes Base

- `Button` - Botões com variantes e estados
- `Input` - Campos de entrada com validação
- `Modal` - Modais responsivos
- `LoadingSpinner` - Indicadores de carregamento

### Classes Utilitárias

```css
.btn-primary     /* Botão primário */
.btn-secondary   /* Botão secundário */
.card           /* Card padrão */
.input          /* Input padrão */
.badge-success  /* Badge verde */
.badge-warning  /* Badge amarelo */
.badge-error    /* Badge vermelho */
```

## 🔐 Segurança

- **Row Level Security (RLS)** habilitado em todas as tabelas
- **Políticas baseadas em roles** (admin, operator, driver)
- **Autenticação JWT** via Supabase
- **Validação client-side e server-side**

## 📱 Responsividade

O sistema é totalmente responsivo e funciona perfeitamente em:
- 📱 **Mobile** (320px+)
- 📱 **Tablet** (768px+)
- 💻 **Desktop** (1024px+)
- 🖥️ **Large Desktop** (1280px+)

## 🚀 Deploy

### Vercel (Recomendado)

```bash
npm run build
vercel --prod
```

### Netlify

```bash
npm run build
# Deploy da pasta .next/
```

### Servidor Próprio

```bash
npm run build
npm start
```

## 📚 Scripts Disponíveis

```bash
npm run dev        # Desenvolvimento
npm run build      # Build para produção
npm start          # Servidor de produção
npm run lint       # Linting
npm run type-check # Verificação de tipos
```

## 🔧 Personalização

### Cores do Sistema

Edite o arquivo `tailwind.config.js`:

```javascript
theme: {
  extend: {
    colors: {
      primary: {
        // Suas cores personalizadas
      }
    }
  }
}
```

### Configurações do Sistema

As configurações são gerenciadas pela tabela `system_config`:

```sql
UPDATE system_config SET 
  organization_name = 'Sua Organização',
  city = 'Sua Cidade',
  state = 'Seu Estado',
  primary_color = '#sua-cor',
  secondary_color = '#sua-cor-secundaria';
```

## 🐛 Solução de Problemas

### Erro "supabaseUrl is required"

1. Verifique se o arquivo `.env.local` existe
2. Confirme se as variáveis estão corretas
3. Reinicie o servidor de desenvolvimento

### Dados não aparecem

1. Execute a migração do banco de dados
2. Verifique se o RLS está configurado
3. Confirme se o usuário está autenticado

### Erro de build

```bash
npm run type-check  # Verificar erros de TypeScript
npm run lint        # Verificar problemas de código
```

## 📞 Suporte

Para suporte técnico ou dúvidas:
- **Email**: daniel.charao@email.com
- **GitHub Issues**: Abra uma issue no repositório

## 📄 Licença

Este projeto está sob a licença MIT.

---

© 2025 DriveSync. Desenvolvido por **Daniel Charao Machado**