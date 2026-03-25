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
      },
    },
  },
  plugins: [],
};
export default config;
