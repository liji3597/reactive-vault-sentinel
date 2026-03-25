// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IVaultActionAdapter.sol";

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf)
        external
        returns (uint256);
}

contract AaveProtectionAdapter is IVaultActionAdapter, Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum ActionType {
        REPAY,
        WITHDRAW,
        SUPPLY
    }

    address public immutable executor;
    IAavePool public pool;

    event PoolUpdated(address indexed pool);
    event Executed(
        uint256 indexed ruleId, ActionType indexed actionType, address indexed asset, uint256 amount, address onBehalfOf
    );

    error UnauthorizedExecutor(address caller);
    error InvalidAddress();
    error UnsupportedAction(uint8 actionType);

    modifier onlyExecutor() {
        if (msg.sender != executor) {
            revert UnauthorizedExecutor(msg.sender);
        }
        _;
    }

    constructor(address _owner, address _executor, address _pool) Ownable(_owner) {
        if (_executor == address(0) || _pool == address(0)) {
            revert InvalidAddress();
        }
        executor = _executor;
        pool = IAavePool(_pool);
    }

    function setPool(address _pool) external onlyOwner {
        if (_pool == address(0)) {
            revert InvalidAddress();
        }
        pool = IAavePool(_pool);
        emit PoolUpdated(_pool);
    }

    function execute(uint256 ruleId, bytes calldata data)
        external
        override
        onlyExecutor
        nonReentrant
        returns (bytes memory)
    {
        (uint8 actionTypeRaw, address asset, uint256 amount, address onBehalfOf) =
            abi.decode(data, (uint8, address, uint256, address));
        if (asset == address(0) || onBehalfOf == address(0)) {
            revert InvalidAddress();
        }

        ActionType actionType = ActionType(actionTypeRaw);

        if (actionType == ActionType.REPAY) {
            IERC20(asset).forceApprove(address(pool), amount);
            uint256 repaid = pool.repay(asset, amount, 2, onBehalfOf);
            emit Executed(ruleId, actionType, asset, repaid, onBehalfOf);
            return abi.encode(repaid);
        }

        if (actionType == ActionType.WITHDRAW) {
            uint256 withdrawn = pool.withdraw(asset, amount, onBehalfOf);
            emit Executed(ruleId, actionType, asset, withdrawn, onBehalfOf);
            return abi.encode(withdrawn);
        }

        if (actionType == ActionType.SUPPLY) {
            IERC20(asset).forceApprove(address(pool), amount);
            pool.supply(asset, amount, onBehalfOf, 0);
            emit Executed(ruleId, actionType, asset, amount, onBehalfOf);
            return abi.encode(amount);
        }

        revert UnsupportedAction(actionTypeRaw);
    }

    function withdrawToken(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }

    function withdrawEth(address payable to, uint256 amount) external onlyOwner {
        (bool ok,) = to.call{value: amount}("");
        require(ok, "WITHDRAW_ETH_FAILED");
    }

    receive() external payable {}
}
