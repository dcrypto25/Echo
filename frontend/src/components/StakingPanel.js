import React, { useState, useEffect } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { formatEther, parseEther } from 'ethers';
import { toast } from 'react-hot-toast';
import { CONTRACTS } from '../config/contracts';
import './StakingPanel.css';

const StakingPanel = () => {
  const { address, isConnected } = useAccount();
  const [stakeAmount, setStakeAmount] = useState('');
  const [unstakeAmount, setUnstakeAmount] = useState('');
  const [referrer, setReferrer] = useState('');

  // Fetch user data
  const { data: echoBalance } = useReadContract({
    address: CONTRACTS.ECHO.address,
    abi: CONTRACTS.ECHO.abi,
    functionName: 'balanceOf',
    args: [address],
    query: {
      enabled: !!address,
    },
  });

  const { data: stakedBalance } = useReadContract({
    address: CONTRACTS.Staking.address,
    abi: CONTRACTS.Staking.abi,
    functionName: 'getStakedBalance',
    args: [address],
    query: {
      enabled: !!address,
    },
  });

  const { data: pendingRewards } = useReadContract({
    address: CONTRACTS.Staking.address,
    abi: CONTRACTS.Staking.abi,
    functionName: 'getPendingRewards',
    args: [address],
    query: {
      enabled: !!address,
    },
  });

  const { data: unstakePenalty } = useReadContract({
    address: CONTRACTS.Staking.address,
    abi: CONTRACTS.Staking.abi,
    functionName: 'calculateUnstakePenalty',
    args: [parseEther(unstakeAmount || '0')],
    query: {
      enabled: !!unstakeAmount && unstakeAmount !== '0',
    },
  });

  // Write contract hooks
  const { writeContract: approve, data: approveHash, isPending: isApprovePending } = useWriteContract();
  const { isLoading: isApproving } = useWaitForTransactionReceipt({ hash: approveHash });

  const { writeContract: stake, data: stakeHash, isPending: isStakePending } = useWriteContract();
  const { isLoading: isStaking, isSuccess: isStakeSuccess } = useWaitForTransactionReceipt({
    hash: stakeHash,
  });

  const { writeContract: requestUnstake, data: requestUnstakeHash, isPending: isRequestUnstakePending } = useWriteContract();
  const { isLoading: isRequestingUnstake, isSuccess: isRequestUnstakeSuccess } = useWaitForTransactionReceipt({
    hash: requestUnstakeHash,
  });

  const { writeContract: claim, data: claimHash, isPending: isClaimPending } = useWriteContract();
  const { isLoading: isClaiming, isSuccess: isClaimSuccess } = useWaitForTransactionReceipt({
    hash: claimHash,
  });

  const { writeContract: compound, data: compoundHash, isPending: isCompoundPending } = useWriteContract();
  const { isLoading: isCompounding, isSuccess: isCompoundSuccess } = useWaitForTransactionReceipt({
    hash: compoundHash,
  });

  // Handle success notifications
  useEffect(() => {
    if (isStakeSuccess) {
      toast.success('Successfully staked!');
      setStakeAmount('');
    }
  }, [isStakeSuccess]);

  useEffect(() => {
    if (isRequestUnstakeSuccess) {
      toast.success('Unstake requested! Cooldown: 1-7 days based on backing ratio.');
    }
  }, [isRequestUnstakeSuccess]);

  useEffect(() => {
    if (isClaimSuccess) {
      toast.success('Rewards claimed!');
    }
  }, [isClaimSuccess]);

  useEffect(() => {
    if (isCompoundSuccess) {
      toast.success('Rewards compounded!');
    }
  }, [isCompoundSuccess]);

  const handleStake = async () => {
    try {
      // First approve
      approve({
        address: CONTRACTS.ECHO.address,
        abi: CONTRACTS.ECHO.abi,
        functionName: 'approve',
        args: [CONTRACTS.Staking.address, parseEther(stakeAmount || '0')],
      });
    } catch (error) {
      toast.error(error.message || 'Transaction failed');
    }
  };

  // Auto-stake after approval succeeds
  useEffect(() => {
    if (approveHash && !isApproving && stakeAmount) {
      try {
        stake({
          address: CONTRACTS.Staking.address,
          abi: CONTRACTS.Staking.abi,
          functionName: 'stake',
          args: [parseEther(stakeAmount || '0'), referrer || '0x0000000000000000000000000000000000000000'],
        });
      } catch (error) {
        toast.error(error.message || 'Stake failed');
      }
    }
  }, [approveHash, isApproving]);

  if (!isConnected) {
    return (
      <div className="staking-panel">
        <div className="connect-prompt">
          <h2>Connect Wallet to Stake</h2>
          <p>Connect your wallet to start staking ECHO and earning rewards</p>
        </div>
      </div>
    );
  }

  return (
    <div className="staking-panel">
      <div className="panel-header">
        <h1>Stake ECHO</h1>
        <p>Stake ECHO to receive eECHO and earn dynamic APY (0-30,000% based on protocol health)</p>
      </div>

      <div className="staking-grid">
        <div className="staking-card">
          <h2>Your Position</h2>
          <div className="position-stats">
            <div className="position-stat">
              <span className="stat-label">ECHO Balance</span>
              <span className="stat-value">
                {echoBalance ? formatEther(echoBalance) : '0.00'}
              </span>
            </div>
            <div className="position-stat">
              <span className="stat-label">Staked (eECHO)</span>
              <span className="stat-value">
                {stakedBalance ? formatEther(stakedBalance) : '0.00'}
              </span>
            </div>
            <div className="position-stat">
              <span className="stat-label">Pending Rewards</span>
              <span className="stat-value">
                {pendingRewards ? formatEther(pendingRewards) : '0.00'}
              </span>
            </div>
          </div>

          <div className="reward-actions">
            <button
              className="btn btn-secondary"
              onClick={() => claim({
                address: CONTRACTS.Staking.address,
                abi: CONTRACTS.Staking.abi,
                functionName: 'claimRewards',
              })}
              disabled={isClaimPending || isClaiming}
            >
              {isClaiming ? 'Claiming...' : 'Claim Rewards'}
            </button>
            <button
              className="btn btn-primary"
              onClick={() => compound({
                address: CONTRACTS.Staking.address,
                abi: CONTRACTS.Staking.abi,
                functionName: 'compound',
              })}
              disabled={isCompoundPending || isCompounding}
            >
              {isCompounding ? 'Compounding...' : 'Compound'}
            </button>
          </div>
        </div>

        <div className="staking-card">
          <h2>Stake ECHO</h2>
          <div className="input-group">
            <label>Amount to Stake</label>
            <input
              type="number"
              placeholder="0.00"
              value={stakeAmount}
              onChange={(e) => setStakeAmount(e.target.value)}
            />
            <button
              className="max-btn"
              onClick={() => setStakeAmount(echoBalance ? formatEther(echoBalance) : '0')}
            >
              MAX
            </button>
          </div>

          <div className="input-group">
            <label>Referrer Address (Optional)</label>
            <input
              type="text"
              placeholder="0x..."
              value={referrer}
              onChange={(e) => setReferrer(e.target.value)}
            />
          </div>

          <button
            className="btn btn-primary btn-large"
            onClick={handleStake}
            disabled={!stakeAmount || isApproving || isStaking}
          >
            {isApproving ? 'Approving...' : isStaking ? 'Staking...' : 'Stake ECHO'}
          </button>
        </div>

        <div className="staking-card">
          <h2>Unstake</h2>
          <div className="input-group">
            <label>Amount to Unstake</label>
            <input
              type="number"
              placeholder="0.00"
              value={unstakeAmount}
              onChange={(e) => setUnstakeAmount(e.target.value)}
            />
            <button
              className="max-btn"
              onClick={() => setUnstakeAmount(stakedBalance ? formatEther(stakedBalance) : '0')}
            >
              MAX
            </button>
          </div>

          {unstakePenalty && (
            <div className="penalty-warning">
              <p>⚠️ Unstake Penalty: {formatEther(unstakePenalty)} ECHO</p>
              <small>Penalty varies from 0-75% based on backing ratio</small>
            </div>
          )}

          <button
            className="btn btn-secondary btn-large"
            onClick={() => requestUnstake({
              address: CONTRACTS.Staking.address,
              abi: CONTRACTS.Staking.abi,
              functionName: 'requestUnstake',
              args: [parseEther(unstakeAmount || '0')],
            })}
            disabled={isRequestUnstakePending || isRequestingUnstake || !unstakeAmount}
          >
            {isRequestingUnstake ? 'Requesting...' : 'Request Unstake (1-7 day cooldown)'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default StakingPanel;
