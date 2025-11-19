import React, { useEffect, useState } from 'react';
import { useAccount, useReadContract } from 'wagmi';
import { formatEther } from 'ethers';
import { CONTRACTS } from '../config/contracts';
import './Dashboard.css';

const Dashboard = () => {
  const { address, isConnected } = useAccount();
  const [stats, setStats] = useState({
    totalSupply: '0',
    totalBurned: '0',
    stakingRatio: '0',
    backingRatio: '0',
    apy: '0',
    runway: '0',
    price: '0',
    nextRebase: '0',
  });

  // Fetch protocol stats
  const { data: totalSupply } = useReadContract({
    address: CONTRACTS.ECHO.address,
    abi: CONTRACTS.ECHO.abi,
    functionName: 'totalSupply',
  });

  const { data: totalBurned } = useReadContract({
    address: CONTRACTS.ECHO.address,
    abi: CONTRACTS.ECHO.abi,
    functionName: 'totalBurned',
  });

  const { data: stakingRatio } = useReadContract({
    address: CONTRACTS.Staking.address,
    abi: CONTRACTS.Staking.abi,
    functionName: 'getStakingRatio',
  });

  const { data: backingRatio } = useReadContract({
    address: CONTRACTS.Treasury.address,
    abi: CONTRACTS.Treasury.abi,
    functionName: 'getBackingRatio',
  });

  const { data: runway } = useReadContract({
    address: CONTRACTS.Treasury.address,
    abi: CONTRACTS.Treasury.abi,
    functionName: 'getRunway',
  });

  const { data: currentPrice } = useReadContract({
    address: CONTRACTS.BondingCurve.address,
    abi: CONTRACTS.BondingCurve.abi,
    functionName: 'getCurrentPrice',
  });

  const { data: nextRebaseTime } = useReadContract({
    address: CONTRACTS.eECHO.address,
    abi: CONTRACTS.eECHO.abi,
    functionName: 'nextRebaseTime',
  });

  const { data: currentAPY } = useReadContract({
    address: CONTRACTS.eECHO.address,
    abi: CONTRACTS.eECHO.abi,
    functionName: 'calculateDynamicAPY',
    args: [backingRatio || 10000],
  });

  useEffect(() => {
    if (totalSupply) setStats(prev => ({ ...prev, totalSupply: formatEther(totalSupply) }));
    if (totalBurned) setStats(prev => ({ ...prev, totalBurned: formatEther(totalBurned) }));
    if (stakingRatio) setStats(prev => ({ ...prev, stakingRatio: (Number(stakingRatio) / 100).toFixed(2) }));
    if (backingRatio) setStats(prev => ({ ...prev, backingRatio: (Number(backingRatio) / 100).toFixed(2) }));
    if (runway) setStats(prev => ({ ...prev, runway: runway.toString() }));
    if (currentPrice) setStats(prev => ({ ...prev, price: formatEther(currentPrice) }));
    if (currentAPY) setStats(prev => ({ ...prev, apy: (Number(currentAPY) / 100).toFixed(0) }));
    if (nextRebaseTime) {
      const timeUntil = Number(nextRebaseTime) - Math.floor(Date.now() / 1000);
      setStats(prev => ({ ...prev, nextRebase: Math.max(0, timeUntil).toString() }));
    }
  }, [totalSupply, totalBurned, stakingRatio, backingRatio, runway, currentPrice, nextRebaseTime, currentAPY]);

  const formatTime = (seconds) => {
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    return `${hrs}h ${mins}m ${secs}s`;
  };

  return (
    <div className="dashboard">
      <div className="hero-section">
        <h1 className="hero-title">
          <span className="gradient-text">EchoForge</span>
        </h1>
        <p className="hero-subtitle">Mathematically Optimized Reserve Currency</p>
        <p className="hero-description">Exponential penalty curves, dynamic APY, and multi-layer protection mechanisms ensure long-term sustainability. The future of money</p>
        <div className="hero-stats">
          <div className="hero-stat">
            <div className="stat-value">{stats.apy}%</div>
            <div className="stat-label">Current APY</div>
          </div>
          <div className="hero-stat">
            <div className="stat-value">{stats.stakingRatio}%</div>
            <div className="stat-label">Staking Ratio</div>
          </div>
          <div className="hero-stat">
            <div className="stat-value">{stats.backingRatio}%</div>
            <div className="stat-label">Backing Ratio</div>
          </div>
        </div>
      </div>

      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-card-header">
            <h3>Total Supply</h3>
          </div>
          <div className="stat-card-value">
            {Number(stats.totalSupply).toLocaleString(undefined, { maximumFractionDigits: 0 })} ECHO
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-card-header">
            <h3>Total Burned</h3>
          </div>
          <div className="stat-card-value">
            {Number(stats.totalBurned).toLocaleString(undefined, { maximumFractionDigits: 0 })} ECHO
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-card-header">
            <h3>Runway</h3>
          </div>
          <div className="stat-card-value">
            {stats.runway} Days
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-card-header">
            <h3>ECHO Price</h3>
          </div>
          <div className="stat-card-value">
            ${Number(stats.price).toFixed(4)}
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-card-header">
            <h3>Next Rebase</h3>
          </div>
          <div className="stat-card-value">
            {formatTime(Number(stats.nextRebase))}
          </div>
        </div>

        <div className="stat-card">
          <div className="stat-card-header">
            <h3>Circulating Supply</h3>
          </div>
          <div className="stat-card-value">
            {(Number(stats.totalSupply) - Number(stats.totalBurned)).toLocaleString(undefined, { maximumFractionDigits: 0 })} ECHO
          </div>
        </div>
      </div>

      <div className="features-section">
        <h2>Why EchoForge Wins Where Others Failed</h2>
        <div className="features-grid">
          <div className="feature-card highlighted">
            <div className="feature-icon">📈</div>
            <h3>Exponential Penalty Curve</h3>
            <p><strong>Always-present penalty protects protocol health.</strong> Mathematical formula: penalty = 75% × ((120% - ratio) / 70%)². Zero penalty at 120%+ backing, 6.1% at 100%, scaling exponentially to 75% at 50% crisis. Prevents bank runs while maintaining capital efficiency.</p>
          </div>

          <div className="feature-card highlighted">
            <div className="feature-icon">🔥</div>
            <h3>Dynamic APY (0-30,000%)</h3>
            <p><strong>Self-regulating APY based on treasury backing.</strong> Formula automatically adjusts rewards from 0% (crisis mode) to 30,000% (maximum growth) based on protocol health. Prevents death spirals through mathematical constraints on emissions.</p>
          </div>

          <div className="feature-card highlighted">
            <div className="feature-icon">🎯</div>
            <h3>Protocol Bonds (5% Discount)</h3>
            <p><strong>Conservative bond discounts prevent mercenary capital.</strong> Fixed 5% discount for long-term value accrual. All bond proceeds flow directly to treasury backing. Post-launch transitions to oracle-based pricing at -5% from market.</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">💰</div>
            <h3>Adaptive Transfer Tax (4-15%)</h3>
            <p><strong>Dual-asset treasury accumulation.</strong> Tax rate adjusts based on staking ratio (4% base, 15% max). Every transfer automatically swaps 50% to ETH, building diversified treasury backing in both ECHO and ETH. Continuous revenue stream independent of bond sales.</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">🛡️</div>
            <h3>Multi-Layer Protection</h3>
            <p><strong>Defense in depth against bank runs.</strong> 7-day unstake cooldown, redemption queue with max daily capacity, automated buyback engine, insurance vault, and exponential penalties. Each layer independently prevents death spirals.</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">⚖️</div>
            <h3>100% Fair Launch</h3>
            <p><strong>Zero team allocation, zero pre-sale, zero VCs.</strong> All ECHO distributed through exponential bonding curve. Pure price discovery with no insider advantages. DAO governance controls all upgradeable contracts.</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">🌳</div>
            <h3>10-Level Referral System</h3>
            <p><strong>Network effects through mathematical incentives.</strong> Tiered rewards (4-14%) distributed in rebasing eECHO. Each referral strengthens protocol TVL while rewarding organic growth.</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">🏦</div>
            <h3>Productive Treasury Assets</h3>
            <p><strong>Treasury generates yield independent of new deposits.</strong> 30% allocation to GMX/GLP for real yield. Diversified reserves in ETH, stablecoins, and yield-bearing positions. Compound growth on protocol backing.</p>
          </div>

          <div className="feature-card">
            <div className="feature-icon">⚡</div>
            <h3>Automated Rebalancing</h3>
            <p><strong>Emission balancer dynamically adjusts supply.</strong> When backing is healthy, system automatically expands money supply by minting and distributing ECHO. When backing drops, burns are initiated and faucet is turned off, until protocol is healthy once again.</p>
          </div>
        </div>
      </div>

      <div className="comparison-section">
        <h2>Protocol Comparison: Mathematical & Mechanism Superiority</h2>
        <div className="comparison-table-wide">
          <table>
            <thead>
              <tr>
                <th>Mechanism</th>
                <th>TIME</th>
                <th>OHM v1</th>
                <th className="echo-col">EchoForge</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td><strong>Unstake Penalty Formula</strong></td>
                <td className="bad">None (0%)</td>
                <td>Linear: (150% - ratio) / 70%</td>
                <td className="good"><strong>Exponential: 75% × ((120% - ratio) / 70%)²</strong></td>
              </tr>
              <tr>
                <td><strong>Penalty at 100% Backing</strong></td>
                <td className="bad">0% (bank run risk)</td>
                <td>71.4% (kills volume)</td>
                <td className="good"><strong>6.1% (11.7x more efficient)</strong></td>
              </tr>
              <tr>
                <td><strong>APY Model</strong></td>
                <td className="bad">Fixed 80,000% (death spiral)</td>
                <td>Fixed ~7,000% (inflexible)</td>
                <td className="good"><strong>Dynamic 0-30,000% (self-regulating)</strong></td>
              </tr>
              <tr>
                <td><strong>Bond Discounts</strong></td>
                <td className="bad">High (~10-15%)</td>
                <td>Variable 10-15% (mercenary capital)</td>
                <td className="good"><strong>Conservative 5% (long-term holders)</strong></td>
              </tr>
              <tr>
                <td><strong>Treasury Diversification</strong></td>
                <td>MIM only (single point failure)</td>
                <td>DAI-heavy (centralization risk)</td>
                <td className="good"><strong>ETH + Multi-stablecoin + Yield</strong></td>
              </tr>
              <tr>
                <td><strong>Automated Buybacks</strong></td>
                <td className="bad">None</td>
                <td className="bad">None</td>
                <td className="good"><strong>Emission Balancer (algorithmic)</strong></td>
              </tr>
              <tr>
                <td><strong>Redemption Queue</strong></td>
                <td className="bad">None</td>
                <td className="bad">None</td>
                <td className="good"><strong>Max 5% supply/day (prevents runs)</strong></td>
              </tr>
              <tr>
                <td><strong>Insurance Vault</strong></td>
                <td className="bad">None</td>
                <td className="bad">None</td>
                <td className="good"><strong>Dedicated reserves for crisis</strong></td>
              </tr>
              <tr>
                <td><strong>Referral System</strong></td>
                <td className="bad">None</td>
                <td className="bad">None</td>
                <td className="good"><strong>10-level referral tree</strong></td>
              </tr>
              <tr>
                <td><strong>Transfer Tax Revenue</strong></td>
                <td className="bad">None</td>
                <td className="bad">None</td>
                <td className="good"><strong>4-15% adaptive (continuous income)</strong></td>
              </tr>
              <tr>
                <td><strong>Fair Launch</strong></td>
                <td className="bad">Team allocation (dump risk)</td>
                <td>Fair (but no bonding curve)</td>
                <td className="good"><strong>100% bonding curve (pure discovery)</strong></td>
              </tr>
              <tr>
                <td><strong>Unstake Cooldown</strong></td>
                <td className="bad">None (instant bank runs)</td>
                <td>Warmup only</td>
                <td className="good"><strong>Dynamic cooldown (1 day @ 120%, 7 days @ 50%) + exponential penalty (0-75%)</strong></td>
              </tr>
            </tbody>
          </table>
        </div>
        <div className="comparison-footer">
          <p><strong>Result:</strong> EchoForge implements 8+ protective mechanisms and mathematical improvements that previous reserve currencies lacked. Every mechanism is battle-tested game theory, designed to prevent the specific failure modes that killed TIME and damaged OHM. This is not an iteration—this is the future of currency.</p>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
