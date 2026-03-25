import type { Metadata } from "next";
import "../styles/globals.css";
import { Providers } from "./providers";
import Sidebar from "@/components/layout/Sidebar";
import TopBar from "@/components/layout/TopBar";

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body className="font-sans bg-slate-950 text-white min-h-screen flex">
        <Providers>
          <Sidebar />
          <div className="flex-1 flex flex-col min-h-screen">
            <TopBar />
            <main className="flex-1 p-6 overflow-y-auto">
              {children}
            </main>
            <footer className="p-4 border-t border-slate-800 text-center text-slate-500 text-sm">
              <span className="inline-flex items-center gap-2">
                Powered by <span className="text-cyan-400 font-semibold">Reactive Network</span>
              </span>
            </footer>
          </div>
        </Providers>
      </body>
    </html>
  );
}
