// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@reactive/interfaces/IReactive.sol";
import "@reactive/interfaces/ISystemContract.sol";

contract ReactiveCallbackProbe is IReactive {
    uint256 internal constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;
    uint64 internal constant DEFAULT_CALLBACK_GAS_LIMIT = 200000;
    bytes32 internal constant MARKER = keccak256("ReactiveCallbackProbeV1");

    bool public vm;
    ISystemContract public service;
    uint256 public sourceChainId;
    uint256 public destinationChainId;
    address public sourceContract;
    address public callbackTarget;
    uint256 public topic0;
    uint64 public callbackGasLimit;

    constructor(
        address _systemContract,
        uint256 _sourceChainId,
        uint256 _destinationChainId,
        address _sourceContract,
        address _callbackTarget,
        uint256 _topic0,
        uint64 _callbackGasLimit
    ) payable {
        service = ISystemContract(payable(_systemContract));
        sourceChainId = _sourceChainId;
        destinationChainId = _destinationChainId;
        sourceContract = _sourceContract;
        callbackTarget = _callbackTarget;
        topic0 = _topic0;
        callbackGasLimit = _callbackGasLimit == 0 ? DEFAULT_CALLBACK_GAS_LIMIT : _callbackGasLimit;

        uint256 size;
        assembly {
            size := extcodesize(0x0000000000000000000000000000000000fffFfF)
        }
        vm = size == 0;

        if (!vm) {
            service.subscribe(_sourceChainId, _sourceContract, _topic0, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE);
        }
    }

    function react(LogRecord calldata log) external override {
        bytes memory markerData = abi.encode(MARKER, log.chain_id, log.tx_hash, log.log_index);
        bytes memory payload = abi.encodeWithSignature("callback(address,bytes)", address(this), markerData);
        emit Callback(destinationChainId, callbackTarget, callbackGasLimit, payload);
    }

    function pay(uint256) external override {}

    receive() external payable override {}
}
