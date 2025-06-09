// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RegistrationContract {
address public admin;

mapping(address => bool) public registeredFarmers;
mapping(address => bool) public registeredInsurers;
mapping(address => bool) public registeredGovernment;
mapping(address => bool) public registeredTokenInvestors;
mapping(address => bool) public registeredCooperatives;
mapping(address => InsuranceProvider) public insuranceProviders;
mapping(address => Cooperative) public cooperatives;


enum CropType { PADI, JAGUNG, KEDELAI }

struct LandData {
    string farmLocation;
    string nik;
    uint256 landSizeInSquareMeters;
    CropType crop;
    string landCertificateURI;
    bool verified;
}

struct InsuranceProvider {
    string agencyName;
    string region;
    bool active;
}

struct Cooperative {
    string name;
    string region;
    bool active;
}


mapping(address => LandData) public landInfo;

event FarmerRegistered(address indexed farmer);
event InsurerRegistered(address indexed insurer);
event GovernmentRegistered(address indexed gov);
event TokenInvestorRegistered(address indexed investor);
event CooperativeRegistered(address indexed coop);
event LandDataSubmitted(address indexed farmer, string farmLocation, uint256 landSizeInSquareMeters, string nik, CropType crop, string landCertificateURI);
event LandDataVerified(address indexed farmer);

constructor() {
    admin = msg.sender;
}

modifier onlyAdmin() {
    require(msg.sender == admin, "Only admin");
    _;
}

modifier onlyGovernment() {
    require(registeredGovernment[msg.sender], "Only government agency");
    _;
}

    function registerFarmer(
    address farmerAddress,
    string memory farmLocation,
    string memory nik,
    uint256 landSizeInSquareMeters,
    CropType crop,
    string memory landCertificateURI
) external {
    require(!registeredFarmers[farmerAddress], "Farmer already registered");
    require(bytes(farmLocation).length > 0, "Location required");
    require(landSizeInSquareMeters > 0, "Land size must be positive");
    require(bytes(landCertificateURI).length > 0, "Certificate required");

    landInfo[farmerAddress] = LandData({
        farmLocation: farmLocation,
        nik: nik,
        landSizeInSquareMeters: landSizeInSquareMeters,
        crop: crop,
        landCertificateURI: landCertificateURI,
        verified: false
    });

    registeredFarmers[farmerAddress] = true;

    emit FarmerRegistered(farmerAddress);
    emit LandDataSubmitted(farmerAddress, farmLocation, landSizeInSquareMeters, nik, crop, landCertificateURI);
}

    function verifyLandData(address farmer) external onlyGovernment {
        require(registeredFarmers[farmer], "Farmer not registered");
        require(bytes(landInfo[farmer].farmLocation).length > 0, "No land data submitted");
        require(!landInfo[farmer].verified, "Already verified");
        landInfo[farmer].verified = true;
        emit LandDataVerified(farmer);
    }

function getLandSizeInHectares(address farmer) external view returns (string memory location, uint256 sizeInHa) {
    require(registeredFarmers[farmer], "Farmer not registered");
    require(msg.sender == farmer || msg.sender == admin, "Unauthorized");
    return (landInfo[farmer].farmLocation, landInfo[farmer].landSizeInSquareMeters / 10000);
}

mapping(uint8 => string) public cropRegistry;
function setCropType(uint8 id, string memory name) external onlyAdmin {
    cropRegistry[id] = name;

}
function registInsuranceProvider(
    address insuranceProviderAddress,
    string memory agencyName,
    string memory region
) external onlyAdmin {
    require(!registeredInsurers[insuranceProviderAddress], "Already registered");

    registeredInsurers[insuranceProviderAddress] = true;
    insuranceProviders[insuranceProviderAddress] = InsuranceProvider({
        agencyName: agencyName,
        region: region,
        active: true
    });

    emit InsurerRegistered(insuranceProviderAddress);
}


function registGovernmentAgency(address govAddress) external onlyAdmin {
    registeredGovernment[govAddress] = true;
    emit GovernmentRegistered(govAddress);
}

function registTokenInvestor(address investorAddress) external onlyAdmin {
    registeredTokenInvestors[investorAddress] = true;
    emit TokenInvestorRegistered(investorAddress);
}

function registCooperative(
    address cooperativeAddress,
    string memory cooperativeName,
    string memory region
) external onlyAdmin {
    require(!registeredCooperatives[cooperativeAddress], "Already registered");

    registeredCooperatives[cooperativeAddress] = true;
    cooperatives[cooperativeAddress] = Cooperative({
        name: cooperativeName,
        region: region,
        active: true
    });

    emit CooperativeRegistered(cooperativeAddress);
}


function isFarmerEligible(address farmer) external view returns (bool) {
    return registeredFarmers[farmer] && landInfo[farmer].verified;
}
}