//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

contract CrowdFunding {
    /*
     * State variables
     */
    mapping(address => uint) public donators;
    address public owner;
    uint public numOfDonators;
    uint public minAmount;
    uint public goal;
    uint public total;
    uint public deadline;

    /*
     * Spending Request
     */
    struct SpendingRequest {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint numOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint => SpendingRequest) public spendingRequests;
    uint numOfSpendingRequest;

    constructor(uint _goal, uint _deadline) {
        owner = msg.sender;
        minAmount = 100 wei;
        goal = _goal;
        deadline = block.timestamp + _deadline;
    }

    event DonateEvent(address _sender, uint _value);
    event CreateSpendingRequestEvent(string _description, address _recipient, uint _value);
    event VoteSpendingRequestEvent(uint _numOfVoters);
    event AcceptSpendingRequest(address _recipient, uint _value);

    receive() external payable {
        donate();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can perform this action.");
        _;
    }

    modifier safeSpendingRequest(uint _numOfSpendingRequest) {
        require(numOfSpendingRequest <= _numOfSpendingRequest, "The spending request does not exist!");
        _;
    }

    function donate() public payable {
        require(block.timestamp < deadline, "Deadline has passed!");
        require(msg.value > minAmount, "Minimum amount is not met!");

        if (donators[msg.sender] == 0) {
            numOfDonators++;
        }

        donators[msg.sender] += msg.value;
        total += msg.value;
        emit DonateEvent(msg.sender, msg.value);
    }

    function withdraw() public {
        require(block.timestamp > deadline && total < goal, "Crowdfunding condition is met!");
        require(donators[msg.sender] > 0, "You didn't have any asset in crowdfunding");

        uint value = donators[msg.sender];
        donators[msg.sender] = 0;
        payable(msg.sender).transfer(value);
    }

    function createSpendingRequest(string memory _description, address payable _recipient, uint _value) public onlyOwner {
        SpendingRequest storage sr = spendingRequests[numOfSpendingRequest];
        numOfSpendingRequest++;

        sr.description = _description;
        sr.recipient = _recipient;
        sr.value = _value;
        sr.completed = false;
        sr.numOfVoters = 0;

        emit CreateSpendingRequestEvent(_description, _recipient, _value);
    }

    function voteSpendingRequest(uint _numOfSpendingRequest) public safeSpendingRequest(_numOfSpendingRequest) {
        require(donators[msg.sender] > 0, "You must be a donator!");
        SpendingRequest storage sr = spendingRequests[_numOfSpendingRequest];

        require(sr.voters[msg.sender] == false, "You have already voted!");
        sr.voters[msg.sender] = true;
        sr.numOfVoters++;

        emit VoteSpendingRequestEvent(sr.numOfVoters);
    }

    function acceptSpendingRequest(uint _numOfSpendingRequest) public onlyOwner safeSpendingRequest(_numOfSpendingRequest) {
        require(total >= goal, "Total amount must greater than or equal to goal!");
        SpendingRequest storage sr = spendingRequests[_numOfSpendingRequest];

        require(sr.completed == false, "The spending request has already completed!");
        require(sr.numOfVoters > numOfDonators / 2, "Need at least half of donators to vote!");
        sr.recipient.transfer(sr.value);
        sr.completed = true;

        emit AcceptSpendingRequest(sr.recipient, sr.value);
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function isDeadlinePassed() public view returns(bool) {
        return block.timestamp > deadline;
    }
}