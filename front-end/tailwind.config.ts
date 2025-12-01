import type { Config } from 'tailwindcss'

const config: Config = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        'casino-gold': '#d4af37',
        'casino-dark': '#0a0a0a',
        'casino-red': '#c41e3a',
        'casino-green': '#0d7d3d',
      },
      boxShadow: {
        'casino-gold': '0 0 20px rgba(212, 175, 55, 0.5)',
      },
    },
  },
  plugins: [],
}
export default config
