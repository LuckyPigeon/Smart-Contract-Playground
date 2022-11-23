//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

contract Lottery {
    address payable[] public players;
    address public manager;

    constructor() {
        manager = msg.sender;
        // Challenge #2: Manage automatically pariticipate the lottery.
        // players.push(payable(manager));
    }

    receive() external payable {
        // Challenge #1: Manager can't participate in the lottery.
        // require(msg.sender != manager);
        require(msg.value == 0.1 ether);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint256) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public view returns(uint256) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function chooseWinner() public {
        // Challenge #3: Anyone call pick the winner and finish the lottery, if there are at least 10 players.
        // if (players.length < 10) {
        //     require(msg.sender == manager);
        // }
        require(msg.sender == manager);
        require(players.length >= 3);

        uint256 r = random();
        address payable winner;

        uint index = r % players.length;
        winner = players[index];
        // Challenge #4: Manager recives a fee of 10% of the lottery funds
        // payable(manager).transfer((getBalance() * 10) / 100)
        // winner.transfer((getBalance() * 90) / 100);
        winner.transfer(getBalance());
        players = new address payable[](0);
        // players.push(payable(manager)); challenge #2
    }
}