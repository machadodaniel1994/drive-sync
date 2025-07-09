'use client'

import { useState, ReactNode } from 'react'
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
import { useAuth } from '@/lib/hooks/useAuth'
import { Button } from '@/components/ui/Button'

interface DashboardLayoutProps {
  children: ReactNode
}

export function DashboardLayout({ children }: DashboardLayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false)
  const { signOut } = useAuth()

  const navigation = [
    { name: 'Dashboard', href: '/', icon: BarChart3, current: true },
    { name: 'Motoristas', href: '/drivers', icon: Users, current: false },
    { name: 'Veículos', href: '/vehicles', icon: Car, current: false },
    { name: 'Viagens', href: '/trips', icon: Calendar, current: false },
    { name: 'Abastecimentos', href: '/fuel', icon: Fuel, current: false },
    { name: 'Manutenção', href: '/maintenance', icon: Wrench, current: false },
    { name: 'Configurações', href: '/settings', icon: Settings, current: false },
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
                <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
                  <Car className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h1 className="text-lg font-bold text-gray-900">DriveSync</h1>
                  <p className="text-xs text-gray-500">Prefeitura de Manoel Viana</p>
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
                  className={`flex items-center px-3 py-2 text-sm font-medium rounded-lg transition-colors ${
                    item.current
                      ? 'bg-primary-100 text-primary-700'
                      : 'text-gray-700 hover:bg-gray-100 hover:text-gray-900'
                  }`}
                >
                  <item.icon className="w-5 h-5 mr-3" />
                  {item.name}
                </a>
              ))}
            </nav>

            <div className="border-t border-gray-200 p-4">
              <Button
                variant="ghost"
                onClick={handleSignOut}
                className="w-full justify-start text-red-600 hover:bg-red-50"
              >
                <LogOut className="w-5 h-5 mr-3" />
                Sair
              </Button>
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