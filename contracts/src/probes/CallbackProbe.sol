// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@reactive/abstract-base/AbstractCallback.sol";

contract CallbackProbe is AbstractCallback {
    address public lastCallbackSender;
    bytes public lastCallbackPayload;

    event CallbackObserved(
        address indexed caller, address indexed sender, uint256 payloadLength, bytes payload
    );

    constructor(address callbackProxy, address expectedRvmId) AbstractCallback(callbackProxy) {
        rvm_id = expectedRvmId;
    }

    function callback(address sender, bytes calldata payload) external authorizedSenderOnly rvmIdOnly(sender) {
        lastCallbackSender = sender;
        lastCallbackPayload = payload;
        emit CallbackObserved(msg.sender, sender, payload.length, payload);
    }

    receive() override external payable {}
}
