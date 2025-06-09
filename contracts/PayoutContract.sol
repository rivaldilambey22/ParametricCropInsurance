// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./InsurancePolicyContract.sol";
import "./WeatherTriggerContract.sol";
import "./FarmFundPool.sol";

contract PayoutContract {
    InsurancePolicyContract  public insurance;
    WeatherTriggerContract public weatherData;
    FarmFundPool public fundPool;

    mapping(uint256 => bool) public claimed;

    event PayoutReleased(uint256 indexed policyId, address indexed farmer, uint256 amount);

    constructor(
        address insurancePolicyAddress,
        address weatherTriggerAddress,
        address farmFundPoolAddress
    ) {
        insurance = InsurancePolicyContract(insurancePolicyAddress);
        weatherData = WeatherTriggerContract(weatherTriggerAddress);
        fundPool = FarmFundPool(farmFundPoolAddress);
    }

    function verifyPayout(uint256 policyId)
        public
        view
        returns (
            bool eligible,
            address farmer,
            uint256 payoutAmount
        )
    {
        InsurancePolicyContract.Policy memory p = insurance.getPolicy(policyId);
        bool isEligible = weatherData.isEligible(policyId) &&
            p.farmer != address(0) &&
            !claimed[policyId];
        return (isEligible, p.farmer, p.payoutAmount);
    }

    function processPayout(uint256 policyId) external {
        (bool eligible, address farmer, uint256 payoutAmount) = verifyPayout(policyId);
        require(eligible, "Not eligible or already claimed");

        claimed[policyId] = true;
        fundPool.releasePayout(farmer, payoutAmount);

        emit PayoutReleased(policyId, farmer, payoutAmount);
    }
}
