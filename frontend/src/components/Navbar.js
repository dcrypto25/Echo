import React, { useState } from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import './Navbar.css';

const Navbar = ({ activeTab, setActiveTab }) => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleNavClick = (tab) => {
    setActiveTab(tab);
    setMobileMenuOpen(false); // Close mobile menu after selection
  };

  return (
    <nav className="navbar">
      <div className="container navbar-container">
        <div className="navbar-brand">
          <span className="logo-text">EchoForge</span>
          <span className="logo-badge">$ECHO</span>
        </div>

        {/* Desktop Menu */}
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
          {/* Mobile Menu Button */}
          <button
            className="mobile-menu-button"
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle menu"
          >
            <span className={`hamburger ${mobileMenuOpen ? 'open' : ''}`}>
              <span></span>
              <span></span>
              <span></span>
            </span>
          </button>
        </div>
      </div>

      {/* Mobile Menu Dropdown */}
      <div className={`mobile-menu ${mobileMenuOpen ? 'open' : ''}`}>
        <button
          className={`nav-item ${activeTab === 'dashboard' ? 'active' : ''}`}
          onClick={() => handleNavClick('dashboard')}
        >
          Dashboard
        </button>
        <button
          className={`nav-item ${activeTab === 'why-echo' ? 'active' : ''}`}
          onClick={() => handleNavClick('why-echo')}
        >
          Why ECHO
        </button>
        <button
          className={`nav-item ${activeTab === 'bond' ? 'active' : ''}`}
          onClick={() => handleNavClick('bond')}
        >
          Bond
        </button>
        <button
          className={`nav-item ${activeTab === 'stake' ? 'active' : ''}`}
          onClick={() => handleNavClick('stake')}
        >
          Stake
        </button>
        <button
          className={`nav-item ${activeTab === 'referral' ? 'active' : ''}`}
          onClick={() => handleNavClick('referral')}
        >
          Referrals
        </button>
        <button
          className={`nav-item ${activeTab === 'docs' ? 'active' : ''}`}
          onClick={() => handleNavClick('docs')}
        >
          Docs
        </button>
      </div>
    </nav>
  );
};

export default Navbar;
