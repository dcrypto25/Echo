import React, { useState } from 'react';
import { WagmiProvider, createConfig, http } from 'wagmi';
import { arbitrum, arbitrumSepolia, hardhat } from 'viem/chains';
import { RainbowKitProvider, getDefaultConfig } from '@rainbow-me/rainbowkit';
import '@rainbow-me/rainbowkit/styles.css';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'react-hot-toast';

import Dashboard from './components/Dashboard';
import Navbar from './components/Navbar';
import StakingPanel from './components/StakingPanel';
import BondingPanel from './components/BondingPanel';
import ReferralPanel from './components/ReferralPanel';
import Docs from './components/Docs';
import WhyEcho from './components/WhyEcho';
import './App.css';

// Configure wagmi for local hardhat network
const wagmiConfig = getDefaultConfig({
  appName: 'EchoForge',
  projectId: 'echoforge-local-dev',
  chains: [hardhat, arbitrum, arbitrumSepolia],
  transports: {
    [hardhat.id]: http('http://127.0.0.1:8545'),
    [arbitrum.id]: http(),
    [arbitrumSepolia.id]: http(),
  },
});

const queryClient = new QueryClient();

function App() {
  const [activeTab, setActiveTab] = useState('dashboard');

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard />;
      case 'why-echo':
        return <WhyEcho />;
      case 'stake':
        return <StakingPanel />;
      case 'bond':
        return <BondingPanel />;
      case 'referral':
        return <ReferralPanel />;
      case 'docs':
        return <Docs />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <WagmiProvider config={wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <div className="App">
            <Navbar activeTab={activeTab} setActiveTab={setActiveTab} />

            <main className="main-content">
              <div className="container">
                {renderContent()}
              </div>
            </main>

            <footer className="footer">
              <div className="container">
                <p>EchoForge - The Unkillable Reserve Currency</p>
                <div className="footer-links">
                  <a onClick={() => setActiveTab('docs')} style={{ cursor: 'pointer' }}>
                    Docs
                  </a>
                  <a href="https://twitter.com/EchoForgeDAO" target="_blank" rel="noopener noreferrer">
                    Twitter
                  </a>
                  <a href="https://discord.gg/echoforge" target="_blank" rel="noopener noreferrer">
                    Discord
                  </a>
                  <a href="https://github.com/dcrypto25/Echo" target="_blank" rel="noopener noreferrer">
                    GitHub
                  </a>
                </div>
              </div>
            </footer>

            <Toaster
              position="bottom-right"
              toastOptions={{
                duration: 4000,
                style: {
                  background: '#1a1a2e',
                  color: '#fff',
                  border: '1px solid #00d4ff',
                },
              }}
            />
          </div>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default App;
