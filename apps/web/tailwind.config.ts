import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        slate: {
          950: "#020617",
          900: "#0f172a",
          800: "#1e293b",
        },
        cyan: {
          400: "#22d3ee",
        },
        emerald: {
          400: "#34d399",
        },
        amber: {
          400: "#fbbf24",
        },
        rose: {
          500: "#f43f5e",
        },
      },
      fontFamily: {
        sans: ["var(--font-geist-sans)"],
        mono: ["var(--font-geist-mono)"],
      },
      boxShadow: {
        'cyan-glow': '0 0 15px rgba(34, 211, 238, 0.4)',
        'emerald-glow': '0 0 15px rgba(52, 211, 153, 0.4)',
        'amber-glow': '0 0 15px rgba(251, 191, 36, 0.4)',
      },
      keyframes: {
        scan: {
          '0%': { top: '0%', opacity: '0' },
          '10%': { opacity: '1' },
          '90%': { opacity: '1' },
          '100%': { top: '100%', opacity: '0' },
        },
        shimmer: {
          '0%': { transform: 'translateX(-100%)' },
          '100%': { transform: 'translateX(100%)' },
        },
        'pulse-slow': {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.6' },
        },
        'pulse-cyan': {
          '0%, 100%': { boxShadow: '0 0 15px rgba(34, 211, 238, 0.4)' },
          '50%': { boxShadow: '0 0 30px rgba(34, 211, 238, 0.8)' },
        },
      },
      animation: {
        scan: 'scan 4s linear infinite',
        shimmer: 'shimmer 2.5s infinite',
        'pulse-slow': 'pulse-slow 4s ease-in-out infinite',
        'pulse-cyan': 'pulse-cyan 2s ease-in-out infinite',
      },
    },
  },
  plugins: [],
};
export default config;
