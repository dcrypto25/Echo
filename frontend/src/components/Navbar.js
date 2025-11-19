import React from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import './Navbar.css';

const Navbar = ({ activeTab, setActiveTab }) => {
  return (
    <nav className="navbar">
      <div className="container navbar-container">
        <div className="navbar-brand">
          <span className="logo-text">EchoForge</span>
          <span className="logo-badge">$ECHO</span>
        </div>

        <div className="navbar-menu">
          <button
            className={`nav-item ${activeTab === 'dashboard' ? 'active' : ''}`}
            onClick={() => setActiveTab('dashboard')}
          >
            Dashboard
          </button>
          <button
            className={`nav-item ${activeTab === 'why-echo' ? 'active' : ''}`}
            onClick={() => setActiveTab('why-echo')}
          >
            Why ECHO
          </button>
          <button
            className={`nav-item ${activeTab === 'bond' ? 'active' : ''}`}
            onClick={() => setActiveTab('bond')}
          >
            Bond
          </button>
          <button
            className={`nav-item ${activeTab === 'stake' ? 'active' : ''}`}
            onClick={() => setActiveTab('stake')}
          >
            Stake
          </button>
          <button
            className={`nav-item ${activeTab === 'referral' ? 'active' : ''}`}
            onClick={() => setActiveTab('referral')}
          >
            Referrals
          </button>
          <button
            className={`nav-item ${activeTab === 'docs' ? 'active' : ''}`}
            onClick={() => setActiveTab('docs')}
          >
            Docs
          </button>
        </div>

        <div className="navbar-actions">
          <ConnectButton />
        </div>
      </div>
    </nav>
  );
};

export default Navbar;
