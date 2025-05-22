// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {VotingSystem} from "../src/VotingSystem.sol";
import {console} from "forge-std/console.sol";

contract Interactions is Script {
    // load contarct addrress from the environment variable
    address contractAddress = vm.envAddress("VOTING_CONTRACT_ADDRESS");
    VotingSystem voting = VotingSystem(contractAddress);
    address public owner = address(1); // Just a test address

    /*constructor() {
        owner = address(this);
    }*/

    function vote(uint _candidateIndex) external {
        vm.startBroadcast();
        voting.vote(_candidateIndex);
        vm.stopBroadcast();
        console.log("Voted for candidate index: ", _candidateIndex);
    }

    function registerVoter(address _voter) external {
        vm.startBroadcast();
        voting.registerVoter(_voter);
        vm.stopBroadcast();
        console.log("Registered voter: ", _voter);
    }

    function addcandidates(string memory _name) external {
        vm.startBroadcast();
        voting.addCandidate(_name);
        vm.stopBroadcast();
        console.log("Added candidate: ", _name);
    }

    function startVoting() external {
        vm.startBroadcast(owner);
        voting.startVoting();
        vm.stopBroadcast();
        console.log("Voting started");
    }

    function endvoting() external {
        vm.startBroadcast(owner);
        voting.endVoting();
        vm.stopBroadcast();
        console.log("Voting ended");
    }

    function getwinner(string memory Winnersname) external {
        vm.startBroadcast();
        voting.getWinners();
        vm.stopBroadcast();
        console.log("Winner announced", Winnersname);
    }

    function getvotingstatus(bool) external {
        vm.startBroadcast();
        voting.getVotingStatus();
        vm.stopBroadcast();
        console.log("VotingStatus: ", voting.getVotingStatus());
    }

    function getvotingdeadline(uint) external {
        vm.startBroadcast();
        voting.getVotingDeadline();
        vm.stopBroadcast();
        console.log("VotingDeadline: ", voting.getVotingDeadline());
    }

    function getcandidates() external {
        vm.startBroadcast();
        voting.getCandidates();
        vm.stopBroadcast();
        VotingSystem.Candidate[] memory candidates = voting.getCandidates();
        for (uint i = 0; i < candidates.length; i++) {
            console.log("Candidate %s: %s", i, candidates[i].name);
        }
    }

    function getresults(string[] memory names, uint[] memory votes) external {
        vm.startBroadcast();
        voting.getResults();
        vm.stopBroadcast();
        (string[] memory resultNames, uint[] memory resultVotes) = voting
            .getResults();
        for (uint i = 0; i < resultNames.length; i++) {
            console.log(
                "Candidate %s: %s with %s votes",
                i,
                resultNames[i],
                resultVotes[i]
            );
        }
    }

    function getregisteredvoterlist(address[] memory) external {
        vm.startBroadcast();
        voting.getRegisteredVoterList();
        vm.stopBroadcast();
        address[] memory registeredVoters = voting.getRegisteredVoterList();
        for (uint i = 0; i < registeredVoters.length; i++) {
            console.log("Registered Voter %s: %s", i, registeredVoters[i]);
        }
    }
}
