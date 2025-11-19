import React from 'react';
import './WhyEcho.css';

const WhyEcho = () => {
  return (
    <div className="why-echo">
      <div className="hero-section-why">
        <h1>Why Do We Need ECHO?</h1>
        <p className="subtitle">The Fundamental Problem with Fiat-Pegged Stablecoins</p>
      </div>

      <div className="problem-section">
        <h2>The Stablecoin Illusion</h2>
        <p className="lead">
          Fiat-pegged stablecoins (USDC, USDT, DAI) have become essential to crypto due to their perceived "stability" compared to volatile assets like Bitcoin and Ether. Users are comfortable transacting with stablecoins believing they hold the same purchasing power today as tomorrow.
        </p>
        <div className="alert-box">
          <h3>⚠️ This is a dangerous fallacy.</h3>
          <p>
            Stablecoins are not stable—they're pegged to fiat currencies controlled by centralized government monetary policy that <strong>guarantee</strong> the depreciation of your purchasing power through inflation.
          </p>
        </div>
      </div>

      <div className="inflation-section">
        <h2>The Mathematics of Fiat Devaluation</h2>

        <div className="data-grid">
          <div className="data-card highlighted">
            <div className="data-number">96.5%</div>
            <div className="data-label">USD Purchasing Power Lost Since 1913</div>
            <div className="data-footnote">Source: Federal Reserve</div>
          </div>

          <div className="data-card highlighted">
            <div className="data-number">7.1%</div>
            <div className="data-label">US CPI Inflation (2021 Peak)</div>
            <div className="data-footnote">40-year high</div>
          </div>

          <div className="data-card highlighted">
            <div className="data-number">$8.9T</div>
            <div className="data-label">Money Printed 2020-2023</div>
            <div className="data-footnote">40% of all USD ever created</div>
          </div>

          <div className="data-card highlighted">
            <div className="data-number">2.5%</div>
            <div className="data-label">Fed's "Target" Inflation Rate</div>
            <div className="data-footnote">Guaranteed 50% loss over 28 years</div>
          </div>
        </div>

        <div className="inflation-formula">
          <h3>Compound Depreciation Formula</h3>
          <div className="formula-box">
            <code>
              Future Value = Present Value × (1 - inflation_rate)^years
            </code>
          </div>
          <div className="calculation-examples">
            <h4>What $1,000 USDC becomes:</h4>
            <table>
              <thead>
                <tr>
                  <th>Years</th>
                  <th>@ 2.5% Inflation</th>
                  <th>@ 4% Inflation</th>
                  <th>@ 7% Inflation</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>5 years</td>
                  <td>$881</td>
                  <td>$815</td>
                  <td>$696</td>
                </tr>
                <tr>
                  <td>10 years</td>
                  <td>$776</td>
                  <td>$664</td>
                  <td>$484</td>
                </tr>
                <tr>
                  <td>20 years</td>
                  <td>$603</td>
                  <td>$442</td>
                  <td>$235</td>
                </tr>
                <tr>
                  <td>30 years</td>
                  <td>$468</td>
                  <td>$294</td>
                  <td>$114</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div className="problem-list">
        <h2>The Centralization Problem</h2>
        <div className="problems-grid">
          <div className="problem-card">
            <div className="problem-icon">🏦</div>
            <h3>Government Control</h3>
            <p>Fiat currencies are controlled by central banks with political incentives to inflate. The Federal Reserve explicitly targets 2%+ annual depreciation.</p>
          </div>

          <div className="problem-card">
            <div className="problem-icon">🚫</div>
            <h3>Censorship Risk</h3>
            <p>USDC and USDT have frozen accounts at government request. Your "decentralized" stablecoins can be confiscated at any time.</p>
          </div>

          <div className="problem-card">
            <div className="problem-icon">🎭</div>
            <h3>Hidden Inflation</h3>
            <p>Official CPI understates real inflation. Actual cost increases in housing, healthcare, and education far exceed reported rates.</p>
          </div>

          <div className="problem-card">
            <div className="problem-icon">💸</div>
            <h3>Perpetual Printing</h3>
            <p>Modern monetary policy favors unlimited money creation. Since leaving the gold standard, USD supply increased 7,200%.</p>
          </div>
        </div>
      </div>

      <div className="solution-section">
        <h2>ECHO: A Mathematical Alternative</h2>
        <p className="lead">
          EchoForge provides Web3 with an alternative to centralized, censorable, depreciating stablecoin assets. Instead of pegging to dying fiat, ECHO is backed by <strong>real crypto assets</strong> and governed by <strong>immutable mathematics</strong>.
        </p>

        <div className="math-comparison">
          <div className="math-card stablecoin">
            <h3>Fiat Stablecoins</h3>
            <div className="math-content">
              <p><strong>Backing Model:</strong></p>
              <code>Value = $1 USD (depreciating)</code>

              <p><strong>Governance:</strong></p>
              <code>Centralized (USDC: Circle/Coinbase)</code>

              <p><strong>Long-term Value:</strong></p>
              <code>-2.5% to -7% annually (guaranteed loss)</code>

              <p><strong>Censorship Resistance:</strong></p>
              <code>None (freezable)</code>
            </div>
          </div>

          <div className="math-card echo">
            <h3>ECHO</h3>
            <div className="math-content">
              <p><strong>Backing Model:</strong></p>
              <code>Value = Treasury / Supply (crypto-backed)</code>

              <p><strong>Governance:</strong></p>
              <code>Decentralized DAO + Immutable Math</code>

              <p><strong>Long-term Value:</strong></p>
              <code>
                Growth via:
                <br/>• Bonding curve appreciation
                <br/>• Treasury yield (GMX/GLP 15-30%)
                <br/>• Buyback engine
                <br/>• Rebase rewards (0-30,000% APY)
              </code>

              <p><strong>Censorship Resistance:</strong></p>
              <code>Maximum (unstoppable smart contracts)</code>
            </div>
          </div>
        </div>
      </div>

      <div className="formulas-section">
        <h2>The Mathematical Superiority</h2>

        <div className="formula-card">
          <h3>1. Intrinsic Value Formula</h3>
          <div className="formula-box">
            <code>
              ECHO Value = (Treasury Assets) / (Circulating Supply)
              <br/><br/>
              Treasury Assets = ETH + Stablecoins + Yield Positions + ECHO
              <br/><br/>
              Minimum Backing: 50%
              <br/>
              Target Backing: 100%+
              <br/>
              Healthy Backing: 120%+
            </code>
          </div>
          <p className="formula-explanation">
            Unlike stablecoins tied to depreciating fiat, ECHO's value is mathematically guaranteed by its treasury reserves. At 100% backing, 1 ECHO is worth exactly 1 ECHO worth of crypto assets.
          </p>
        </div>

        <div className="formula-card">
          <h3>2. Dynamic Supply Regulation</h3>
          <div className="formula-box">
            <code>
              Rebase APY = f(backing_ratio)
              <br/><br/>
              APY = 0% when backing &lt; 80%
              <br/>
              APY = 5,000% at backing = 100%
              <br/>
              APY = 30,000% at backing ≥ 200%
              <br/><br/>
              Formula: APY = min(30000%, 5000% × (backing / 100%)^2)
            </code>
          </div>
          <p className="formula-explanation">
            Supply expansion is mathematically constrained by treasury health. High backing = aggressive growth. Low backing = automatic contraction. Self-regulating system prevents death spirals.
          </p>
        </div>

        <div className="formula-card">
          <h3>3. Treasury Growth Mechanics</h3>
          <div className="formula-box">
            <code>
              Treasury Growth Rate =
              <br/>  + Bond Sales (continuous)
              <br/>  + Transfer Tax (4-15% on all transfers)
              <br/>  + GMX/GLP Yield (15-30% on 30% of treasury)
              <br/>  + Trading Fees (bonding curve spread)
              <br/>  - Redemptions (max 2% supply/day)
              <br/>  - Insurance Payouts (crisis mode only)
              <br/><br/>
              Expected Growth: 20-50% annually in normal conditions
            </code>
          </div>
          <p className="formula-explanation">
            Multiple revenue streams ensure treasury grows even without new deposits. Yield compounds, buybacks restore health, and mathematical constraints prevent overextension.
          </p>
        </div>

        <div className="formula-card">
          <h3>4. Exponential Penalty Protection</h3>
          <div className="formula-box">
            <code>
              Unstake Penalty = 75% × ((120% - backing_ratio) / 70%)²
              <br/><br/>
              At 120% backing: 0% penalty (free exit)
              <br/>
              At 100% backing: 6.1% penalty (minimal friction)
              <br/>
              At 80% backing: 24.5% penalty (protection mode)
              <br/>
              At 50% backing: 75% penalty (crisis lockdown)
            </code>
          </div>
          <p className="formula-explanation">
            Exponential curve ensures capital efficiency when healthy while preventing bank runs during stress. 11.7x more efficient than OHM's linear model at 100% backing.
          </p>
        </div>
      </div>

      <div className="conclusion-section">
        <h2>The Choice is Clear</h2>
        <div className="final-comparison">
          <div className="comparison-col">
            <h3 className="bad-choice">❌ Fiat Stablecoins</h3>
            <ul>
              <li>Guaranteed depreciation (-2.5% to -7% annually)</li>
              <li>Centralized control and censorship</li>
              <li>No yield, no growth, only slow death</li>
              <li>Dependent on failing government policy</li>
              <li>Account freezing and confiscation risk</li>
            </ul>
          </div>

          <div className="comparison-col">
            <h3 className="good-choice">✓ ECHO</h3>
            <ul>
              <li>Mathematically-backed appreciation potential</li>
              <li>Decentralized governance + immutable code</li>
              <li>Multiple yield sources (15-30,000% APY range)</li>
              <li>Treasury growth independent of fiat</li>
              <li>Unstoppable smart contract execution</li>
            </ul>
          </div>
        </div>

        <div className="cta-box">
          <h3>Web3 Needs a Real Reserve Currency</h3>
          <p>
            ECHO provides the decentralized, crypto-native, mathematically-sound alternative that the ecosystem has been waiting for. Not pegged to dying fiat. Not controlled by governments. Not censorable by corporations.
          </p>
          <p className="highlight">
            <strong>Just pure mathematics, game theory, and decentralized trust.</strong>
          </p>
        </div>
      </div>
    </div>
  );
};

export default WhyEcho;
