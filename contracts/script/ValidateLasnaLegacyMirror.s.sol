// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@reactive/interfaces/IReactive.sol";
import "@reactive/interfaces/ISystemContract.sol";

contract LegacyMirrorReactiveProbe is IReactive {
    uint256 internal constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;
    uint64 internal constant CALLBACK_GAS_LIMIT = 200000;

    bool public vm;
    ISystemContract public service;
    uint256 public originChainId;
    uint256 public destinationChainId;
    address public originContract;
    address public callbackContract;
    uint256 public topic0;

    constructor(
        address _service,
        uint256 _originChainId,
        uint256 _destinationChainId,
        address _originContract,
        address _callbackContract,
        uint256 _topic0
    ) payable {
        service = ISystemContract(payable(_service));
        originChainId = _originChainId;
        destinationChainId = _destinationChainId;
        originContract = _originContract;
        callbackContract = _callbackContract;
        topic0 = _topic0;

        uint256 size;
        assembly {
            size := extcodesize(0x0000000000000000000000000000000000fffFfF)
        }
        vm = size == 0;

        if (!vm) {
            service.subscribe(_originChainId, _originContract, _topic0, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE);
        }
    }

    function react(LogRecord calldata) external override {
        bytes memory payload = abi.encodeWithSignature("callback(address)", address(this));
        emit Callback(destinationChainId, callbackContract, CALLBACK_GAS_LIMIT, payload);
    }

    function pay(uint256) external override {}

    receive() external payable override {}
}

contract ValidateLasnaLegacyMirror is Script {
    uint256 internal constant DEFAULT_SOURCE_CHAIN_ID = 11155111;
    uint256 internal constant DEFAULT_DESTINATION_CHAIN_ID = 84532;
    uint256 internal constant DEFAULT_TOPIC_0 = uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));
    uint256 internal constant DEFAULT_VALUE = 0;
    address internal constant SYSTEM_CONTRACT = 0x0000000000000000000000000000000000fffFfF;

    function _startBroadcastWithOptionalKey(string memory privateKeyEnv) internal {
        string memory keystore = vm.envOr("REACTIVE_KEYSTORE", string(""));
        if (bytes(keystore).length != 0) {
            vm.startBroadcast();
            return;
        }

        string memory keystoreAccount = vm.envOr("REACTIVE_KEYSTORE_ACCOUNT", string(""));
        if (bytes(keystoreAccount).length != 0) {
            vm.startBroadcast();
            return;
        }

        string memory privateKey = vm.envOr(privateKeyEnv, string("__SET_LOCALLY_ONLY__"));
        if (
            bytes(privateKey).length != 0
                && keccak256(bytes(privateKey)) != keccak256(bytes("__SET_LOCALLY_ONLY__"))
        ) {
            vm.startBroadcast(vm.parseUint(privateKey));
        } else {
            vm.startBroadcast();
        }
    }

    function run() external {
        uint256 sourceChainId = vm.envOr("VALIDATION_SOURCE_CHAIN_ID", DEFAULT_SOURCE_CHAIN_ID);
        uint256 destinationChainId = vm.envOr("VALIDATION_DESTINATION_CHAIN_ID", DEFAULT_DESTINATION_CHAIN_ID);
        address sourceContract = vm.envAddress("VALIDATION_SOURCE_CONTRACT");
        address callbackContract = vm.envAddress("VALIDATION_CALLBACK_CONTRACT");
        uint256 topic0 = vm.envOr("VALIDATION_TOPIC0", DEFAULT_TOPIC_0);
        uint256 deployValue = vm.envOr("VALIDATION_DEPLOY_VALUE_WEI", DEFAULT_VALUE);

        _startBroadcastWithOptionalKey("REACTIVE_PRIVATE_KEY");
        LegacyMirrorReactiveProbe probe = new LegacyMirrorReactiveProbe{value: deployValue}(
            SYSTEM_CONTRACT, sourceChainId, destinationChainId, sourceContract, callbackContract, topic0
        );
        vm.stopBroadcast();

        console2.log("=== Lasna Legacy Mirror Validation ===");
        console2.log("LegacyMirrorReactiveProbe:", address(probe));
        console2.log("vm:", probe.vm());
        console2.log("originChainId:", probe.originChainId());
        console2.log("destinationChainId:", probe.destinationChainId());
        console2.log("originContract:", probe.originContract());
        console2.log("callbackContract:", probe.callbackContract());
        console2.log("topic0:", probe.topic0());
    }
}
