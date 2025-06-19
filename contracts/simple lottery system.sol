
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleLottery {
    address public owner;
    address[] public players;
    uint256 public ticketPrice;
    bool public lotteryActive;
    address public lastWinner;
    uint256 public totalPrizePool;
    
    event PlayerEntered(address indexed player);
    event WinnerSelected(address indexed winner, uint256 prize);
    event LotteryReset();
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier lotteryIsActive() {
        require(lotteryActive, "Lottery is not active");
        _;
    }
    
    constructor(uint256 _ticketPrice) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        lotteryActive = true;
    }
    
    // Core Function 1: Enter the lottery by buying a ticket
    function enterLottery() public payable lotteryIsActive {
        require(msg.value == ticketPrice, "Incorrect ticket price");
        require(msg.sender != owner, "Owner cannot participate");
        
        players.push(msg.sender);
        totalPrizePool += msg.value;
        
        emit PlayerEntered(msg.sender);
    }
    
    // Core Function 2: Pick a winner (only owner can call)
    function pickWinner() public onlyOwner lotteryIsActive {
        require(players.length > 0, "No players in the lottery");
        
        // Generate pseudo-random number (Note: not truly random, for production use Chainlink VRF)
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            players.length
        ))) % players.length;
        
        address winner = players[randomIndex];
        uint256 prize = totalPrizePool;
        
        // Transfer prize to winner
        payable(winner).transfer(prize);
        
        // Update state
        lastWinner = winner;
        lotteryActive = false;
        
        emit WinnerSelected(winner, prize);
    }
    
    // Core Function 3: Reset lottery for a new round
    function resetLottery() public onlyOwner {
        require(!lotteryActive, "Current lottery must be completed first");
        
        // Clear players array
        delete players;
        totalPrizePool = 0;
        lotteryActive = true;
        
        emit LotteryReset();
    }
    
    // View function to get current players
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
    
    // View function to get number of players
    function getPlayerCount() public view returns (uint256) {
        return players.length;
    }
    
    // View function to check if address is participating
    function isPlayerParticipating(address player) public view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) {
                return true;
            }
        }
        return false;
    }
    
    // Emergency function to withdraw funds (only if lottery is inactive)
    function emergencyWithdraw() public onlyOwner {
        require(!lotteryActive, "Cannot withdraw while lottery is active");
        payable(owner).transfer(address(this).balance);
    }
    
    // Function to change ticket price (only when lottery is inactive)
    function setTicketPrice(uint256 _newPrice) public onlyOwner {
        require(!lotteryActive, "Cannot change price while lottery is active");
        ticketPrice = _newPrice;
    }
}
