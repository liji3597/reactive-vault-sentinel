'use client';

import { motion } from 'framer-motion';

export default function ConnectingLine({ active }: { active: boolean }) {
  return (
    <div className="w-full flex flex-col items-center gap-2">
      <div className="relative w-full h-1 bg-slate-800 rounded-full overflow-hidden">
        {active && (
          <motion.div 
            initial={{ left: '-100%' }}
            animate={{ left: '100%' }}
            transition={{ repeat: Infinity, duration: 1.5, ease: "linear" }}
            className="absolute top-0 bottom-0 w-1/2 bg-gradient-to-r from-transparent via-cyan-400 to-transparent"
          />
        )}
      </div>
      
      {/* Particle Effect */}
      {active && (
        <div className="flex gap-2">
          {[1, 2, 3].map((i) => (
            <motion.div 
              key={i}
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: [0, 1, 0], opacity: [0, 1, 0] }}
              transition={{ repeat: Infinity, duration: 1, delay: i * 0.2 }}
              className="w-1.5 h-1.5 rounded-full bg-cyan-400"
            />
          ))}
        </div>
      )}
    </div>
  );
}
