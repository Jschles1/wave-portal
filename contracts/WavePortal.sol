// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WavePortal is VRFConsumerBase, Ownable {
    uint256 totalWaves;
    bytes32 private keyHash;
    uint256 private fee;

    struct Wave {
        address waver;
        string message;
        uint256 timestamp;
    }

    Wave[] waves;

    mapping(address => uint256) public lastWavedAt;
    mapping(address => string) public messageFromSender;
    mapping(bytes32 => address) public requestIdToSender;

    event NewWave(address indexed from, uint256 timestamp, string message, bool isWinner);
    event RandomNumberRequested(bytes32 indexed requestId);

    constructor(address _vrfCoordinator, address _linkToken, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        payable 
    {
        keyHash = _keyHash;
        fee = _fee;
    }

    function initializeWave(string memory _message) public {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        /*
         * We need to make sure the current timestamp is at least 2 minutes bigger than the last timestamp we stored
         */
        require(
            lastWavedAt[msg.sender] + 2 minutes < block.timestamp,
            "Wait 2 minutes"
        );

        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;
        messageFromSender[msg.sender] = _message;

        emit RandomNumberRequested(requestId);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint256 randomResult = (randomness % 100) + 1;
        address requestSender = requestIdToSender[requestId];
        string memory pendingMessage = messageFromSender[requestSender];

        finishWave(pendingMessage, randomResult);
    }

    function finishWave(string memory _message, uint256 random) internal {
        /*
         * Update the current timestamp we have for the user
         */
        lastWavedAt[msg.sender] = block.timestamp;

        totalWaves += 1;

        waves.push(Wave(msg.sender, _message, block.timestamp));

        bool isWinner = false;

        if (random <= 50) {
            uint256 prizeAmount = 0.0001 ether;
            require(
                prizeAmount <= address(this).balance,
                "Trying to withdraw more money than they contract has."
            );
            (bool success, ) = (msg.sender).call{value: prizeAmount}("");
            require(success, "Failed to withdraw money from contract.");
            isWinner = true;
        }

        emit NewWave(msg.sender, block.timestamp, _message, isWinner);
    }

    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getTotalWaves() public view returns (uint256) {
        return totalWaves;
    }

    function resetWaves() public onlyOwner {
        delete waves;
        totalWaves = 0;
    }
}