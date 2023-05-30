// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6 <0.9.0;

// importing chainlink data agregator interface (ABI) to get crypto prices
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * Network: Sepolia
 * Aggregator: ETH/USD
 * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
 */

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;

    // what we add to the constructor is immediately executed during the deploument

    address payable public owner;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        owner = payable(msg.sender);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function fund() public payable {
        // minimum amount of usd (multiplied by 10^8) required for sending
        uint256 minUSD = 50 * 10 ** 8;
        require(
            getConversionRate(msg.value) >= minUSD,
            "You have to spend more ETH"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // ETH -> USD conversion rate
    function getPrice() public view returns (uint256) {
        // we make blank variables in the tuple below not to store all returned data from the aggregator
        (, int256 answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer);
    }

    // cost of a particular amount of ETH in WEI
    function getConversionRate(
        uint256 weiAmount
    ) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 weiAmountInUsd = (ethPrice * weiAmount) / 10 ** 18;
        return weiAmountInUsd;
    }

    // return minimum amount of WEI to fund the contract
    function getEntranceFee() public view returns (uint256) {
        // minimum USD
        uint256 minimumUSD = 50 * 10 ** 8;
        uint256 price = getPrice();
        uint256 precision = 1 * 10 ** 18;
        return (minimumUSD * precision) / price;
    }

    // require that the owner only can withdraw money
    modifier onlyOwner() {
        require(msg.sender == owner, "The owner only can withdraw funds!");
        _; // underscore denotes when the function to which we apply the modifier will be executed, in this case we will at first check the requirement and then execute function
    }

    // we apply "onlyOwner" modifier to this function
    function withdraw() public payable onlyOwner {
        // converting msg.sender to the payable address to run the transfer below
        address payable paybleMsgAddr = payable(msg.sender);

        // transfer money from the contract balance to my account
        // keywrod "this" is used to denote this contracrt address
        paybleMsgAddr.transfer(address(this).balance);

        //reset all fundings to 0 after withdrawal
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        funders = new address[](0);
    }
}
