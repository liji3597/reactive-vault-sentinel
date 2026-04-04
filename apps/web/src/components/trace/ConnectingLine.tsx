'use client';

import { motion } from 'framer-motion';
import { clsx } from 'clsx';

export default function ConnectingLine({ active, orientation = 'horizontal' }: { active: boolean, orientation?: 'horizontal' | 'vertical' }) {
  const isHorizontal = orientation === 'horizontal';

  return (
    <div className={clsx(
      "flex items-center justify-center gap-2",
      isHorizontal ? "w-full flex-col" : "h-full flex-row"
    )}>
      <div className={clsx(
        "relative rounded-full overflow-hidden bg-slate-800",
        isHorizontal ? "w-full h-1" : "h-full w-1"
      )}>
        {active && (
          <motion.div 
            initial={isHorizontal ? { left: '-100%' } : { top: '-100%' }}
            animate={isHorizontal ? { left: '100%' } : { top: '100%' }}
            transition={{ repeat: Infinity, duration: 1.5, ease: "linear" }}
            className={clsx(
              "absolute from-transparent via-cyan-400 to-transparent",
              isHorizontal
                ? "top-0 bottom-0 w-1/2 bg-gradient-to-r"
                : "left-0 right-0 h-1/2 bg-gradient-to-b"
            )}
          />
        )}
      </div>
      
      {/* Particle Effect */}
      {active && (
        <div className={isHorizontal ? "flex gap-2" : "flex flex-col gap-2"}>
          {[1, 2, 3].map((i) => (
            <motion.div 
              key={i}
              initial={{ scale: 0, opacity: 0 }}
              animate={{ scale: [0, 1, 0], opacity: [0, 1, 0] }}
              transition={{ repeat: Infinity, duration: 1, delay: i * 0.2 }}
              className="w-1.5 h-1.5 rounded-full bg-cyan-400 shadow-[0_0_8px_#22d3ee]"
            />
          ))}
        </div>
      )}
    </div>
  );
}

