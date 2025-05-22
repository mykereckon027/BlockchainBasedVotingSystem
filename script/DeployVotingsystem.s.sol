// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VotingSystem} from "../src/VotingSystem.sol";
import {console} from "forge-std/console.sol";

contract DeployVotingsystem is Script {
    VotingSystem public votingSystem;
    string[] public candidatesnames = new string[](3);

    function deployVotingSystem(
        string[] memory _candidatesnames,
        uint duration
    ) public returns (VotingSystem) {
        vm.startBroadcast();
        votingSystem = new VotingSystem(_candidatesnames, duration);
        vm.stopBroadcast();

        console.log("VotingSystem deployed to: ", address(votingSystem));
        return votingSystem;
    }

    function run() external returns (VotingSystem) {
        candidatesnames[0] = vm.envString("CANDIDATE1");
        candidatesnames[1] = vm.envString("CANDIDATE2");
        candidatesnames[2] = vm.envString("CANDIDATE3");
        uint duration = vm.envUint("VOTING_DURATION");

        return deployVotingSystem(candidatesnames, duration);
    }
}
