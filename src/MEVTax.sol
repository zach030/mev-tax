// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title MEVTax
/// @notice This contract should be inherited by contracts to apply a MEV tax.
///         The tax amount is calculated as a function of the priority fee per
///         gas of the transaction.
contract MEVTax is Ownable {
    /// @notice ERC20 token for paying the tax.
    IERC20 public currency;

    /// @notice Recipient of the tax transfers.
    address public recipient = address(this);

    uint256 internal _negDelta = 0;

    /// @notice Modifier to apply tax on a function.
    ///         If applying the tax fails, the modifier reverts.
    modifier applyTax() {
        _;
        _applyTax();
    }

    /// @dev Sets the deployer as the initial owner.
    constructor(address _currencyAddress) Ownable(msg.sender) {
        currency = IERC20(_currencyAddress);
    }

    /// @notice Updates currency to _currency.
    /// @param _currency ERC20 token setting _currency to.
    function setCurrency(IERC20 _currency) external onlyOwner {
        currency = _currency;
    }

    /// @notice Updates recipient to _recipient.
    /// @param _recipient Address setting recipient to.
    function setRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    /// @notice Computes the tax function for an arbitrary _priorityFeePerGas.
    ///         Unless overridden, it is 99 times the priority fee per gas.
    /// @dev    Override this function to implement an arbitrary tax function.
    /// @param  _priorityFeePerGas Priority fee per gas to input to the tax function.
    /// @return Output of the tax function (the tax amount for _priorityFeePerGas).
    function tax(uint256 _priorityFeePerGas) public view virtual returns (uint256) {
        return 99 * _priorityFeePerGas;
    }

    /// @notice Applies tax by transferring the tax amount (at the tx's priority fee per gas)
    ///         from msg.sender to recipient. If the transfer fails, _payTax reverts.
    function _applyTax() internal {
        require(currency.transferFrom(msg.sender, recipient, tax(_getPriorityFeePerGas())));
    }

    /// @notice Returns the priority fee per gas.
    /// @return Priority fee per gas.
    function _getPriorityFeePerGas() internal view returns (uint256) {
        return tx.gasprice - block.basefee;
    }

    function _msgValue() internal view virtual returns (uint256) {
        return msg.value - _negDelta;
    }
}
