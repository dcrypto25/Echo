import React, { useState } from 'react';
import { useAccount, useReadContract } from 'wagmi';
import { formatEther } from 'ethers';
import { toast } from 'react-hot-toast';
import { CONTRACTS } from '../config/contracts';
import './ReferralPanel.css';

const ReferralPanel = () => {
  const { address, isConnected } = useAccount();

  // Fetch referral data
  const { data: referralData } = useReadContract({
    address: CONTRACTS.Referral.address,
    abi: CONTRACTS.Referral.abi,
    functionName: 'getReferralData',
    args: [address],
    query: {
      enabled: !!address,
    },
  });

  const { data: directReferrals } = useReadContract({
    address: CONTRACTS.Referral.address,
    abi: CONTRACTS.Referral.abi,
    functionName: 'getDirectReferrals',
    args: [address],
    query: {
      enabled: !!address,
    },
  });

  const referralLink = `https://app.echoforge.finance?ref=${address}`;

  const copyReferralLink = () => {
    navigator.clipboard.writeText(referralLink);
    toast.success('Referral link copied!');
  };

  if (!isConnected) {
    return (
      <div className="referral-panel">
        <div className="connect-prompt">
          <h2>Connect Wallet to View Referrals</h2>
          <p>Connect your wallet to access your referral dashboard</p>
        </div>
      </div>
    );
  }

  const bonusRates = [
    { level: 'L1 (Direct)', rate: '4%' },
    { level: 'L2', rate: '2%' },
    { level: 'L3-L10', rate: '1% each' },
  ];

  return (
    <div className="referral-panel">
      <div className="panel-header">
        <h1>Referral Dashboard</h1>
        <p>Share your link and earn up to 14% of referee stakes as rebasing eECHO</p>
      </div>

      <div className="referral-grid">
        <div className="referral-card large">
          <h2>Your Referral Link</h2>
          <div className="referral-link-box">
            <input
              type="text"
              value={referralLink}
              readOnly
              className="referral-link-input"
            />
            <button className="btn btn-primary" onClick={copyReferralLink}>
              Copy Link
            </button>
          </div>

          <div className="social-share">
            <h4>Share on:</h4>
            <div className="social-buttons">
              <button className="social-btn twitter">
                Twitter
              </button>
              <button className="social-btn telegram">
                Telegram
              </button>
              <button className="social-btn discord">
                Discord
              </button>
            </div>
          </div>
        </div>

        <div className="referral-card">
          <h2>Your Stats</h2>
          <div className="referral-stats">
            <div className="referral-stat">
              <span className="stat-icon">👥</span>
              <div className="stat-info">
                <span className="stat-label">Direct Referrals</span>
                <span className="stat-value">
                  {directReferrals ? directReferrals.length : '0'}
                </span>
              </div>
            </div>

            <div className="referral-stat">
              <span className="stat-icon">💰</span>
              <div className="stat-info">
                <span className="stat-label">Total Earned</span>
                <span className="stat-value">
                  {referralData ? formatEther(referralData.totalEarned) : '0.00'} eECHO
                </span>
              </div>
            </div>

            <div className="referral-stat">
              <span className="stat-icon">📊</span>
              <div className="stat-info">
                <span className="stat-label">Referral Volume</span>
                <span className="stat-value">
                  {referralData ? Number(formatEther(referralData.totalReferralVolume)).toLocaleString(undefined, { maximumFractionDigits: 0 }) : '0'} ECHO
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="referral-card">
          <h2>Referral Structure</h2>
          <div className="referral-structure">
            {bonusRates.map((bonus, index) => (
              <div key={index} className="bonus-row">
                <span className="bonus-level">{bonus.level}</span>
                <span className="bonus-rate">{bonus.rate}</span>
              </div>
            ))}
            <div className="bonus-total">
              <strong>Total Maximum:</strong>
              <strong>14%</strong>
            </div>
          </div>

          <div className="info-box">
            <h4>💎 How It Works:</h4>
            <p>You receive eECHO based on % of referee's stake. This eECHO rebases automatically alongside their stake!</p>
          </div>
        </div>

        <div className="referral-card large">
          <h2>How Referrals Work</h2>
          <div className="how-it-works">
            <div className="step">
              <div className="step-number">1</div>
              <div className="step-content">
                <h4>Share Your Link</h4>
                <p>Copy your unique referral link and share it with friends</p>
              </div>
            </div>

            <div className="step">
              <div className="step-number">2</div>
              <div className="step-content">
                <h4>They Stake</h4>
                <p>When someone stakes using your link, you earn bonuses</p>
              </div>
            </div>

            <div className="step">
              <div className="step-number">3</div>
              <div className="step-content">
                <h4>Earn eECHO Rewards</h4>
                <p>Receive 4-14% of their stake as rebasing eECHO (up to 10 levels deep)</p>
              </div>
            </div>

            <div className="step">
              <div className="step-number">4</div>
              <div className="step-content">
                <h4>Automatic Rebasing</h4>
                <p>Your referral eECHO grows at the same rate as their stake, compounding forever</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ReferralPanel;
