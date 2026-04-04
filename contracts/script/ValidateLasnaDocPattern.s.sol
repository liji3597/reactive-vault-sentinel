// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "@reactive/interfaces/IReactive.sol";
import "@reactive/interfaces/ISystemContract.sol";

contract DocPatternReactiveProbe is IReactive {
    uint256 internal constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;

    bool public vm;
    ISystemContract public service;
    uint256 public originChainId;
    address public sourceContract;
    uint256 public topic0;

    constructor(address _service, uint256 _originChainId, address _sourceContract, uint256 _topic0) payable {
        service = ISystemContract(payable(_service));
        originChainId = _originChainId;
        sourceContract = _sourceContract;
        topic0 = _topic0;

        uint256 size;
        assembly {
            size := extcodesize(0x0000000000000000000000000000000000fffFfF)
        }
        vm = size == 0;

        if (!vm) {
            service.subscribe(_originChainId, _sourceContract, _topic0, REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE);
        }
    }

    function react(LogRecord calldata) external override {}

    function pay(uint256) external override {}

    receive() external payable override {}
}

contract ValidateLasnaDocPattern is Script {
    uint256 internal constant DEFAULT_SOURCE_CHAIN_ID = 11155111;
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
        address sourceContract_ = vm.envAddress("VALIDATION_SOURCE_CONTRACT");
        uint256 topic0_ = vm.envOr("VALIDATION_TOPIC0", DEFAULT_TOPIC_0);
        uint256 deployValue = vm.envOr("VALIDATION_DEPLOY_VALUE_WEI", DEFAULT_VALUE);

        _startBroadcastWithOptionalKey("REACTIVE_PRIVATE_KEY");
        DocPatternReactiveProbe probe =
            new DocPatternReactiveProbe{value: deployValue}(SYSTEM_CONTRACT, sourceChainId, sourceContract_, topic0_);
        vm.stopBroadcast();

        console2.log("=== Lasna Doc Pattern Validation ===");
        console2.log("DocPatternReactiveProbe:", address(probe));
        console2.log("vm:", probe.vm());
        console2.log("originChainId:", probe.originChainId());
        console2.log("sourceContract:", probe.sourceContract());
        console2.log("topic0:", probe.topic0());
    }
}
