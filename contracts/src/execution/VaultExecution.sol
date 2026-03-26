// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@reactive/abstract-base/AbstractCallback.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../adapters/interfaces/IVaultActionAdapter.sol";

contract VaultExecution is AbstractCallback, Ownable2Step, Pausable, ReentrancyGuard {
    mapping(address => bool) public allowedAdapters;

    event AdapterAllowed(address indexed adapter, bool allowed);
    event ExecutionSucceeded(uint256 indexed ruleId, address indexed adapter, bytes returnData);
    event ExecutionFailed(uint256 indexed ruleId, address indexed adapter, bytes reason);

    error AdapterNotAllowed(address adapter);
    error InvalidAdapter();

    constructor(address _owner, address _callbackProxy) AbstractCallback(_callbackProxy) Ownable(_owner) {
        rvm_id = _owner;
    }

    function setAdapterAllowed(address adapter, bool allowed) external onlyOwner {
        if (adapter == address(0)) {
            revert InvalidAdapter();
        }
        allowedAdapters[adapter] = allowed;
        emit AdapterAllowed(adapter, allowed);
    }

    function executeFromReactive(address rvmId, uint256 ruleId, address adapter, bytes calldata adapterData)
        external
        authorizedSenderOnly
        rvmIdOnly(rvmId)
        whenNotPaused
        nonReentrant
    {
        if (!allowedAdapters[adapter]) {
            revert AdapterNotAllowed(adapter);
        }

        try IVaultActionAdapter(adapter).execute(ruleId, adapterData) returns (bytes memory returnData) {
            emit ExecutionSucceeded(ruleId, adapter, returnData);
        } catch Error(string memory reason) {
            emit ExecutionFailed(ruleId, adapter, bytes(reason));
        } catch (bytes memory lowLevelReason) {
            emit ExecutionFailed(ruleId, adapter, lowLevelReason);
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    receive() override external payable {}
}
