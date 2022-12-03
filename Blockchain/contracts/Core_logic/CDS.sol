pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

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


contract Cds_borrowing is SafeERC20{

    using SafeERC20 for IERC20;

    IERC20 public immutable Trinity_token;
    IERC20 public immutable option_token;

    uint256 public cds_count = 0;
    uint96 public withdraw_time = 86400; // 30 days limit

    mapping(address => mapping(uint96 => uint256)) public cds_member_token_amount_deposited; // address => index => amount
    // mapping(address => uint256) private cds_member_token_amount_count;
    mapping(address => uint96) public cds_member_index;
    mapping(address => mapping(uint96 => uint96)) public cds_member_timestamp_with_index; // address => index => timestamp



    constructor (address _trinity, address _cds, address _option) public {

        Trinity_token = IERC20(_trinity); // _trinity token contract address
        option_token = IERC(_option); // option token contract address

    }  

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    } 

    function deposit(uint256 _amount, uint96 _timeStamp ) public {
        require(_amount != 0, "Deposit amount should not be zero"); // check _amount not zero
        require(Trinity_token.balanceOf(msg.sender) >= _amount, "Insufficient balance with msg.sender"); // check if user has sufficient trinity token  

        uint256 amount_present_for_cds_member = cds_member_token_amount_count[msg.sender];

        if(amount_present_for_cds_member == 0) {
            cds_count = cds_count + 1;
            cds_member_index[msg.sender] = 0;

        }

        // cds_member_token_amount_count[msg.sender] = cds_count; 

        uint96 cds_member_index_count =  cds_member_index[msg.sender] + 1; // get index of msg.sender

        cds_member_token_amount_deposited[msg.sender][cds_member_index_count] = _amount; // store amount of msg.sender by index

        Trinity_token.transferFrom(msg.sender, address(this), _amount);(address(this), _amount); // transfer amount to this contract

    }

    function withdraw(address _to, uint256 _amount, uint96 _index) public  {
        require(_amount != 0, "Amount cannot be zero");
        require(_to != address(0) && isContract(_to) == false, "Invalid address");

        uint256 amount_deposited = cds_member_token_amount_deposited[msg.sender][_index]; // get amount deposited by msg.sender at _index value

        require(amount_deposited >= _amount, "amount is more than deposit amount"); // should have sufficient deposited amount to withdraw

        uint256 amount_remaining = amount_deposited - _amount; // get the remaining amount after withdraw

        uint96 timestamp_at_index = cds_member_timestamp_with_index[msg.sender][_index]; // get timestamp at particular index

        uint96 expiration_time = timestamp_at_index + withdraw_time; // calculate expiration time

        if(expiration_time <= block.timestamp) {
            Trinity_token.transferFrom(address(this), msg.sender, _amount); // transfer amount to msg.sender
        }
    }
}