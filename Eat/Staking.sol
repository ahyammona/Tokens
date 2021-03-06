// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IERC20.sol";
import "./Ownable.sol";

contract Staking is Ownable {
    uint256 internal constant DISTRIBUTION_MULTIPLIER = 2**64;

    IBEP20 public token;

    mapping(address => uint256) public stakeValue;
    mapping(address => uint256) public stakerPayouts;

    
    uint256 public totalDistributions;
    uint256 public totalStaked;
    uint256 public totalStakers;
    uint256 public profitPerShare;
    uint256 private emptyStakeTokens;

    uint256 public startTime;

    event OnStake(address sender, uint256 amount);
    event OnUnstake(address sender, uint256 amount);
    event OnWithdraw(address sender, uint256 amount);
    event OnDistribute(address sender, uint256 amount);
    event Received(address sender, uint256 amount);
    event UpdateStartTime(uint256 timestamp);

    constructor (IBEP20 _token)  {
        token = _token;
    }

    modifier whenStakingActive {
        require(
            startTime != 0 && block.timestamp > startTime,
            "Staking not yet started."
        );
        _;
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        require(startTime == 0 || block.timestamp < startTime, "staking already active");
        startTime =_startTime;
        emit UpdateStartTime(_startTime);
    }
     function dividendsOf(address staker) public view returns (uint256) {
        uint256 divPayout = profitPerShare * stakeValue[staker];
        require(divPayout >= stakerPayouts[staker], "dividend calc overflow");

        return (divPayout - stakerPayouts[staker]) / DISTRIBUTION_MULTIPLIER;
    }

    function stake(uint256 amount) public whenStakingActive {
        require(
            token.balanceOf(msg.sender) >= amount,
            "Cannot stake more Eat than you hold unstaked."
        );
        if (stakeValue[msg.sender] == 0) totalStakers += 1;

        _addStake(amount);

        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Stake failed due to failed transfer."
        );

        emit OnStake(msg.sender, amount);
    }

    function unstake(uint256 amount) external whenStakingActive {
        require(
            stakeValue[msg.sender] >= amount,
            "Cannot unstake more Eat than you have staked."
        );

        withdraw(dividendsOf(msg.sender));

        if (stakeValue[msg.sender] == amount) totalStakers = totalStakers -= 1;

        totalStaked = totalStaked -= amount;
        stakeValue[msg.sender] = stakeValue[msg.sender] -= amount;
        stakerPayouts[msg.sender] = profitPerShare * stakeValue[msg.sender];

        token.approve(address(this), amount);

        require(
            token.transferFrom(address(this), msg.sender, amount),
            "Unstake failed due to failed transfer."
        );

        emit OnUnstake(msg.sender, amount);
    }

    function withdraw(uint256 amount) public payable whenStakingActive {
        require(
            dividendsOf(msg.sender) >= amount,
            "Cannot withdraw more dividends than you have earned."
        );

        stakerPayouts[msg.sender] =
            stakerPayouts[msg.sender] +
            amount *
            DISTRIBUTION_MULTIPLIER;
        payable(msg.sender).transfer(amount);
        emit OnWithdraw(msg.sender, amount);
    }

    function distribute() external payable {
        // Forward 6% to dev wallet
        uint256 split = (msg.value * 6) / 100;
        uint256 amount = msg.value - split;

        payable(owner()).transfer(split);

        if (amount > 0) {
            totalDistributions += amount;
            _increaseProfitPerShare(amount);
            emit OnDistribute(msg.sender, amount);
        }
    }

    function _addStake(uint256 _amount) internal {
        totalStaked += _amount;
        stakeValue[msg.sender] += _amount;

        uint256 payout = profitPerShare * _amount;
        stakerPayouts[msg.sender] = stakerPayouts[msg.sender] + payout;
    }

    function _increaseProfitPerShare(uint256 amount) internal {
        if (totalStaked != 0) {
            if (emptyStakeTokens != 0) {
                amount += emptyStakeTokens;
                emptyStakeTokens = 0;
            }
            profitPerShare += ((amount * DISTRIBUTION_MULTIPLIER) / totalStaked);
        } else {
            emptyStakeTokens += amount;
        }
    }

     receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}