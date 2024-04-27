// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity ^0.8.19;
// 2. Imports
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addresssToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        if( msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    constructor (address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    // 记录一下各位都fund的钱数，token都add到合约本身了
    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "you need to spend more ETH.");

        s_addresssToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            s_addresssToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        //这里不安全，失败处理不严谨
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_addresssToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }


    // private  更省gas
    function getAddressToAmountFunded(address fundingAddress) public view returns (uint256) {
        return s_addresssToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }

}

