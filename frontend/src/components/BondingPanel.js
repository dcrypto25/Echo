import React, { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { formatEther, parseEther } from 'ethers';
import { toast } from 'react-hot-toast';
import { CONTRACTS } from '../config/contracts';
import './BondingPanel.css';

const BondingPanel = () => {
  const { address, isConnected } = useAccount();
  const [ethAmount, setEthAmount] = useState('');

  // Fetch current price
  const { data: currentPrice } = useReadContract({
    address: CONTRACTS.BondingCurve.address,
    abi: CONTRACTS.BondingCurve.abi,
    functionName: 'getCurrentPrice',
  });

  // Calculate ECHO amount
  const { data: echoAmount } = useReadContract({
    address: CONTRACTS.BondingCurve.address,
    abi: CONTRACTS.BondingCurve.abi,
    functionName: 'getEchoAmount',
    args: [parseEther(ethAmount || '0'), '0x0000000000000000000000000000000000000000'],
    query: {
      enabled: !!ethAmount && ethAmount !== '0',
    },
  });

  const { data: totalSold } = useReadContract({
    address: CONTRACTS.BondingCurve.address,
    abi: CONTRACTS.BondingCurve.abi,
    functionName: 'totalEchoSold',
  });

  // Buy with ETH
  const { writeContract: buy, data: buyHash, isPending: isBuyPending } = useWriteContract();
  const { isLoading: isBuying, isSuccess: isBuySuccess } = useWaitForTransactionReceipt({
    hash: buyHash,
  });

  // Handle success notification
  useEffect(() => {
    if (isBuySuccess) {
      toast.success('Successfully purchased ECHO!');
      setEthAmount('');
    }
  }, [isBuySuccess]);

  if (!isConnected) {
    return (
      <div className="bonding-panel">
        <div className="connect-prompt">
          <h2>Connect Wallet to Bond</h2>
          <p>Connect your wallet to purchase ECHO via the bonding curve</p>
        </div>
      </div>
    );
  }

  const progress = totalSold ? (Number(formatEther(totalSold)) / 1000000) * 100 : 0;

  return (
    <div className="bonding-panel">
      <div className="panel-header">
        <h1>Bond ECHO</h1>
        <p>Purchase ECHO via exponential bonding curve - 100% fair launch</p>
      </div>

      <div className="bonding-grid">
        <div className="bonding-card">
          <h2>Bonding Curve Stats</h2>
          <div className="curve-stats">
            <div className="curve-stat">
              <span className="stat-label">Current Price</span>
              <span className="stat-value">
                ${currentPrice ? Number(formatEther(currentPrice)).toFixed(4) : '0.0000'}
              </span>
            </div>
            <div className="curve-stat">
              <span className="stat-label">Total Sold</span>
              <span className="stat-value">
                {totalSold ? Number(formatEther(totalSold)).toLocaleString(undefined, { maximumFractionDigits: 0 }) : '0'} / 1,000,000
              </span>
            </div>
          </div>

          <div className="progress-bar">
            <div className="progress-fill" style={{ width: `${progress}%` }}></div>
          </div>
          <div className="progress-label">{progress.toFixed(2)}% Sold</div>
        </div>

        <div className="bonding-card">
          <h2>Buy ECHO</h2>
          <div className="input-group">
            <label>ETH Amount</label>
            <input
              type="number"
              placeholder="0.00"
              value={ethAmount}
              onChange={(e) => setEthAmount(e.target.value)}
            />
          </div>

          {echoAmount && (
            <div className="preview">
              <div className="preview-row">
                <span>You will receive:</span>
                <span className="preview-value">
                  {formatEther(echoAmount)} ECHO
                </span>
              </div>
              <div className="preview-row">
                <span>Price per ECHO:</span>
                <span className="preview-value">
                  ${currentPrice ? Number(formatEther(currentPrice)).toFixed(4) : '0.0000'}
                </span>
              </div>
            </div>
          )}

          <button
            className="btn btn-primary btn-large"
            onClick={() => buy({
              address: CONTRACTS.BondingCurve.address,
              abi: CONTRACTS.BondingCurve.abi,
              functionName: 'buyWithETH',
              value: parseEther(ethAmount || '0'),
            })}
            disabled={isBuyPending || isBuying || !ethAmount}
          >
            {isBuying ? 'Purchasing...' : 'Buy ECHO with ETH'}
          </button>

          <div className="info-box">
            <h4>How the Bonding Curve Works:</h4>
            <ul>
              <li>Price increases exponentially with supply</li>
              <li>Early buyers get the best prices</li>
              <li>100% of funds go to treasury (backing)</li>
              <li>No team allocation, no pre-sale</li>
              <li>Completely fair launch</li>
            </ul>
          </div>
        </div>

        <div className="bonding-card">
          <h2>Price Chart</h2>
          <div className="chart-placeholder">
            <p>Price increases as more ECHO is sold</p>
            <div className="chart-visual">
              <div className="chart-line"></div>
            </div>
          </div>

          <div className="price-milestones">
            <h4>Price Milestones</h4>
            <div className="milestone">
              <span>25% Sold:</span>
              <span>$0.0156</span>
            </div>
            <div className="milestone">
              <span>50% Sold:</span>
              <span>$0.0225</span>
            </div>
            <div className="milestone">
              <span>75% Sold:</span>
              <span>$0.0306</span>
            </div>
            <div className="milestone">
              <span>100% Sold:</span>
              <span>$0.0400</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default BondingPanel;
