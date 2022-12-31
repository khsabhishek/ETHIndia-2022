pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


interface IERC20 {
    function mint(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

contract borrow_downside is IUniswap{

    using SafeERC20 for IERC20;

    IERC20 public immutable synthetic_token;

    IUniswap UniswapV2Router02 = 0xb71c52BA5E0690A7cE3A0214391F4c03F5cbFB0d;

    AggregatorV3Interface internal priceFeed_ETH;
    AggregatorV3Interface internal priceFeed_synthetic;

    bool short_trade = false;
    bool long_trade = true;

    constructor(address _synthetic_token) public {
        synthetic_token = IERC20(_synthetic_token);
    }

    function split_amount()public payable {
        require(_amount != 0, "amount incorrect");

        _amount = msg.value;

        uint96 amount_part1 = _amount / 2; // Will remain eth
        uint96 amount_part2 = _amount / 2; // will convert to synthetic token

        require(synthetic_token.approve(address(UniswapV2Router02), amountIn), 'approve failed.');

        int deadline = block.timestamp + 100;
        address[] memory path = new address[](2);
        path[0] = IUniswap.WETH();
        path[1] = synthetic_tokenq;

        UniswapV2Router02.swapExactETHForTokens{value: amount_part2 }(0, path, address(this), deadline);

    } 

    function bid() public {
        
    }

    function get_price_feed_Address_ETH(address _address) public {
        priceFeed_ETH = AggregatorV3Interface(_address);
    }

    function get_price_feed_Address_Trinity(address _address) public {
        priceFeed_Trinity = AggregatorV3Interface(_address);
    }

    function getLatestPrice_for_eth() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed_ETH.latestRoundData();
        return price;
    }

    function getLatestPrice_for_Synthetic() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed_synthetic.latestRoundData();
        return price;
    }
}