// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
    function _msgData() internal view  returns(bytes  calldata){
        this;
        return msg.data;
    }
}