// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function mint(address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Borrowing is Ownable {

    // User locks their tokens of X amount worth $Y
    // Corresponding stablecoin of worth $Y is minted and transferred to user

    AggregatorV3Interface internal priceFeed;

    IERC20 public Trinity; // our stablecoin

    struct BorrowerDetails {
        IERC20 tokenStaked;
        uint depositedAmount;
        uint borrowedAmount;
        bool hasBorrowed;
        bool hasDeposited;
    }

    mapping(address => BorrowerDetails) public borrowing;

    uint8 private LTV; // LTV is a percentage eg LTV = 60 is 60%, must be divided by 100 in calculations

    constructor(address _tokenAddress) {
        Trinity = IERC20(_tokenAddress);
        priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
    }

    /*
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    
    function depositTokens() payable external {
        require(msg.value > 0, "Cannot deposit zero tokens");
        require(!borrowing[msg.sender].hasDeposited, "Cannot deposit tokens twice in one loan");

        require(msg.sender.balance > 0, "You do not have sufficient balance to execute this transaction");

        borrowing[msg.sender].depositedAmount = msg.value;
        borrowing[msg.sender].hasDeposited = true;

        // since function is payable and is called by msg.sender on contract,
        // funds are transferred from msg.sender's wallet to contract address
    }

    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function lendTokens(address _borrower) external onlyOwner {
        require(_borrower != address(0), "Borrower cannot be zero address");
        require(borrowing[_borrower].hasDeposited, "Borrower must have deposited collateral before claiming loan");
        require(LTV != 0, "LTV must be set to non-zero value before providing loans");
        
        // Chainlink is integrated here to find price of deposited token in USD
        // getLatestPrice();

        uint tokenValueConversion = borrowing[_borrower].depositedAmount * 1; // dummy data

        // tokenValueConversion is in USD, and our stablecoin is pegged to USD in 1:1 ratio
        // Hence if tokenValueConversion = 1, then equivalent stablecoin tokens = tokenValueConversion

        uint tokensToLend = tokenValueConversion * LTV / 100;
        borrowing[_borrower].hasBorrowed = true;
        borrowing[_borrower].borrowedAmount = tokensToLend;

        Trinity.mint(_borrower, tokensToLend);
    }
    
    function setLTV(uint8 _LTV) external onlyOwner {
        LTV = _LTV;
    }
}