import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Casino Royale',
  description: 'Premium online casino experience',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
