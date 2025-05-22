// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {VotingSystem} from "../src/VotingSystem.sol";
import {DeployVotingsystem} from "../script/DeployVotingsystem.s.sol";
import {console} from "forge-std/console.sol";

contract DeployVotingSystemTest is Test {
    DeployVotingsystem deployScript;

    function setUp() public {
        deployScript = new DeployVotingsystem();
    }

    /*  function testDeployment() public {
        string ;
        candidates[0] = "Alice";
        candidates[1] = "Bob";
        candidates[2] = "Charlie";

        uint duration = 3600;

        VotingSystem vs = deployScript.deployVotingSystem(candidates, duration);
        assert(address(vs) != address(0));
    }
}*/

    function testDeploymentWithEnvironmentVariables() public {
        vm.setEnv("CANDIDATE1", "Alice");
        vm.setEnv("CANDIDATE2", "Bob");
        vm.setEnv("CANDIDATE3", "Charlie");
        vm.setEnv("VOTING_DURATION", "86400");

        // act
        VotingSystem deployed = deployScript.run();

        // Assert
        assert(address(deployed) != address(0)); // check if contract was deployed
    }
}
