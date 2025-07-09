'use client'

import { useState } from 'react'
import { Car, Mail, Lock, AlertCircle, ArrowLeft } from 'lucide-react'
import { useAuth } from '@/lib/hooks/useAuth'
import { Button } from '@/components/ui/Button'
import { Input } from '@/components/ui/Input'

interface LoginFormProps {
  onBack?: () => void
}

export function LoginForm({ onBack }: LoginFormProps) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const { signIn } = useAuth()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError('')

    try {
      await signIn(email, password)
    } catch (err) {
      setError('Erro ao fazer login. Verifique se o Supabase está configurado corretamente.')
    } finally {
      setLoading(false)
    }
  }

  const handleDemoLogin = (demoEmail: string) => {
    setEmail(demoEmail)
    setPassword('demo123')
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="max-w-md w-full mx-4">
        <div className="bg-white rounded-2xl shadow-xl p-8">
          {/* Back Button */}
          {onBack && (
            <button
              onClick={onBack}
              className="flex items-center text-gray-600 hover:text-gray-900 mb-6 transition-colors"
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Voltar
            </button>
          )}

          {/* Logo */}
          <div className="text-center mb-8">
            <div className="inline-flex items-center justify-center w-16 h-16 bg-primary-600 rounded-full mb-4">
              <Car className="w-8 h-8 text-white" />
            </div>
            <h1 className="text-3xl font-bold text-gray-900">DriveSync</h1>
            <p className="text-gray-600 mt-2">Sistema de Gestão de Frotas</p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-6">
            {error && (
              <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-center space-x-2">
                <AlertCircle className="w-5 h-5 text-red-500" />
                <span className="text-sm text-red-700">{error}</span>
              </div>
            )}

            <Input
              label="Email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="seu@email.com"
              required
            />

            <Input
              label="Senha"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />

            <Button
              type="submit"
              loading={loading}
              className="w-full"
              size="lg"
            >
              {loading ? 'Entrando...' : 'Entrar'}
            </Button>
          </form>

          {/* Demo credentials */}
          <div className="mt-8 p-4 bg-gray-50 rounded-lg">
            <p className="text-sm text-gray-600 mb-3 font-medium">Credenciais de demonstração:</p>
            <div className="space-y-3 text-sm">
              <div className="flex items-center justify-between">
                <div>
                  <strong className="text-gray-900">Administrador</strong><br />
                  <span className="text-gray-600">admin@manoelviana.rs.gov.br</span>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleDemoLogin('admin@manoelviana.rs.gov.br')}
                >
                  Usar
                </Button>
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <strong className="text-gray-900">Operador</strong><br />
                  <span className="text-gray-600">operador@manoelviana.rs.gov.br</span>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleDemoLogin('operador@manoelviana.rs.gov.br')}
                >
                  Usar
                </Button>
              </div>
              <div className="flex items-center justify-between">
                <div>
                  <strong className="text-gray-900">Motorista</strong><br />
                  <span className="text-gray-600">motorista@manoelviana.rs.gov.br</span>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => handleDemoLogin('motorista@manoelviana.rs.gov.br')}
                >
                  Usar
                </Button>
              </div>
            </div>
            <p className="text-xs text-gray-500 mt-3">
              Senha para todos: <code className="bg-gray-200 px-1 rounded">demo123</code>
            </p>
          </div>
        </div>

        {/* Footer */}
        <div className="text-center mt-8 text-sm text-gray-500">
          © 2025 DriveSync. Desenvolvido por Daniel Charao Machado
        </div>
      </div>
    </div>
  )
}