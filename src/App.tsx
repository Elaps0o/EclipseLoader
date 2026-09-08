import { useState, useEffect } from 'react';
import {
  Crosshair, Eye, Globe, Move, Users, Palette, Settings,
  Check, Clock, User, Fingerprint, Search
} from 'lucide-react';
import { cn } from './lib/utils';

const tabs = [
  { id: 'aimbot', label: 'aimbot', icon: Crosshair },
  { id: 'visuals', label: 'visuals', icon: Eye },
  { id: 'world', label: 'world', icon: Globe },
  { id: 'movement', label: 'movement', icon: Move },
  { id: 'players', label: 'players', icon: Users },
  { id: 'skins', label: 'skins', icon: Palette },
  { id: 'misc', label: 'miscellaneous', icon: Settings },
];

const CheckboxRow = ({ label, active, hasColor, colorClass, hasGear }: any) => (
  <div className="flex items-center justify-between py-1.5 px-2 hover:bg-purple-900/10 rounded transition-all cursor-pointer group">
    <div className="flex items-center gap-2">
      <div className={cn(
        "w-3.5 h-3.5 rounded-sm border flex items-center justify-center transition-all bg-black",
        active ? "border-purple-500 shadow-[0_0_8px_rgba(168,85,247,0.6)]" : "border-white/15 group-hover:border-purple-500/50"
      )}>
        {active && <Check className="w-2.5 h-2.5 text-purple-400" strokeWidth={3} />}
      </div>
      <span className={cn(
        "text-xs font-medium tracking-wide transition-colors",
        active ? "text-purple-100" : "text-neutral-400 group-hover:text-purple-200"
      )}>{label}</span>
    </div>
    <div className="flex items-center gap-2">
      {hasColor && <div className={cn("w-4 h-3 rounded shadow-sm border border-white/20 opacity-80 hover:opacity-100 transition-opacity", colorClass)} />}
      {hasGear && <Settings className="w-3.5 h-3.5 text-neutral-600 hover:text-purple-400 transition-colors" />}
    </div>
  </div>
);

const Section = ({ title, children }: { title: string, children: React.ReactNode }) => (
  <div className="mb-3 bg-[#0a0a0a] border border-white/5 rounded-lg overflow-hidden shrink-0 shadow-lg">
    <div className="px-3 py-1.5 border-b border-white/5 bg-gradient-to-r from-purple-900/20 to-transparent">
      <h3 className="text-[10px] uppercase tracking-wider text-purple-400 font-bold opacity-90">{title}</h3>
    </div>
    <div className="p-2 flex flex-col gap-0.5">
      {children}
    </div>
  </div>
);

