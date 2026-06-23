/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        bg: '#0A0A0A',
        card: '#171717',
        surface: '#222222',
        divider: '#2a2a2a',
        textSecondary: '#8E8E93',
      },
    },
  },
  plugins: [],
}
