'use client'

import { 
  Car, 
  Users, 
  Calendar, 
  BarChart3, 
  Shield, 
  Smartphone,
  CheckCircle,
  ArrowRight,
  Phone,
  Mail,
  MapPin,
  Star,
  Zap,
  Globe,
  Clock
} from 'lucide-react'
import { Button } from './ui/Button'

interface LandingPageProps {
  onLoginClick: () => void
}

export function LandingPage({ onLoginClick }: LandingPageProps) {
  const features = [
    {
      icon: Users,
      title: 'Gestão de Motoristas',
      description: 'Controle completo da equipe com alertas de CNH, status e histórico de viagens.'
    },
    {
      icon: Car,
      title: 'Controle de Frota',
      description: 'Gerencie veículos, manutenções preventivas e quilometragem em tempo real.'
    },
    {
      icon: Calendar,
      title: 'Agendamento Inteligente',
      description: 'Sistema avançado de agendamento com validações automáticas e notificações.'
    },
    {
      icon: BarChart3,
      title: 'Relatórios Detalhados',
      description: 'Dashboards e relatórios completos para tomada de decisões estratégicas.'
    },
    {
      icon: Shield,
      title: 'Segurança Total',
      description: 'Dados protegidos com criptografia avançada e controle de acesso.'
    },
    {
      icon: Smartphone,
      title: 'Interface Moderna',
      description: 'Design responsivo e intuitivo, funciona perfeitamente em qualquer dispositivo.'
    }
  ]

  const benefits = [
    'Redução de 40% nos custos operacionais',
    'Aumento de 60% na eficiência da frota',
    'Controle total em tempo real',
    'Relatórios automáticos e precisos',
    'Manutenção preventiva inteligente',
    'Interface moderna e intuitiva'
  ]

  const testimonials = [
    {
      name: 'Maria Silva',
      role: 'Secretária de Saúde',
      city: 'Manoel Viana - RS',
      content: 'O DriveSync revolucionou nossa gestão de ambulâncias. Agora temos controle total e relatórios precisos.',
      rating: 5
    },
    {
      name: 'João Santos',
      role: 'Coordenador de Transporte',
      city: 'Alegrete - RS',
      content: 'Sistema intuitivo e completo. A equipe se adaptou rapidamente e os resultados foram imediatos.',
      rating: 5
    },
    {
      name: 'Ana Costa',
      role: 'Diretora Administrativa',
      city: 'São Borja - RS',
      content: 'Excelente custo-benefício. Recomendo para qualquer prefeitura que busca modernização.',
      rating: 5
    }
  ]

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="bg-white shadow-sm sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center py-4">
            <div className="flex items-center space-x-3">
              <div className="w-10 h-10 bg-primary-600 rounded-lg flex items-center justify-center">
                <Car className="w-6 h-6 text-white" />
              </div>
              <div>
                <h1 className="text-xl font-bold text-gray-900">DriveSync</h1>
                <p className="text-xs text-gray-500">Gestão Inteligente de Frotas</p>
              </div>
            </div>
            <div className="flex items-center space-x-4">
              <a href="#contato" className="text-gray-600 hover:text-primary-600 transition-colors">
                Contato
              </a>
              <Button onClick={onLoginClick}>
                Acessar Sistema
              </Button>
            </div>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="bg-gradient-to-br from-blue-50 to-indigo-100 py-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div>
              <div className="inline-flex items-center px-4 py-2 bg-blue-100 text-blue-800 rounded-full text-sm font-medium mb-6">
                <Zap className="w-4 h-4 mr-2" />
                Sistema Moderno de Gestão
              </div>
              <h1 className="text-5xl font-bold text-gray-900 mb-6 leading-tight">
                Gestão de Frotas
                <span className="text-primary-600 block">Inteligente e Moderna</span>
              </h1>
              <p className="text-xl text-gray-600 mb-8 leading-relaxed">
                Sistema completo para prefeituras e empresas gerenciarem suas frotas com 
                eficiência, segurança e controle total. Desenvolvido especialmente para 
                o setor público brasileiro.
              </p>
              <div className="flex flex-col sm:flex-row gap-4">
                <Button size="lg" onClick={onLoginClick}>
                  Testar Gratuitamente
                  <ArrowRight className="w-5 h-5 ml-2" />
                </Button>
                <Button variant="outline" size="lg">
                  <a href="#contato">Falar com Especialista</a>
                </Button>
              </div>
            </div>
            <div className="relative">
              <div className="bg-white rounded-2xl shadow-2xl p-8 transform rotate-3 hover:rotate-0 transition-transform duration-300">
                <div className="bg-primary-600 rounded-lg p-4 mb-6">
                  <div className="flex items-center justify-between text-white">
                    <span className="font-semibold">Dashboard DriveSync</span>
                    <div className="flex space-x-1">
                      <div className="w-3 h-3 bg-red-400 rounded-full"></div>
                      <div className="w-3 h-3 bg-yellow-400 rounded-full"></div>
                      <div className="w-3 h-3 bg-green-400 rounded-full"></div>
                    </div>
                  </div>
                </div>
                <div className="space-y-4">
                  <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <div className="flex items-center space-x-3">
                      <Users className="w-5 h-5 text-primary-600" />
                      <span className="font-medium">Motoristas Ativos</span>
                    </div>
                    <span className="text-2xl font-bold text-green-600">12</span>
                  </div>
                  <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <div className="flex items-center space-x-3">
                      <Car className="w-5 h-5 text-primary-600" />
                      <span className="font-medium">Veículos Disponíveis</span>
                    </div>
                    <span className="text-2xl font-bold text-green-600">8</span>
                  </div>
                  <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                    <div className="flex items-center space-x-3">
                      <Calendar className="w-5 h-5 text-primary-600" />
                      <span className="font-medium">Viagens Hoje</span>
                    </div>
                    <span className="text-2xl font-bold text-primary-600">15</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              Funcionalidades Completas
            </h2>
            <p className="text-xl text-gray-600 max-w-3xl mx-auto">
              Tudo que sua prefeitura precisa para uma gestão de frotas moderna, 
              eficiente e transparente.
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {features.map((feature, index) => (
              <div key={index} className="card hover:shadow-lg transition-shadow">
                <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mb-6">
                  <feature.icon className="w-6 h-6 text-primary-600" />
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-4">
                  {feature.title}
                </h3>
                <p className="text-gray-600 leading-relaxed">
                  {feature.description}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Benefits Section */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div>
              <h2 className="text-4xl font-bold text-gray-900 mb-6">
                Resultados Comprovados
              </h2>
              <p className="text-xl text-gray-600 mb-8">
                Prefeituras que utilizam o DriveSync relatam melhorias significativas 
                em eficiência, economia e controle operacional.
              </p>
              <div className="space-y-4">
                {benefits.map((benefit, index) => (
                  <div key={index} className="flex items-center space-x-3">
                    <CheckCircle className="w-6 h-6 text-green-500 flex-shrink-0" />
                    <span className="text-gray-700 font-medium">{benefit}</span>
                  </div>
                ))}
              </div>
            </div>
            <div className="card">
              <div className="text-center mb-8">
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <BarChart3 className="w-8 h-8 text-green-600" />
                </div>
                <h3 className="text-2xl font-bold text-gray-900 mb-2">
                  Prefeitura de Manoel Viana
                </h3>
                <p className="text-gray-600">Caso de Sucesso</p>
              </div>
              <div className="grid grid-cols-2 gap-6">
                <div className="text-center">
                  <div className="text-3xl font-bold text-primary-600 mb-2">40%</div>
                  <div className="text-sm text-gray-600">Redução de Custos</div>
                </div>
                <div className="text-center">
                  <div className="text-3xl font-bold text-green-600 mb-2">60%</div>
                  <div className="text-sm text-gray-600">Mais Eficiência</div>
                </div>
                <div className="text-center">
                  <div className="text-3xl font-bold text-purple-600 mb-2">100%</div>
                  <div className="text-sm text-gray-600">Controle Digital</div>
                </div>
                <div className="text-center">
                  <div className="text-3xl font-bold text-orange-600 mb-2">24/7</div>
                  <div className="text-sm text-gray-600">Monitoramento</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-gray-900 mb-4">
              O que nossos clientes dizem
            </h2>
            <p className="text-xl text-gray-600">
              Depoimentos reais de gestores públicos que transformaram suas frotas
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <div key={index} className="card">
                <div className="flex items-center mb-4">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 text-yellow-400 fill-current" />
                  ))}
                </div>
                <p className="text-gray-700 mb-6 italic">
                  "{testimonial.content}"
                </p>
                <div>
                  <div className="font-semibold text-gray-900">{testimonial.name}</div>
                  <div className="text-sm text-gray-600">{testimonial.role}</div>
                  <div className="text-sm text-primary-600">{testimonial.city}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-primary-600">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <h2 className="text-4xl font-bold text-white mb-6">
            Pronto para modernizar sua gestão de frotas?
          </h2>
          <p className="text-xl text-blue-100 mb-8 max-w-3xl mx-auto">
            Junte-se a centenas de prefeituras que já transformaram sua gestão 
            com o DriveSync. Teste gratuitamente por 30 dias.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button 
              size="lg" 
              variant="secondary"
              onClick={onLoginClick}
            >
              <Clock className="w-5 h-5 mr-2" />
              Teste Grátis por 30 Dias
            </Button>
            <Button 
              size="lg" 
              variant="outline"
              className="border-white text-white hover:bg-white hover:text-primary-600"
            >
              <Phone className="w-5 h-5 mr-2" />
              <a href="#contato">Agendar Demonstração</a>
            </Button>
          </div>
        </div>
      </section>

      {/* Contact Section */}
      <section id="contato" className="py-20 bg-gray-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
            <div>
              <h2 className="text-4xl font-bold text-gray-900 mb-6">
                Entre em Contato
              </h2>
              <p className="text-xl text-gray-600 mb-8">
                Nossa equipe está pronta para ajudar sua prefeitura a implementar 
                a solução ideal para gestão de frotas.
              </p>
              <div className="space-y-6">
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                    <Phone className="w-6 h-6 text-primary-600" />
                  </div>
                  <div>
                    <div className="font-semibold text-gray-900">Telefone</div>
                    <div className="text-gray-600">(55) 99999-0000</div>
                  </div>
                </div>
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                    <Mail className="w-6 h-6 text-primary-600" />
                  </div>
                  <div>
                    <div className="font-semibold text-gray-900">Email</div>
                    <div className="text-gray-600">contato@drivesync.com.br</div>
                  </div>
                </div>
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                    <MapPin className="w-6 h-6 text-primary-600" />
                  </div>
                  <div>
                    <div className="font-semibold text-gray-900">Endereço</div>
                    <div className="text-gray-600">Manoel Viana - RS</div>
                  </div>
                </div>
                <div className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center">
                    <Globe className="w-6 h-6 text-primary-600" />
                  </div>
                  <div>
                    <div className="font-semibold text-gray-900">Website</div>
                    <div className="text-gray-600">www.drivesync.com.br</div>
                  </div>
                </div>
              </div>
            </div>
            <div className="card">
              <h3 className="text-2xl font-bold text-gray-900 mb-6">
                Solicite uma Demonstração
              </h3>
              <form className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Nome Completo
                  </label>
                  <input
                    type="text"
                    className="input"
                    placeholder="Seu nome completo"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Email Institucional
                  </label>
                  <input
                    type="email"
                    className="input"
                    placeholder="seu@prefeitura.gov.br"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Prefeitura/Órgão
                  </label>
                  <input
                    type="text"
                    className="input"
                    placeholder="Nome da prefeitura"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Telefone
                  </label>
                  <input
                    type="tel"
                    className="input"
                    placeholder="(55) 99999-9999"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Mensagem
                  </label>
                  <textarea
                    rows={4}
                    className="input"
                    placeholder="Conte-nos sobre suas necessidades..."
                  ></textarea>
                </div>
                <Button type="submit" className="w-full">
                  Enviar Solicitação
                </Button>
              </form>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-gray-900 text-white py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center space-x-3 mb-4">
                <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
                  <Car className="w-5 h-5 text-white" />
                </div>
                <span className="text-xl font-bold">DriveSync</span>
              </div>
              <p className="text-gray-400 mb-4">
                Sistema completo de gestão de frotas para prefeituras e empresas.
              </p>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Produto</h4>
              <ul className="space-y-2 text-gray-400">
                <li><a href="#" className="hover:text-white transition-colors">Funcionalidades</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Preços</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Demonstração</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Suporte</h4>
              <ul className="space-y-2 text-gray-400">
                <li><a href="#" className="hover:text-white transition-colors">Documentação</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Treinamento</a></li>
                <li><a href="#contato" className="hover:text-white transition-colors">Contato</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-semibold mb-4">Empresa</h4>
              <ul className="space-y-2 text-gray-400">
                <li><a href="#" className="hover:text-white transition-colors">Sobre</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Blog</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Carreiras</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-gray-800 mt-8 pt-8 text-center text-gray-400">
            <p>© 2025 DriveSync. Desenvolvido por Daniel Charao Machado. Todos os direitos reservados.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}