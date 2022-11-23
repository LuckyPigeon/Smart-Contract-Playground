//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;


contract Auction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Activated, Ended, Canceled}
    State public auctionState;

    mapping(address => uint) bidders;
    uint public sailingPrice;
    uint public bidIncrement;
    address payable public highestBidder;

    constructor() {
        owner = payable(msg.sender);
        startBlock = block.number;
        endBlock = startBlock + 40320; // ethereum produce a block every 15 sec in average, bids for a weeks
        ipfsHash = "";
        auctionState = State.Activated;
        bidIncrement = 100;
    }

    /* Modifier */
    /* Only the owner can perform action */
    modifier onlyOwner() {
        require(msg.sender == owner, "only the owner can perform this action");
        _;
    }

    /* Owner can't participate the bid, or the price will be manipulated artificially */
    modifier notOwner() {
        require(msg.sender != owner, "owner can't participate the bid");
        _;
    }

    /* The bids must come after the bids start */
    modifier afterStartBlock() {
        require(block.number > startBlock, "this action can only execute after startBlock");
        _;
    }

    /* The bids must come before the bids end */
    modifier beforeEndBlock() {
        require(block.number < endBlock, "this action can only execute before endBlock");
        _;
    }

    function min(uint a, uint b) public pure returns(uint) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }

    function placeBid() public payable notOwner afterStartBlock beforeEndBlock {
        require(auctionState == State.Activated, "action state must be activated");
        require(msg.value >= 1000, "bid must greater than 1000");

        uint currentBid = bidders[msg.sender] + msg.value;
        require(currentBid > sailingPrice, "bid must greater than sailing price");

        bidders[msg.sender] = currentBid;

        if (currentBid < bidders[highestBidder]) {
            sailingPrice = min(currentBid + bidIncrement, bidders[highestBidder]);
        } else {
            sailingPrice = min(currentBid, bidders[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    function cancelBid() public onlyOwner {
        auctionState = State.Canceled;
    }

    function finalizeBid() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bidders[msg.sender] > 0);

        address payable recipient;
        uint amount;

        if (msg.sender == owner) {
            recipient = owner;
            amount = sailingPrice;
        } else {
            if (msg.sender == highestBidder) {
                recipient = highestBidder;
                amount = bidders[highestBidder] - sailingPrice;
            } else {
                recipient = payable(msg.sender);
                amount = bidders[msg.sender];
            }
        }

        recipient.transfer(amount);
    }
}

