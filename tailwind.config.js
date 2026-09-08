/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
      },
      animation: {
        'wave': 'wave 2.5s ease-in-out infinite',
        'glow-pulse': 'glow-pulse 3s max ease-in-out infinite alternate',
      },
      keyframes: {
        wave: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-4px)' },
        },
        'glow-pulse': {
          '0%': { opacity: '0.4', filter: 'blur(10px)' },
          '100%': { opacity: '0.8', filter: 'blur(15px)' },
        }
      }
    },
  },
  plugins: [],
}
