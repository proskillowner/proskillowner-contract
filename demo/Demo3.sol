// SPDX-License-Identifier: BUSL-1.1
// (c) Long Gamma Labs, 2024.
pragma solidity ^0.8.28;


import { IPyth } from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";


import { ErrorReporter } from "../ErrorReporter.sol";


library PythPriceHelper {
    function updatePrices(IPyth pyth, bytes[] calldata priceUpdateData) internal returns (uint256) {
        uint256 fee = 0;
        if (priceUpdateData.length != 0) {
            fee = pyth.getUpdateFee(priceUpdateData);
            require(msg.value >= fee, ErrorReporter.InsufficientFeeForPythUpdate());
            pyth.updatePriceFeeds{value: fee}(priceUpdateData);
        }

        uint256 rest;
        unchecked {
            rest = msg.value - fee;
        }
        sendGASToken(msg.sender, rest);
        return rest;
    }

    function sendGASToken(address to, uint256 value) internal {
        if (value == 0) {
            return;
        }
        (bool success, ) = to.call{value: value}("");
        require(success, ErrorReporter.TransferFailed());
    }
}