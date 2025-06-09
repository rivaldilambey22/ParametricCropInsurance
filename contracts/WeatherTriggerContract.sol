// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./InsurancePolicyContract.sol";

contract WeatherTriggerContract {
    address public validator;
    InsurancePolicyContract public insurance;

    uint256 public quorum = 3;
    uint256 public reportWindow = 1 days;

    struct OracleReport {
        uint256 timestamp;
        uint256 value;
    }

    mapping(uint256 => OracleReport[]) public weatherReports; // policyId => list of weather reports
    mapping(uint256 => bool) public eligiblePolicies;
    mapping(uint256 => bool) public triggered;

    event PolicyEligible(uint256 indexed policyId, address farmer, uint256 payout);
    event PolicyIneligible(uint256 indexed policyId, uint256 medianValue);
    event WeatherReported(uint256 indexed policyId, uint256 value, address reporter);

    modifier onlyValidator() {
        require(msg.sender == validator, "Not authorized");
        _;
    }

    constructor(address insurancePolicyAddress) {
        validator = msg.sender;
        insurance = InsurancePolicyContract(insurancePolicyAddress);
    }

    /// Called by off-chain Chainlink Functions node or trusted validator
    function reportWeather(uint256 policyId, uint256 observedIndex) external onlyValidator {
        require(!triggered[policyId], "Policy already evaluated");

        weatherReports[policyId].push(OracleReport(block.timestamp, observedIndex));
        emit WeatherReported(policyId, observedIndex, msg.sender);
    }

    /// Evaluates the weather report using median filter once quorum is reached
    function triggerPolicy(uint256 policyId) external onlyValidator {
        require(!triggered[policyId], "Already triggered");
        OracleReport[] storage reports = weatherReports[policyId];
        require(reports.length >= quorum, "Not enough oracle data");

        uint256[] memory values = new uint256[](reports.length);
        for (uint256 i = 0; i < reports.length; i++) {
            require(block.timestamp - reports[i].timestamp <= reportWindow, "Stale data");
            values[i] = reports[i].value;
        }

        // Sort and take median
        uint256 median = _median(values);
        InsurancePolicyContract.Policy memory p = insurance.getPolicy(policyId);
        triggered[policyId] = true;

        if (median >= p.indexLevel) {
            eligiblePolicies[policyId] = true;
            emit PolicyEligible(policyId, p.farmer, p.payoutAmount);
        } else {
            emit PolicyIneligible(policyId, median);
        }
    }

    function isEligible(uint256 policyId) external view returns (bool) {
        return eligiblePolicies[policyId];
    }

    function _median(uint256[] memory data) internal pure returns (uint256) {
        // Basic bubble sort (for demo purposes only)
        uint256 n = data.length;
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (data[j] > data[j + 1]) {
                    (data[j], data[j + 1]) = (data[j + 1], data[j]);
                }
            }
        }

        if (n % 2 == 1) {
            return data[n / 2];
        } else {
            return (data[n / 2 - 1] + data[n / 2]) / 2;
        }
    }
}
