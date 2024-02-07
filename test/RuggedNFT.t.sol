// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {RuggedNFT} from "../contracts/RuggedNFT.sol";

contract RuggedNFTTest is Test {
    RuggedNFT public ruggedNFT;

    function setUp() public {
        ruggedNFT = new RuggedNFT(0, 0);
    }

    function test_Increment() public {
    }

    function testFuzz_SetNumber(uint256 x) public {
    }
}
