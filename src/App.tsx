import React, { useEffect, useState } from 'react'
import { useAuth } from './hooks/useAuth'
import { supabase } from './lib/supabase'
import type { Tenant } from './lib/supabase'
import { LandingPage } from './components/LandingPage'
import { LoginForm } from './components/LoginForm'
import { Layout } from './components/Layout'
import { Dashboard } from './components/Dashboard'
import { MotoristasList } from './components/MotoristasList'

function App() {
  const { user, loading } = useAuth()
  const [tenant, setTenant] = useState<Tenant | null>(null)
  const [currentView, setCurrentView] = useState('dashboard')
  const [showLogin, setShowLogin] = useState(false)

  useEffect(() => {
    if (user) {
      // Buscar dados do tenant - na implementação real, isso seria baseado no usuário
      const fetchTenant = async () => {
        const { data, error } = await supabase
          .from('tenants')
          .select('*')
          .limit(1)
          .single()

        if (data && !error) {
          setTenant(data)
        }
      }

      fetchTenant()
    }
  }, [user])

  // Simular roteamento simples
  useEffect(() => {
    const handleHashChange = () => {
      const hash = window.location.hash.substring(1)
      if (hash) {
        setCurrentView(hash)
      }
    }

    window.addEventListener('hashchange', handleHashChange)
    handleHashChange()

    return () => window.removeEventListener('hashchange', handleHashChange)
  }, [])

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Carregando...</p>
        </div>
      </div>
    )
  }

  if (!user) {
    if (showLogin) {
      return <LoginForm />
    }
    return <LandingPage onLoginClick={() => setShowLogin(true)} />
  }

  const renderContent = () => {
    switch (currentView) {
      case 'motoristas':
        return <MotoristasList />
      case 'dashboard':
      default:
        return tenant ? <Dashboard tenant={tenant} /> : <div>Carregando tenant...</div>
    }
  }

  return (
    <Layout tenant={tenant || undefined}>
      {renderContent()}
    </Layout>
  )
}

export default App