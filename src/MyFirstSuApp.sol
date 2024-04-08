// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

contract MyFirstSuapp { 
    function onchain() public {}

    function offchain() public pure returns (bytes memory) {
        /* This is where you will write all your compute-heavy,
        off-chain logic to be done in a Kettle */
        return abi.encodeWithSelector(this.onchain.selector);
    }
}
