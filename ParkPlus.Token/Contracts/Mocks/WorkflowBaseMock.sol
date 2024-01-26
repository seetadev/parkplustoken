// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../WorkflowBase.sol";

contract WorkflowBaseMock is WorkflowBase {
    function addItems(uint256 num) external {
        for (uint256 i = 0; i < num; i++) {
            _getNextId();
        }
    }
}