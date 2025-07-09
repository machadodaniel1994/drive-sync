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

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <LoadingSpinner size="lg" />
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