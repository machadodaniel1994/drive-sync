# DriveSync - Sistema SaaS de Gestão de Frotas

![DriveSync Logo](https://images.pexels.com/photos/8828786/pexels-photo-8828786.jpeg?auto=compress&cs=tinysrgb&w=200&h=100&dpr=2)

DriveSync é um sistema SaaS (Software as a Service) completo para gestão de frotas internas, desenvolvido especialmente para prefeituras, órgãos públicos e empresas privadas. O sistema é **multi-tenant (white label)** e permite isolamento total dos dados de cada cliente.

**Desenvolvido por Daniel Charao Machado**

## 🚀 Tecnologias Utilizadas

- **Frontend**: React.js 18+ com TypeScript
- **Backend**: Supabase (PostgreSQL, Auth, Row Level Security)
- **Estilização**: Tailwind CSS
- **Ícones**: Lucide React
- **Build Tool**: Vite
- **Hospedagem**: Vercel / Netlify

## 📋 Funcionalidades Principais

### 🏢 Multi-Tenant & White Label
- ✅ Cada cliente (tenant) possui ambiente completamente isolado
- ✅ Configuração personalizada de identidade visual (logo, cores)
- ✅ Dados não compartilhados entre clientes
- ✅ Row Level Security (RLS) garantindo segurança total

### 👥 Gestão de Motoristas
- ✅ Cadastro completo de motoristas
- ✅ Controle de status (Disponível / Indisponível)
- ✅ Gestão de CNH com alertas de vencimento
- ✅ Visualização de viagens agendadas
- ✅ Histórico completo de viagens
- ✅ Criação e edição de planos de viagem
- ✅ Sistema de justificativas para alterações

### 🚗 Gestão de Veículos
- ✅ Cadastro detalhado (placa, modelo, tipo, quilometragem)
- ✅ Controle de status (Disponível / Em manutenção)
- ✅ Identificação interna personalizada
- ✅ Relacionamento muitos-para-muitos com motoristas
- ✅ Histórico de manutenções e abastecimentos

### 📅 Agendamento de Viagens
- ✅ Criação e edição de viagens
- ✅ Gestão de passageiros (nome + documento)
- ✅ Validações automáticas de disponibilidade
- ✅ Notificações automáticas aos motoristas
- ✅ Controle de quilometragem (saída/chegada)
- ✅ Status em tempo real (agendada, em andamento, concluída)

### 🗺️ Planos de Viagem
- ✅ Criação a partir de viagens existentes ou do zero
- ✅ Sistema de aprovação/rejeição
- ✅ Histórico completo de alterações
- ✅ Justificativas obrigatórias para mudanças
- ✅ Envio para supervisão/gerência

### ⛽ Controle de Abastecimentos
- ✅ Registro detalhado (local, combustível, litros, valor)
- ✅ Vinculação com viagens
- ✅ Upload de comprovantes
- ✅ Relatórios de consumo e custos
- ✅ Alertas para abastecimentos fora do padrão

### 🔧 Manutenção Preventiva
- ✅ Lembretes por data ou quilometragem
- ✅ Tipos personalizáveis de manutenção
- ✅ Histórico completo de serviços
- ✅ Alertas automáticos

### 📊 Painel Administrativo
- ✅ Dashboard com métricas em tempo real
- ✅ Relatórios detalhados (PDF, Excel)
- ✅ Sistema de alertas inteligentes
- ✅ Gestão de usuários e permissões
- ✅ Logs e auditoria completa

### 📱 Integração WhatsApp
- ✅ Notificações automáticas via WhatsApp
- ✅ Links diretos para o sistema
- ✅ Sem necessidade de API paga
- ✅ Funciona sem contato salvo

### 🆔 Crachá Digital com QR Code
- ✅ Geração automática de crachás
- ✅ QR Code com link para perfil público
- ✅ Layout moderno e personalizável
- ✅ Exportação em PDF/PNG/JPG

## 🔧 Instalação e Configuração

### Pré-requisitos
- Node.js 18+ 
- Conta no Supabase
- Git

### 1. Clone o Repositório
```bash
git clone https://github.com/seu-usuario/drivesync.git
cd drivesync
```

### 2. Instale as Dependências
```bash
npm install
```

### 3. Configure as Variáveis de Ambiente
```bash
cp .env.example .env
```

Edite o arquivo `.env` com suas credenciais do Supabase:
```env
VITE_SUPABASE_URL=sua_url_do_supabase
VITE_SUPABASE_ANON_KEY=sua_chave_anonima_do_supabase
```

### 4. Configure o Banco de Dados

#### Opção A: Usando o Supabase Dashboard
1. Acesse o [Supabase Dashboard](https://supabase.com/dashboard)
2. Vá para **SQL Editor**
3. Execute o conteúdo do arquivo `supabase/migrations/001_drop_and_recreate_schema.sql`

#### Opção B: Usando CLI (se disponível)
```bash
supabase db reset
```

### 5. Inicie o Servidor de Desenvolvimento
```bash
npm run dev
```

O sistema estará disponível em `http://localhost:5173`

## 🔑 Credenciais de Teste

Após executar a migração, você pode usar estas credenciais para testar:

| Tipo | Email | Senha | Descrição |
|------|-------|-------|-----------|
| **Administrador** | admin@sp.gov.br | demo123 | Acesso completo ao sistema |
| **Operador** | operador@sp.gov.br | demo123 | Gestão operacional |
| **Motorista** | motorista@sp.gov.br | demo123 | Acesso limitado |

## 📊 Dados de Demonstração

O sistema vem com dados pré-carregados para demonstração:
- **1 Tenant**: Prefeitura Municipal de São Paulo
- **5 Motoristas** com diferentes status e CNHs
- **5 Veículos** (vans, ambulância, caminhonete)
- **3 Viagens** em diferentes estágios
- **5 Passageiros** distribuídos nas viagens
- **2 Abastecimentos** com dados realistas
- **3 Lembretes de manutenção** pendentes
- **2 Planos de viagem** (aprovado e pendente)

## 🗄️ Estrutura do Banco de Dados

### Tabelas Principais

#### `tenants` - Clientes/Empresas
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid | Chave primária |
| nome | text | Nome da empresa/prefeitura |
| cidade | text | Cidade |
| uf | text | Estado |
| logo_url | text | URL do logotipo |
| cor_primaria | text | Cor primária do tema |
| cor_secundaria | text | Cor secundária do tema |

#### `usuarios` - Usuários do Sistema
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid | Chave primária |
| tenant_id | uuid | FK → tenants.id |
| email | text | Email único |
| nome | text | Nome completo |
| role | text | admin, operador, motorista |
| telefone | text | Telefone de contato |

#### `motoristas` - Motoristas
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid | Chave primária |
| tenant_id | uuid | FK → tenants.id |
| nome | text | Nome do motorista |
| telefone | text | Telefone |
| cnh | text | Número da CNH |
| validade_cnh | date | Validade da CNH |
| status | text | disponivel, indisponivel |

#### `veiculos` - Veículos da Frota
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid | Chave primária |
| tenant_id | uuid | FK → tenants.id |
| placa | text | Placa do veículo |
| modelo | text | Modelo/marca |
| tipo | text | Van, ambulância, etc. |
| quilometragem_atual | integer | KM atual |
| identificacao_interna | text | Código interno |
| status | text | disponivel, em_manutencao |

#### `viagens` - Viagens Agendadas/Realizadas
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid | Chave primária |
| tenant_id | uuid | FK → tenants.id |
| motorista_id | uuid | FK → motoristas.id |
| veiculo_id | uuid | FK → veiculos.id |
| agendador_id | uuid | FK → usuarios.id |
| data_viagem | timestamp | Data/hora planejada |
| data_saida | timestamp | Horário real de saída |
| km_saida | integer | KM na saída |
| data_chegada | timestamp | Horário real de chegada |
| km_chegada | integer | KM na chegada |
| observacoes | text | Observações |
| status | text | agendada, em_andamento, concluida, cancelada |

#### `abastecimentos` - Controle de Combustível
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid | Chave primária |
| tenant_id | uuid | FK → tenants.id |
| viagem_id | uuid | FK → viagens.id (opcional) |
| motorista_id | uuid | FK → motoristas.id |
| veiculo_id | uuid | FK → veiculos.id |
| data_abastecimento | timestamp | Data/hora |
| local | text | Posto/local |
| tipo_combustivel | text | Diesel, gasolina, etc. |
| litros | numeric | Litros abastecidos |
| valor_total | numeric | Valor gasto |
| quilometragem | integer | KM no momento |
| comprovante_url | text | URL do comprovante |

#### `planos_viagem` - Planos de Viagem
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid | Chave primária |
| motorista_id | uuid | FK → motoristas.id |
| tenant_id | uuid | FK → tenants.id |
| titulo | text | Título do plano |
| descricao | text | Descrição/observações |
| status | text | pendente, aprovado, rejeitado |
| enviado_para | text | Destinatário |
| criado_do_zero | boolean | Criado do zero? |

#### `lembretes_manutencao` - Manutenção Preventiva
| Campo | Tipo | Descrição |
|-------|------|-----------|
| id | uuid | Chave primária |
| veiculo_id | uuid | FK → veiculos.id |
| tenant_id | uuid | FK → tenants.id |
| tipo | text | Tipo de manutenção |
| data_prevista | date | Data prevista |
| km_previsto | integer | KM previsto |
| descricao | text | Descrição |
| status | text | aberto, concluido, cancelado |

### Tabelas de Relacionamento

- `motoristas_veiculos` - Relacionamento N:N entre motoristas e veículos
- `passageiros` - Passageiros das viagens
- `planos_viagem_viagens` - Viagens associadas aos planos
- `planos_viagem_custom_trajetos` - Trajetos customizados
- `planos_viagem_alteracoes` - Histórico de alterações nos planos

## 🔒 Segurança

### Row Level Security (RLS)
- ✅ **Isolamento total por tenant** - Cada cliente vê apenas seus dados
- ✅ **Políticas automáticas** - Aplicadas em todas as operações
- ✅ **Validação no banco** - Segurança garantida mesmo com acesso direto

### Autenticação
- ✅ **Supabase Auth** - Sistema robusto e confiável
- ✅ **JWT Tokens** - Autenticação stateless
- ✅ **Roles baseadas** - Controle granular de acesso

### Auditoria
- ✅ **Logs automáticos** - Todas as operações registradas
- ✅ **Timestamps** - created_at e updated_at em todas as tabelas
- ✅ **Histórico de alterações** - Rastreabilidade completa

## 🚀 Deploy

### Netlify
```bash
npm run build
# Deploy da pasta dist/
```

### Vercel
```bash
npm run build
vercel --prod
```

### Servidor Próprio
```bash
npm run build
# Servir arquivos da pasta dist/
```

## 📚 Scripts Disponíveis

```bash
# Desenvolvimento
npm run dev

# Build para produção
npm run build

# Preview da build
npm run preview

# Linting
npm run lint
```

## 🔧 Configuração Avançada

### Personalização de Cores
Edite as cores padrão no arquivo `supabase/migrations/001_drop_and_recreate_schema.sql`:
```sql
cor_primaria text DEFAULT '#1E40AF',
cor_secundaria text DEFAULT '#059669',
```

### Adição de Novos Tipos de Veículos
Modifique a validação na tabela `veiculos` conforme necessário.

### Configuração de Notificações WhatsApp
O sistema gera links automáticos no formato:
```
https://wa.me/5511999999999?text=Mensagem%20codificada
```

## 🐛 Solução de Problemas

### Erro de Conexão com Supabase
1. Verifique as variáveis de ambiente no `.env`
2. Confirme se o projeto Supabase está ativo
3. Verifique se as migrações foram executadas

### Erro de Permissão RLS
1. Confirme se o usuário está autenticado
2. Verifique se o `tenant_id` está correto no JWT
3. Revise as políticas RLS no Supabase

### Dados não Aparecem
1. Execute a migração completa
2. Verifique se há dados de teste inseridos
3. Confirme se o RLS está configurado corretamente

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 📞 Suporte

Para suporte técnico ou dúvidas:
- **Email**: daniel.charao@email.com
- **GitHub Issues**: [Abrir Issue](https://github.com/seu-usuario/drivesync/issues)
- **Documentação**: [Wiki do Projeto](https://github.com/seu-usuario/drivesync/wiki)

## 🎯 Roadmap

### Versão 2.0 (Planejada)
- [ ] App mobile React Native
- [ ] Integração com GPS/rastreamento
- [ ] Relatórios avançados com gráficos
- [ ] API REST completa
- [ ] Sistema de escalas automáticas
- [ ] Integração com sistemas de pagamento

### Versão 1.5 (Em desenvolvimento)
- [ ] Módulo de manutenção avançado
- [ ] Sistema de aprovações por workflow
- [ ] Notificações push
- [ ] Exportação de dados em massa

---

© 2025 - DriveSync. Desenvolvido por **Daniel Charao Machado**

**Sistema de Gestão de Frotas - Solução Completa para Prefeituras e Empresas**