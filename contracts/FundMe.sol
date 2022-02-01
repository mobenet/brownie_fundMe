//SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

//we import the code from CHainlink:
//this is importing from npm
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

//we want this contract to be able to accept some type of payment

contract FundMe {
    using SafeMathChainlink for uint256; //this controls overflow

    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    //constructor: li passem l'adreça del mock d'agregator
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender; //quien deploya este contracto va a assignarsele al owner
    }

    //function that accepts payment: payable
    function fund() public payable {
        // setting a threshold
        //50$
        uint256 minimumUSD = 50 * 10**18; // 50 usd * 10¹⁸ everything in wei terms

        require(
            getConversionRate(msg.value) >= minimumUSD,
            "YOu need to spend more eth"
        ); //if not accomplished it will revert the trans

        //we wan tto keep track of who is sending us some funcding
        //all the addresses that sent us money
        addressToAmountFunded[msg.sender] += msg.value; //keywords in every transaction
        //msg.sender is the sender of the function call
        //msg.value is how much theyve sent.

        //create a minimum value or change currency & we want to work in USD
        //first: what the ETH -> USD conversion rate

        funders.push(msg.sender);
    }

    //get the last version of the Agreggator interface
    function getVersion() public view returns (uint256) {
        //first we need the type, with the address as a param of where this contract Aggregator is
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //    0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);
        //now we can call the functions from the aggregator interface
        return priceFeed.version();
    }

    //funcio per obtenir l'ultim preu de eth a usd
    function getPrice() public view returns (uint256) {
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //    0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //);
        //aixo es una tupla: it's a list of objects of potentially different types whose number is a constant at compile time
        (
            ,
            /*uint80 roundId*/
            //per tenir el codi mes net es pot deixar els valors en blank
            int256 answer, //answer is a int256 and we want to returna uint256 so we can typecasting /*uint256 startedAt*/ /*uint256 updatedAt*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData(); //answer retorna 10⁸, per aixo multipliquem per 10¹⁰ per obtenir el valor en wei
        return uint256(answer * 10000000000); //this is typecasting (el resultat es en wei)  2422.023296160000000000
    }

    //1000000000 wei = 1 gwei
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethAmount * ethPrice) / 1000000000000000000; // dividir entre 10¹⁸ perque tan ethprice com ethAmount estan elevats a 10¹⁸
        return ethAmountInUsd; //2422.02329616   24220.23296160   24220.23296160
        //2422023296160
        //1000000000 wei = 1 gwei => 2422023296160/10¹⁸ = 0.000002422 usd
        //1 eth = 1000000000gwei so if we multiply 0.000002422* 10⁹ = 2422 usd / 1 eth4
        //per tant un cop sha obtingut el valor sha de dividir entre 10¹8 ja que estem amb weis
    }

    function getEntranceFee() public view returns (uint256) {
        //minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    //modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _; //first it will run this code before the function, and will continue after the _;
    }

    //withdraw our money from the contract
    function withdraw() public payable onlyOwner {
        require(
            msg.sender == owner,
            "Only the owner of this contract can withdraw"
        );
        msg.sender.transfer(address(this).balance); //transfer all ethereum in this contract
        //msg.sender who ever called the withdraw
        //reset all value of the fundersArray to 0 because u have withdrawn
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
