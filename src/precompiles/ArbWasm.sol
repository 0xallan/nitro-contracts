// Copyright 2022-2023, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Methods for managing user programs
 * @notice Precompiled contract that exists in every Arbitrum chain at 0x0000000000000000000000000000000000000071.
 */
interface ArbWasm {
    // @notice compile a wasm program
    // @param program the program to compile
    // @return version the stylus version the program was compiled against
    function compileProgram(address program) external returns (uint32 version);

    // @notice gets the latest stylus version
    // @return version the stylus version
    function stylusVersion() external view returns (uint32 version);

    // @notice gets the conversion rate between gas and ink
    // @return price the price (in evm gas basis points) of ink
    function inkPrice() external view returns (uint64 price);

    // @notice gets the wasm stack size limit
    // @return depth the maximum depth (in wasm words) a wasm stack may grow
    function wasmMaxDepth() external view returns (uint32 depth);

    // @notice gets the fixed-cost overhead needed to initiate a hostio call
    // @return cost the cost (in ink) of starting a stylus hostio call
    function wasmHostioInk() external view returns (uint64 price);

    // @notice gets the stylus version the program was most recently compiled against.
    // @return version the program version (0 for EVM contracts)
    function programVersion(address program) external view returns (uint32 version);

    error ProgramNotCompiled();
    error ProgramOutOfDate(uint32 version);
    error ProgramUpToDate();
}
