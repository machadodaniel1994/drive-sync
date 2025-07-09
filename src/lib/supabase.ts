import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey)

// Tipos para as tabelas
export interface SystemConfig {
  id: string
  nome_organizacao: string
  cidade?: string
  uf?: string
  logo_url?: string
  cor_primaria: string
  cor_secundaria: string
  created_at: string
  updated_at: string
}

// Interface compatível para o componente (mapeamento)
export interface Tenant {
  id: string
  nome: string
  cidade?: string
  uf?: string
  logo_url?: string
  cor_primaria: string
  cor_secundaria: string
  created_at: string
  updated_at: string
}

export interface Usuario {
  id: string
  email: string
  nome: string
  role: 'admin' | 'operador' | 'motorista'
  avatar_url?: string
  telefone?: string
  created_at: string
  updated_at: string
}

export interface Motorista {
  id: string
  nome: string
  telefone?: string
  cnh?: string
  validade_cnh?: string
  status: 'disponivel' | 'indisponivel'
  created_at: string
  updated_at: string
}

export interface Veiculo {
  id: string
  placa: string
  modelo: string
  tipo: string
  quilometragem_atual: number
  identificacao_interna?: string
  status: 'disponivel' | 'em_manutencao'
  created_at: string
  updated_at: string
}

export interface Viagem {
  id: string
  motorista_id?: string
  veiculo_id?: string
  agendador_id?: string
  data_viagem: string
  data_saida?: string
  km_saida?: number
  data_chegada?: string
  km_chegada?: number
  observacoes?: string
  status: 'agendada' | 'em_andamento' | 'concluida' | 'cancelada'
  created_at: string
  updated_at: string
}

export interface Abastecimento {
  id: string
  viagem_id?: string
  motorista_id?: string
  veiculo_id?: string
  data_abastecimento: string
  local: string
  tipo_combustivel: string
  litros: number
  valor_total: number
  quilometragem?: number
  comprovante_url?: string
  created_at: string
}

export interface PlanoViagem {
  id: string
  motorista_id?: string
  titulo: string
  descricao?: string
  data_criacao: string
  status: 'pendente' | 'aprovado' | 'rejeitado'
  enviado_para?: string
  criado_do_zero: boolean
  created_at: string
  updated_at: string
}

export interface LembreteManutencao {
  id: string
  veiculo_id: string
  tipo: string
  data_prevista?: string
  km_previsto?: number
  descricao?: string
  status: 'aberto' | 'concluido' | 'cancelado'
  data_conclusao?: string
  created_at: string
  updated_at: string
}