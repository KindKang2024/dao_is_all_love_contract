// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../dependencies/IAnyrand.sol";
import "../../dependencies/IRandomiserCallbackV3.sol";

/**
 * @title AnyrandMock
 * @notice A mock implementation of the Anyrand service for local testing
 * @dev This mock allows manual triggering of randomness responses for testing purposes
 */
contract AnyrandMock is IAnyrand {
    // Maps requestIds to their current state
    mapping(uint256 => RequestState) public requests;

    // Maps requestIds to their callback information
    struct RequestInfo {
        address requester;
        uint256 callbackGasLimit;
        uint256 deadline;
        bool fulfilled;
    }

    mapping(uint256 => RequestInfo) public requestInfo;

    // For generating sequential request IDs
    uint256 public nextRequestId = 1;

    // Fee settings
    uint256 public baseFee = 0.001 ether;
    uint256 public gasPriceWei = 50 gwei;

    /**
     * @notice Compute the request price based on callback gas limit
     * @param callbackGasLimit Gas limit for the callback
     * @return totalPrice Total price in wei
     * @return effectiveFeePerGas The gas price used for calculating the fee
     */
    function getRequestPrice(uint256 callbackGasLimit)
        external
        view
        returns (uint256 totalPrice, uint256 effectiveFeePerGas)
    {
        effectiveFeePerGas = gasPriceWei;
        totalPrice = baseFee + (callbackGasLimit * effectiveFeePerGas);
        return (totalPrice, effectiveFeePerGas);
    }

    /**
     * @notice Request randomness with a deadline
     * @param deadline Timestamp after which randomness should be fulfilled
     * @param callbackGasLimit Gas limit for callback
     * @return requestId The ID of the randomness request
     */
    function requestRandomness(uint256 deadline, uint256 callbackGasLimit) external payable returns (uint256) {
        require(deadline > block.timestamp, "Deadline must be in the future");

        // Check if payment is sufficient
        (uint256 price,) = this.getRequestPrice(callbackGasLimit);
        require(msg.value >= price, "Insufficient payment");

        // Generate request ID
        uint256 requestId = nextRequestId;
        nextRequestId++;

        // Store request info
        requests[requestId] = RequestState.Pending;
        requestInfo[requestId] = RequestInfo({
            requester: msg.sender,
            callbackGasLimit: callbackGasLimit,
            deadline: deadline,
            fulfilled: false
        });

        return requestId;
    }

    /**
     * @notice Get the state of a request
     * @param requestId The request identifier
     * @return state The current state of the request
     */
    function getRequestState(uint256 requestId) external view returns (RequestState) {
        return requests[requestId];
    }

    /**
     * @notice Manually fulfill a randomness request for testing
     * @dev Only call this for testing purposes
     * @param requestId The ID of the request to fulfill
     * @param randomValue The random value to return
     */
    function fulfillRandomness(uint256 requestId, uint256 randomValue) external {
        RequestInfo storage info = requestInfo[requestId];
        require(info.requester != address(0), "Request does not exist");
        require(!info.fulfilled, "Request already fulfilled");
        require(requests[requestId] == RequestState.Pending, "Request not pending");

        info.fulfilled = true;

        // Call the callback with the provided gas limit
        // try IRandomiserCallbackV3(info.requester).receiveRandomness{ gas: info.callbackGasLimit }(
        //     requestId, randomValue
        // ) {
        //     requests[requestId] = RequestState.Fulfilled;
        // } catch {
        //     requests[requestId] = RequestState.Failed;
        // }
        IRandomiserCallbackV3(info.requester).receiveRandomness(requestId, randomValue);
        requests[requestId] = RequestState.Fulfilled;
    }

    /**
     * @notice Set the base fee for testing
     * @param _baseFee New base fee in wei
     */
    function setBaseFee(uint256 _baseFee) external {
        baseFee = _baseFee;
    }

    /**
     * @notice Set the gas price for testing
     * @param _gasPriceWei New gas price in wei
     */
    function setGasPrice(uint256 _gasPriceWei) external {
        gasPriceWei = _gasPriceWei;
    }

    /**
     * @notice Withdraw ETH from the contract
     * @param to Address to send ETH to
     * @param amount Amount of ETH to withdraw
     */
    function withdraw(address payable to, uint256 amount) external {
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
    }
}
