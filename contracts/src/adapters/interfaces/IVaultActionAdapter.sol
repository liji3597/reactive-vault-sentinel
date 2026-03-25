// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IVaultActionAdapter {
    function execute(uint256 ruleId, bytes calldata data) external returns (bytes memory);
}
