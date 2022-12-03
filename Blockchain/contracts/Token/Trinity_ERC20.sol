// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts@4.8.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.8.0/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@4.8.0/security/Pausable.sol";
import "@openzeppelin/contracts@4.8.0/access/Ownable.sol";

contract TrinityStablecoin is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("Trinity", "TR") {
        whitelist[msg.sender] = true;
    }

    mapping(address => bool) public whitelist;

    function addToWhitelist(address _whitelistAddress) external onlyOwner {
        whitelist[_whitelistAddress] = true;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
    
    modifier onlyWhitelist() {
        require(whitelist[msg.sender] == true, "Caller is not whitelisted to call this function");
        _;
    }
}
