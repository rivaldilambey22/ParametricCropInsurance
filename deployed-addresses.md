# 📄 Deployed Smart Contract Addresses (Polygon Amoy Testnet)

This file contains the verified smart contract addresses deployed for the blockchain-based parametric crop insurance system. The contracts are organized according to the system process flow.

| Contract Name              | Address                                      | Description                                     |
|---------------------------|----------------------------------------------|-------------------------------------------------|
| RegistrationContract       | 0xd29a65e16505e7f41b6e8f3556424c525cc4b531   | Manages registration of farmers, cooperatives, and insurers |
| InsurancePolicyContract    | 0xa25e12b299dc5a68f04c410fd6f5c224263682ce   | Issues ERC-721 policy tokens to insured farmers |
| WeatherTriggerContract     | 0xb5732c947b377757961c744e22b46a5c54630fae   | Listens for weather data to trigger payouts     |
| PayoutContract             | 0x143068b937be5a56f3a08fc146d9556ec3f5dfe0   | Validates and disburses parametric payouts      |
| FarmFundPool               | 0x2f8fd540428b9768c05a258de8bb9f7d0bfac135   | Manages cooperative-managed liquidity pools     |