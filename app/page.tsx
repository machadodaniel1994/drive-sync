'use client'

import { useEffect, useState } from 'react'
import { useAuth } from '@/lib/hooks/useAuth'
import { LandingPage } from '@/components/LandingPage'
import { LoginForm } from '@/components/auth/LoginForm'
import { DashboardLayout } from '@/components/layout/DashboardLayout'
import { Dashboard } from '@/components/dashboard/Dashboard'
import { LoadingSpinner } from '@/components/ui/LoadingSpinner'

export default function Home() {
  const { user, loading } = useAuth()
  const [showLogin, setShowLogin] = useState(false)
  const [isConfigured, setIsConfigured] = useState(true)

  useEffect(() => {
    // Verificar se o Supabase está configurado
    const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL
    const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
    
    if (!supabaseUrl || !supabaseKey || supabaseUrl.includes('your-project') || supabaseKey.includes('your-anon-key')) {
      setIsConfigured(false)
    }
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  // Mostrar aviso se Supabase não estiver configurado
  if (!isConfigured) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="max-w-md w-full mx-4">
          <div className="bg-white rounded-2xl shadow-xl p-8 text-center">
            <div className="w-16 h-16 bg-yellow-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
              </svg>
            </div>
            <h1 className="text-2xl font-bold text-gray-900 mb-4">
              Configuração Necessária
            </h1>
            <p className="text-gray-600 mb-6">
              Para usar o DriveSync, você precisa configurar o Supabase primeiro.
            </p>
            <div className="bg-gray-50 rounded-lg p-4 text-left">
              <h3 className="font-semibold text-gray-900 mb-2">Passos:</h3>
              <ol className="text-sm text-gray-600 space-y-1">
                <li>1. Crie uma conta no <a href="https://supabase.com" target="_blank" className="text-blue-600 hover:underline">Supabase</a></li>
                <li>2. Crie um novo projeto</li>
                <li>3. Execute a migração do banco (arquivo SQL na pasta supabase/migrations)</li>
                <li>4. Configure as variáveis no arquivo .env.local</li>
              </ol>
            </div>
            <div className="mt-6">
              <button
                onClick={() => setShowLogin(true)}
                className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
              >
                Continuar Mesmo Assim (Demo)
              </button>
            </div>
          </div>
        </div>
      </div>
    )
  }

  if (!user) {
    if (showLogin) {
      return <LoginForm onBack={() => setShowLogin(false)} />
    }
    return <LandingPage onLoginClick={() => setShowLogin(true)} />
  }

  return (
    <DashboardLayout>
      <Dashboard />
    </DashboardLayout>
  )
}