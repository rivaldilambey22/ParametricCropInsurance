// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MockStablecoin.sol";
import "./InsurancePolicyContract.sol";

contract FarmFundPool {
    MockStablecoin public usdt;
    InsurancePolicyContract public insurance;
    address public payoutContract;

    address public admin;
    uint256 public minimumCapitalReserve;

    mapping(address => uint256) public staked;
    mapping(address => uint256) public stakingTimestamp;
    mapping(address => uint256) public reward;
    mapping(address => uint256) public coopCollateral;

    event PremiumCollected(address indexed farmer, uint256 amount);
    event LoanDisbursed(address indexed coop, uint256 amount);
    event LoanRepaid(address indexed coop, uint256 amount);
    event InterestCollected(address indexed coop, uint256 amount);
    event RewardClaimed(address indexed investor, uint256 amount);
    event ServiceFeePaid(address indexed provider, uint256 amount);
    event PayoutExecuted(address indexed farmer, uint256 amount);
    event ReserveAdjusted(uint256 newMCR);
    event CollateralDeposited(address indexed coop, uint256 amount);
    event CollateralWithdrawn(address indexed coop, uint256 amount);

    constructor(
        address stablecoinAddress,
        address insurancePolicyAddress
    ) {
        usdt = MockStablecoin(stablecoinAddress); 
        insurance = InsurancePolicyContract(insurancePolicyAddress);
        admin = msg.sender;
    }

    function setPayoutContract(address payoutContractAddress) external onlyAdmin {
        require(payoutContract == address(0), "Already set");
        require(payoutContractAddress != address(0), "Invalid address");
        payoutContract = payoutContractAddress;
    }

    modifier onlyPayoutContract() {
        require(msg.sender == payoutContract, "Only payout contract");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    function getReserveBalance() external view returns (uint256) {
        return usdt.balanceOf(address(this));
    }

    modifier onlyInsuranceContract() {
    require(msg.sender == address(insurance), "Unauthorized");
    _;
}


    function collectPremium(uint256 premiumAmount) external {
    require(premiumAmount > 0, "Invalid amount");
    require(usdt.transferFrom(msg.sender, address(this), premiumAmount), "Transfer failed");
    emit PremiumCollected(msg.sender, premiumAmount);
}

    function stakeToken(uint256 stakeAmount) external {
        require(stakeAmount > 0, "Stake amount must be positive");
        require(usdt.transferFrom(msg.sender, address(this), stakeAmount), "Stake failed");
        staked[msg.sender] += stakeAmount;
        stakingTimestamp[msg.sender] = block.timestamp;
    }
    function calculateReward(address investor) public view returns (uint256) {
        if (staked[investor] == 0 || stakingTimestamp[investor] == 0) return 0;
        uint256 duration = block.timestamp - stakingTimestamp[investor];
    uint256 cappedDuration = duration > 30 days ? 30 days : duration;

    return (staked[investor] * cappedDuration) / 1 days / 100;
}


    function claimReward() external {
        uint256 r = calculateReward(msg.sender);
        require(r > 0, "No reward to claim");
        require(usdt.balanceOf(address(this)) >= r, "Insufficient pool for reward");
        usdt.transfer(msg.sender, r);
        reward[msg.sender] += r;
        stakingTimestamp[msg.sender] = block.timestamp;
        emit RewardClaimed(msg.sender, r);
    }

    function disburseLoan(address cooperativeAddress, uint256 loanAmount) external onlyAdmin {
        require(cooperativeAddress != address(0), "Invalid cooperative address");
        require(loanAmount > 0, "Amount must be positive");
        require(usdt.balanceOf(address(this)) >= loanAmount + minimumCapitalReserve, "MCR breached");
        require(coopCollateral[cooperativeAddress] >= loanAmount / 2, "Insufficient collateral"); // contoh rasio 50%
        usdt.transfer(cooperativeAddress, loanAmount);
        emit LoanDisbursed(cooperativeAddress, loanAmount);
    }

    function repayLoan(uint256 repaymentAmount) external {
        require(repaymentAmount > 0, "Repayment must be positive");
        require(usdt.transferFrom(msg.sender, address(this), repaymentAmount), "Repayment failed");
        emit LoanRepaid(msg.sender, repaymentAmount);
    }

    function releasePayout(address farmer, uint256 payoutAmount) external onlyPayoutContract {
        require(farmer != address(0), "Invalid farmer address");
        require(payoutAmount > 0, "Payout amount must be positive");
        require(usdt.balanceOf(address(this)) >= payoutAmount + minimumCapitalReserve, "Insufficient funds in pool");
        require(usdt.transfer(farmer, payoutAmount), "Transfer to farmer failed");
        emit PayoutExecuted(farmer, payoutAmount);
    }

    function autoAdjustReserve() external onlyAdmin {
        uint256 totalCoverage;
        for (uint256 i = 0; ; i++) {
            try insurance.getPolicy(i) returns (InsurancePolicyContract.Policy memory p) {
                totalCoverage += p.payoutAmount;
            } catch {
                break;
            }
        }
        minimumCapitalReserve = (totalCoverage * 30) / 100;
        emit ReserveAdjusted(minimumCapitalReserve);
    }

    function initializeReserve(uint256 initialCapitalReserve) external onlyAdmin {
        require(initialCapitalReserve > 0, "Initial reserve must be greater than zero");
        minimumCapitalReserve = initialCapitalReserve;
        emit ReserveAdjusted(initialCapitalReserve);
    }
}
