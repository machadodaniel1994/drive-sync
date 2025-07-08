import React, { useState } from 'react'
import { Plus, Search, Edit, Trash2, User, Phone, Calendar, CheckCircle, XCircle } from 'lucide-react'
import { useData } from '../hooks/useData'
import type { Motorista } from '../lib/supabase'

export function MotoristasList() {
  const [searchTerm, setSearchTerm] = useState('')
  const [showModal, setShowModal] = useState(false)
  const { data: motoristas, loading, error } = useData<Motorista>('motoristas')
  
  const filteredMotoristas = (motoristas || []).filter(motorista =>
    motorista.nome.toLowerCase().includes(searchTerm.toLowerCase()) ||
    motorista.telefone?.includes(searchTerm)
  )

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR')
  }

  const isValidadeCNHProxima = (validade: string) => {
    const hoje = new Date()
    const vencimento = new Date(validade)
    const diasRestantes = Math.ceil((vencimento.getTime() - hoje.getTime()) / (1000 * 60 * 60 * 24))
    return diasRestantes <= 30
  }

  return (
    <div className="p-6 max-w-7xl mx-auto">
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <p className="text-red-700">Erro ao carregar motoristas: {error}</p>
        </div>
      )}

      {loading && (
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        </div>
      )}

      {/* Header */}
      {!loading && (
        <>
          <div className="flex justify-between items-center mb-8">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Motoristas</h1>
              <p className="text-gray-600 mt-1">
                Gerencie os motoristas da sua frota ({(motoristas || []).length} {(motoristas || []).length === 1 ? 'motorista' : 'motoristas'})
              </p>
            </div>
            <button
              onClick={() => setShowModal(true)}
              className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 flex items-center space-x-2 transition-colors"
            >
              <Plus className="w-5 h-5" />
              <span>Novo Motorista</span>
            </button>
          </div>

          {/* Search */}
          <div className="mb-6">
            <div className="relative max-w-md">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
              <input
                type="text"
                placeholder="Buscar motorista..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
          </div>

          {/* Motoristas Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredMotoristas.map((motorista) => (
              <div key={motorista.id} className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center space-x-3">
                    <div className="w-12 h-12 bg-blue-100 rounded-full flex items-center justify-center">
                      <User className="w-6 h-6 text-blue-600" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900">{motorista.nome}</h3>
                      <div className="flex items-center space-x-2 mt-1">
                        {motorista.status === 'disponivel' ? (
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            <CheckCircle className="w-3 h-3 mr-1" />
                            Disponível
                          </span>
                        ) : (
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                            <XCircle className="w-3 h-3 mr-1" />
                            Indisponível
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                  <div className="flex space-x-2">
                    <button className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors">
                      <Edit className="w-4 h-4" />
                    </button>
                    <button className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                <div className="space-y-3">
                  {motorista.telefone && (
                    <div className="flex items-center space-x-2 text-sm text-gray-600">
                      <Phone className="w-4 h-4" />
                      <span>{motorista.telefone}</span>
                    </div>
                  )}
                  
                  {motorista.cnh && (
                    <div className="text-sm text-gray-600">
                      <span className="font-medium">CNH:</span> {motorista.cnh}
                    </div>
                  )}
                  
                  {motorista.validade_cnh && (
                    <div className="flex items-center space-x-2 text-sm">
                      <Calendar className="w-4 h-4" />
                      <span className="text-gray-600">Validade:</span>
                      <span className={`font-medium ${
                        isValidadeCNHProxima(motorista.validade_cnh) ? 'text-red-600' : 'text-gray-900'
                      }`}>
                        {formatDate(motorista.validade_cnh)}
                      </span>
                      {isValidadeCNHProxima(motorista.validade_cnh) && (
                        <span className="text-xs bg-red-100 text-red-800 px-2 py-1 rounded-full">
                          Vence em breve
                        </span>
                      )}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>

          {filteredMotoristas.length === 0 && (
            <div className="text-center py-12">
              <User className="w-16 h-16 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-900 mb-2">Nenhum motorista encontrado</h3>
              <p className="text-gray-500">
                {searchTerm ? 'Tente buscar com termos diferentes' : 'Adicione o primeiro motorista da sua frota'}
              </p>
            </div>
          )}

          {/* Modal para adicionar motorista */}
          {showModal && (
            <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
              <div className="bg-white rounded-xl p-6 w-full max-w-md mx-4">
                <h2 className="text-xl font-bold text-gray-900 mb-6">Novo Motorista</h2>
                
                <form className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Nome Completo
                    </label>
                    <input
                      type="text"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                      placeholder="Nome do motorista"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Telefone
                    </label>
                    <input
                      type="tel"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                      placeholder="(11) 99999-9999"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      CNH
                    </label>
                    <input
                      type="text"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                      placeholder="Número da CNH"
                    />
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Validade da CNH
                    </label>
                    <input
                      type="date"
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                    />
                  </div>
                  
                  <div className="flex space-x-3 pt-6">
                    <button
                      type="button"
                      onClick={() => setShowModal(false)}
                      className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
                    >
                      Cancelar
                    </button>
                    <button
                      type="submit"
                      className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
                    >
                      Adicionar
                    </button>
                  </div>
                </form>
              </div>
            </div>
          )}
        </>
      )}
    </div>
  )
}