import React, { useState } from 'react'
import { 
  Car, 
  Users, 
  Calendar, 
  MapPin, 
  Fuel, 
  Settings, 
  Bell,
  Menu,
  X,
  LogOut,
  BarChart3,
  Wrench
} from 'lucide-react'
import { useAuth } from '../hooks/useAuth'

interface LayoutProps {
  children: React.ReactNode
  systemConfig?: {
    nome: string
    logo_url?: string
    cor_primaria: string
    cor_secundaria: string
  }
}

export function Layout({ children, systemConfig }: LayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const { signOut } = useAuth()

  const navigation = [
    { name: 'Dashboard', href: '/dashboard', icon: BarChart3 },
    { name: 'Motoristas', href: '/motoristas', icon: Users },
    { name: 'Veículos', href: '/veiculos', icon: Car },
    { name: 'Viagens', href: '/viagens', icon: Calendar },
    { name: 'Planos de Viagem', href: '/planos', icon: MapPin },
    { name: 'Abastecimentos', href: '/abastecimentos', icon: Fuel },
    { name: 'Manutenção', href: '/manutencao', icon: Wrench },
    { name: 'Configurações', href: '/configuracoes', icon: Settings },
  ]

  const handleSignOut = async () => {
    try {
      await signOut()
    } catch (error) {
      console.error('Erro ao sair:', error)
    }
  }

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Sidebar */}
      <div className={`${sidebarOpen ? 'block' : 'hidden'} fixed inset-0 z-50 lg:relative lg:block lg:z-0`}>
        <div className="flex">
          <div className="flex flex-col w-64 bg-white shadow-lg">
            <div className="flex items-center justify-between p-4 border-b border-gray-200">
              <div className="flex items-center space-x-3">
                {systemConfig?.logo_url && (
                  <img 
                    src={systemConfig.logo_url} 
                    alt={systemConfig.nome} 
                    className="w-8 h-8 rounded-full object-cover"
                  />
                )}
                <div>
                  <h1 className="text-lg font-bold text-gray-900">DriveSync</h1>
                  {systemConfig && (
                    <p className="text-xs text-gray-500 truncate w-40">{systemConfig.nome}</p>
                  )}
                </div>
              </div>
              <button
                onClick={() => setSidebarOpen(false)}
                className="lg:hidden p-1 rounded-md hover:bg-gray-100"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>

            <nav className="flex-1 px-4 py-6 space-y-2">
              {navigation.map((item) => (
                <a
                  key={item.name}
                  href={item.href}
                  className="flex items-center px-3 py-2 text-sm font-medium text-gray-700 rounded-lg hover:bg-gray-100 hover:text-gray-900 transition-colors"
                >
                  <item.icon className="w-5 h-5 mr-3" />
                  {item.name}
                </a>
              ))}
            </nav>

            <div className="border-t border-gray-200 p-4">
              <button
                onClick={handleSignOut}
                className="flex items-center w-full px-3 py-2 text-sm font-medium text-red-600 rounded-lg hover:bg-red-50 transition-colors"
              >
                <LogOut className="w-5 h-5 mr-3" />
                Sair
              </button>
            </div>
          </div>
          
          {/* Overlay for mobile */}
          <div 
            className="flex-1 lg:hidden"
            onClick={() => setSidebarOpen(false)}
          />
        </div>
      </div>

      {/* Main content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Header */}
        <header className="bg-white shadow-sm border-b border-gray-200">
          <div className="flex items-center justify-between px-4 py-4">
            <button
              onClick={() => setSidebarOpen(true)}
              className="lg:hidden p-2 rounded-md hover:bg-gray-100"
            >
              <Menu className="w-5 h-5 text-gray-500" />
            </button>
            
            <div className="flex items-center space-x-4">
              <button className="p-2 rounded-full hover:bg-gray-100 relative">
                <Bell className="w-5 h-5 text-gray-500" />
                <span className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full"></span>
              </button>
            </div>
          </div>
        </header>

        {/* Main content area */}
        <main className="flex-1 overflow-auto">
          {children}
        </main>
      </div>
    </div>
  )
}