export default function App() {
  const [activeTab, setActiveTab] = useState('visuals');
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => setSeconds(s => s + 1), 1000);
    return () => clearInterval(interval);
  }, []);

  const formatTime = (total: number) => {
    const h = Math.floor(total / 3600).toString().padStart(2, '0');
    const m = Math.floor((total % 3600) / 60).toString().padStart(2, '0');
    const s = (total % 60).toString().padStart(2, '0');
    return `${h}:${m}:${s}`;
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 sm:p-8 relative selection:bg-purple-500/30">
      {/* Ambient background glows */}
      <div className="absolute top-1/4 -left-32 w-96 h-96 bg-purple-700/10 rounded-full blur-[100px] pointer-events-none" />
      <div className="absolute bottom-1/4 -right-32 w-96 h-96 bg-purple-900/15 rounded-full blur-[120px] pointer-events-none" />

      {/* Main Window */}
      <div className="w-full max-w-5xl bg-[#111111]/95 backdrop-blur-xl border border-purple-500/20 rounded-2xl shadow-2xl flex flex-col overflow-hidden relative z-10 h-[85vh]">
        
        {/* Header */}
        <header className="flex items-center justify-between px-6 py-4 border-b border-purple-500/10 bg-black/40">
          
          {/* Logo with Wave & Blur Effect */}
          <div className="relative group flex items-center pr-8 border-r border-white/5">
            <div className="absolute -inset-2 bg-purple-600/40 blur-[15px] rounded-full animate-glow-pulse" />
            <div className="flex items-center gap-2 relative z-10 animate-wave">
              <Fingerprint className="w-6 h-6 text-purple-400" />
              <h1 className="text-2xl font-black tracking-widest text-transparent bg-clip-text bg-gradient-to-r from-purple-300 via-purple-500 to-purple-800 uppercase">
                Eclipse
              </h1>
            </div>
          </div>

          {/* Search Bar */}
          <div className="hidden md:flex flex-1 max-w-xs mx-6 relative group">
            <Search className="w-4 h-4 text-neutral-500 absolute left-3 top-1/2 -translate-y-1/2 group-focus-within:text-purple-400 transition-colors" />
            <input 
              type="text" 
              placeholder="search feature..."
              className="w-full bg-black/50 border border-white/5 rounded-full py-1.5 pl-9 pr-4 text-xs text-white placeholder-neutral-600 focus:outline-none focus:border-purple-500/50 focus:bg-purple-900/10 transition-all"
            />
          </div>

          {/* User & Session Status */}
          <div className="flex items-center gap-6">
            <div className="flex flex-col items-end">
              <div className="flex items-center gap-1.5 text-purple-400">
                <Clock className="w-3.5 h-3.5" />
                <span className="text-xs font-mono tracking-wider font-semibold">{formatTime(seconds)}</span>
              </div>
              <span className="text-[9px] text-neutral-500 uppercase tracking-widest">Session Active</span>
            </div>
            <div className="flex items-center gap-2 pl-6 border-l border-white/5">
              <div className="text-right hidden sm:block">
                <div className="text-xs font-medium text-white tracking-wide">@neurothyc</div>
                <div className="text-[9px] text-purple-400/80 uppercase tracking-wider">Premium</div>
              </div>
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-purple-600 to-black p-0.5 shadow-lg shadow-purple-900/20">
                <div className="w-full h-full bg-black rounded-full flex items-center justify-center">
                  <User className="w-4 h-4 text-purple-400" />
                </div>
              </div>
            </div>
          </div>
        </header>

        {/* Navigation Tabs */}
        <nav className="flex px-4 py-2 border-b border-white/5 overflow-x-auto custom-scroll shrink-0">
          {tabs.map(tab => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={cn(
                  "flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-medium transition-all mr-2 whitespace-nowrap",
                  isActive 
                    ? "bg-purple-600/10 text-purple-300 border border-purple-500/20 shadow-[inset_0_0_15px_rgba(168,85,247,0.1)]"
                    : "text-neutral-500 hover:text-neutral-300 hover:bg-white/5 border border-transparent"
                )}
              >
                <Icon className={cn("w-4 h-4", isActive ? "text-purple-400" : "")} />
                {tab.label}
              </button>
            );
          })}
        </nav>

        {/* Main Content Area */}
        <main className="flex flex-1 overflow-hidden h-full">
          {/* Options Grid */}
          <div className="flex-1 p-4 grid grid-cols-1 md:grid-cols-2 gap-4 overflow-y-auto custom-scroll">
            
            {/* Left Column */}
            <div className="flex flex-col">
              <Section title="Enemies">
                <CheckboxRow label="box esp" active hasColor colorClass="bg-purple-600" />
                <CheckboxRow label="name esp" hasGear />
                <CheckboxRow label="weapon esp" active hasColor colorClass="bg-pink-400" hasGear />
                <CheckboxRow label="health bar" />
                <CheckboxRow label="chams" active hasColor colorClass="bg-purple-800" hasGear />
                <CheckboxRow label="skeleton" hasColor colorClass="bg-neutral-400" hasGear />
                <CheckboxRow label="flags" />
                <CheckboxRow label="out of view arrow" active hasColor colorClass="bg-blue-500" hasGear />
              </Section>

              <Section title="Allies">
                <CheckboxRow label="box esp" active hasColor colorClass="bg-purple-900" />
                <CheckboxRow label="name esp" />
                <CheckboxRow label="weapon esp" hasColor colorClass="bg-pink-300" hasGear />
                <CheckboxRow label="health bar" />
              </Section>
            </div>

            {/* Right Column */}
            <div className="flex flex-col">
              <Section title="Shots">
                <CheckboxRow label="tracers" hasGear />
                <CheckboxRow label="bullet impacts" hasGear />
                <CheckboxRow label="shot info" hasGear />
                <CheckboxRow label="extrapolation chams" active hasColor colorClass="bg-blue-400" />
                <CheckboxRow label="penetration preview" active hasColor colorClass="bg-orange-400" />
                <CheckboxRow label="penetration trace" active hasColor colorClass="bg-green-400" />
                <CheckboxRow label="contact glow" active hasColor colorClass="bg-orange-500" />
              </Section>

              <Section title="Awareness">
                <CheckboxRow label="sound esp" hasGear />
                <CheckboxRow label="line of sight" hasGear />
              </Section>

              <Section title="Screen Flags">
                <CheckboxRow label="c4 state" />
                <CheckboxRow label="feature flags" active hasGear />
              </Section>
            </div>
          </div>

          {/* Right Preview Panel */}
          <div className="w-full max-w-[320px] bg-[#0c0c0c] border-l border-white/5 p-4 hidden lg:flex flex-col shrink-0">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-[10px] font-bold text-purple-400 tracking-widest uppercase">ESP Preview</h3>
            </div>
            <div className="flex-1 rounded-xl bg-gradient-to-b from-[#141414] to-[#0a0a0a] border border-white/5 flex items-center justify-center relative shadow-inner overflow-hidden">
               {/* Mock Grid Lines */}
               <div className="absolute inset-0 opacity-[0.03]" style={{ backgroundImage: 'linear-gradient(#fff 1px, transparent 1px), linear-gradient(90deg, #fff 1px, transparent 1px)', backgroundSize: '20px 20px' }}></div>
               
               {/* Character Model Placeholder */}
               <div className="relative w-40 h-64 border border-purple-500/40 rounded flex flex-col justify-end bg-purple-900/5 shadow-[0_0_30px_rgba(168,85,247,0.1)]">
                  <User className="w-32 h-32 text-neutral-800 absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2" />
                  
                  {/* Mock ESP details */}
                  <div className="absolute -top-5 left-0 w-full flex justify-between px-1">
                    <span className="text-[9px] text-white font-mono tracking-wider">TERRORIST</span>
                  </div>
                  
                  {/* Health Bar Mock */}
                  <div className="absolute -left-2 bottom-0 w-1 h-full bg-black/50 border border-white/10 rounded-full overflow-hidden p-[1px]">
                     <div className="w-full h-[85%] bg-green-500 rounded-full shadow-[0_0_5px_rgba(34,197,94,0.5)] mt-auto" />
                  </div>

                  {/* Weapon Mock */}
                  <div className="absolute -bottom-5 left-0 w-full flex justify-center">
                    <span className="text-[9px] text-purple-300 font-mono tracking-widest">AK-47</span>
                  </div>
               </div>
            </div>
          </div>
        </main>
      </div>
    </div>
  );
}
