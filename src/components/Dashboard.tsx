import React from 'react'
import { Car, Users, Calendar, TrendingUp, AlertTriangle, CheckCircle } from 'lucide-react'

interface DashboardProps {
  systemConfig: {
    nome: string
    cor_primaria: string
    cor_secundaria: string
  }
}

export function Dashboard({ systemConfig }: DashboardProps) {
  const stats = [
    {
      name: 'Motoristas Ativos',
      value: '12',
      change: '+2 este mês',
      changeType: 'positive',
      icon: Users,
      color: 'bg-blue-500',
    },
    {
      name: 'Veículos Disponíveis',
      value: '8',
      change: '2 em manutenção',
      changeType: 'neutral',
      icon: Car,
      color: 'bg-green-500',
    },
    {
      name: 'Viagens Hoje',
      value: '15',
      change: '+5 vs ontem',
      changeType: 'positive',
      icon: Calendar,
      color: 'bg-purple-500',
    },
    {
      name: 'Consumo Mensal',
      value: 'R$ 2.450',
      change: '-8% vs mês anterior',
      changeType: 'positive',
      icon: TrendingUp,
      color: 'bg-orange-500',
    },
  ]

  const recentActivities = [
    {
      id: 1,
      type: 'viagem',
      message: 'Viagem para Hospital Central iniciada',
      motorista: 'Carlos Oliveira',
      time: '2 min atrás',
      status: 'success',
    },
    {
      id: 2,
      type: 'manutencao',
      message: 'Manutenção preventiva VAN-001 agendada',
      motorista: 'Sistema',
      time: '15 min atrás',
      status: 'warning',
    },
    {
      id: 3,
      type: 'abastecimento',
      message: 'Abastecimento registrado - R$ 120,00',
      motorista: 'Ana Pereira',
      time: '1 hora atrás',
      status: 'info',
    },
  ]

  const alerts = [
    {
      id: 1,
      type: 'warning',
      message: 'CNH de Ricardo Alves vence em 30 dias',
      time: 'Hoje',
    },
    {
      id: 2,
      type: 'error',
      message: 'Veículo ABC-1234 com manutenção atrasada',
      time: 'Ontem',
    },
  ]

  return (
    <div className="p-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">
          Bem-vindo ao DriveSync
        </h1>
        <p className="text-gray-600">
          Painel de controle - {systemConfig.nome}
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {stats.map((stat) => (
          <div key={stat.name} className="bg-white rounded-xl shadow-sm p-6 border border-gray-100">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-600">{stat.name}</p>
                <p className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</p>
              </div>
              <div className={`p-3 rounded-lg ${stat.color}`}>
                <stat.icon className="w-6 h-6 text-white" />
              </div>
            </div>
            <div className="mt-4">
              <span className={`text-sm ${
                stat.changeType === 'positive' ? 'text-green-600' : 
                stat.changeType === 'negative' ? 'text-red-600' : 'text-gray-600'
              }`}>
                {stat.change}
              </span>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Recent Activities */}
        <div className="lg:col-span-2 bg-white rounded-xl shadow-sm border border-gray-100">
          <div className="p-6 border-b border-gray-100">
            <h3 className="text-lg font-semibold text-gray-900">Atividades Recentes</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {recentActivities.map((activity) => (
                <div key={activity.id} className="flex items-start space-x-3">
                  <div className={`p-2 rounded-full ${
                    activity.status === 'success' ? 'bg-green-100' :
                    activity.status === 'warning' ? 'bg-yellow-100' :
                    'bg-blue-100'
                  }`}>
                    <CheckCircle className={`w-4 h-4 ${
                      activity.status === 'success' ? 'text-green-600' :
                      activity.status === 'warning' ? 'text-yellow-600' :
                      'text-blue-600'
                    }`} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900">
                      {activity.message}
                    </p>
                    <p className="text-sm text-gray-500">
                      {activity.motorista} • {activity.time}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Alerts */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-100">
          <div className="p-6 border-b border-gray-100">
            <h3 className="text-lg font-semibold text-gray-900">Alertas</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {alerts.map((alert) => (
                <div key={alert.id} className="flex items-start space-x-3">
                  <AlertTriangle className={`w-5 h-5 mt-0.5 ${
                    alert.type === 'error' ? 'text-red-500' : 'text-yellow-500'
                  }`} />
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900">
                      {alert.message}
                    </p>
                    <p className="text-sm text-gray-500">
                      {alert.time}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}