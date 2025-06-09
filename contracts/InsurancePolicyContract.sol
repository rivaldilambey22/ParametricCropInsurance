// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract InsurancePolicyContract is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _policyCounter;

    address public insuranceProvider;

    struct Policy {
        uint256 policyNumber;
        uint256 insurancePremium;
        uint256 insurancePeriodDays;
        uint256 payoutAmount;
        uint256 indexLevel;
        address farmer;
        bool active;
    }

    mapping(uint256 => Policy) public policies;

    event NewPolicyMinted(
        uint256 indexed policyId,
        uint256 policyNumber,
        uint256 premium,
        uint256 period,
        uint256 payout,
        uint256 indexLevel
    );

    event PolicyActivated(uint256 indexed policyId, address indexed farmer);

    modifier onlyInsuranceProvider() {
        require(msg.sender == insuranceProvider, "Only insurance provider");
        _;
    }

    constructor() ERC721("InsurancePolicyNFT", "IPNFT") {
        insuranceProvider = msg.sender;
    }

    function mintPolicy(
        uint256 insurancePremium,
        uint256 insurancePeriodDays,
        uint256 payoutAmount,
        uint256 indexLevel,
        string memory policyMetadataURI
    ) external onlyInsuranceProvider returns (uint256) {
        _policyCounter.increment();
        uint256 policyId = _policyCounter.current();

        _mint(address(this), policyId);
        _setTokenURI(policyId, policyMetadataURI);

        policies[policyId] = Policy({
            policyNumber: policyId,
            insurancePremium: insurancePremium,
            insurancePeriodDays: insurancePeriodDays,
            payoutAmount: payoutAmount,
            indexLevel: indexLevel,
            farmer: address(0),
            active: false
        });

        emit NewPolicyMinted(policyId, policyId, insurancePremium, insurancePeriodDays, payoutAmount, indexLevel);
        return policyId;
    }

    function activatePolicy(uint256 policyId, address farmer) external onlyInsuranceProvider {
        require(ownerOf(policyId) == address(this), "Policy already owned");
        require(!policies[policyId].active, "Policy already active");

        policies[policyId].farmer = farmer;
        policies[policyId].active = true;

        _transfer(address(this), farmer, policyId);

        emit PolicyActivated(policyId, farmer);
    }

    function getPolicy(uint256 policyId) external view returns (Policy memory) {
        return policies[policyId];
    }
}