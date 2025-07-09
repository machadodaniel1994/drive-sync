import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'DriveSync - Sistema de Gestão de Frotas',
  description: 'Sistema completo para gestão de frotas internas, desenvolvido para prefeituras e empresas.',
  keywords: ['gestão de frotas', 'prefeitura', 'transporte', 'motoristas', 'veículos'],
  authors: [{ name: 'Daniel Charao Machado' }],
  viewport: 'width=device-width, initial-scale=1',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="pt-BR">
      <body className={inter.className}>
        {children}
      </body>
    </html>
  )
}