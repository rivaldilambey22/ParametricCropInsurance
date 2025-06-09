// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockStablecoin is ERC20 {
    address public admin;

    constructor() ERC20("Mock USD Stablecoin", "USDT") {
    admin = msg.sender;
    _mint(msg.sender, 1_000_000 * 10 ** decimals());
}


    // Admin can mint more tokens if needed for simulation
    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "Only admin can mint");
        _mint(to, amount);
    }

    // Optionally allow burning tokens
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}
