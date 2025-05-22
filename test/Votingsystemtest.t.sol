// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {VotingSystem} from "../src/VotingSystem.sol";
import {console} from "forge-std/console.sol";

contract VotingSystemTest is Test {
    VotingSystem public voting;
    address public owner = address(1);
    address public voter1;
    address public voter2;
    address public voter3;

    /* custom error*/
    error youHaveAlreadyvoted();
    error youAreNotRegistered(address voter);
    error votingPeriodOver();
    error invalidCandidateIndex(uint index);
    error noCandidatesAvailable();
    error VoterAlreadyRegistered(address voter);

    string[] candidateNames = ["Alice", "Bob", "Charlie"];
    uint votingDuration = 1 days;

    function setUp() public {
        // owner = address(this);
        voter1 = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        voter2 = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
        voter3 = address(0x90F79bf6EB2c4f870365E785982E1f101E93b906);

        vm.startPrank(owner);
        voting = new VotingSystem(candidateNames, votingDuration);
        vm.stopPrank();

        console.log("VotingSystem owner:", voting.owner());
    }

    function testIfOwnerIsReallyOwner() public {
        assertEq(voting.owner(), owner, "Owner is not the contract deployer");
    }

    function testInitialCandidates() public {
        VotingSystem.Candidate[] memory candidateList = voting.getCandidates();
        assertEq(candidateList.length, 3, "Initial candidates count is not 3");
        assertEq(
            candidateList[0].name,
            "Alice",
            "First candidate name is not Alice"
        );
        assertEq(
            candidateList[1].name,
            "Bob",
            "Second candidate name is not Bob"
        );
        assertEq(
            candidateList[2].name,
            "Charlie",
            "Third candidate name is not Charlie"
        );
    }

    function testRegisterVoter() public {
        vm.prank(owner);
        voting.startVoting();
        vm.prank(owner);
        voting.registerVoter(voter1);
        assertTrue(
            voting.registeredVoters(voter1),
            "Voter1 should be registered"
        );
    }

    function testVoteSuccess() public {
        vm.prank(owner);
        voting.startVoting();
        vm.prank(owner);
        voting.registerVoter(voter1);
        vm.prank(voter1);
        voting.vote(0); // Voter1 votes for Alice
        assertTrue(voting.hasVoted(voter1), "Voter1 should have voted");
        vm.prank(owner);
        VotingSystem.Candidate[] memory candidateList = voting.getCandidates();
        assertEq(candidateList[0].voteCount, 1, "Alice should have 1 vote");
    }

    function testDoubleVoteRevert() public {
        vm.prank(owner);
        voting.startVoting();
        vm.prank(owner);
        voting.registerVoter(voter2);
        vm.prank(voter2);
        voting.vote(1); // Voter2 votes for Bob
        vm.expectRevert(youHaveAlreadyvoted.selector);
        vm.prank(voter2);
        voting.vote(1); // Voter2 tries to vote again
    }

    function testUnregisteredVotersReverts() public {
        vm.prank(owner);
        voting.startVoting();
        vm.expectRevert();
        vm.prank(voter1);
        voting.vote(0); // Voter1 tries to vote without being registered
    }

    function testInvalidCandidateIndexReverts() public {
        vm.prank(owner);
        voting.startVoting();
        vm.prank(owner);
        voting.registerVoter(voter1);

        // Tell Foundry to expect the specific custom error with the correct argument
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingSystem.InvalidCandidateIndex.selector,
                10
            )
        );

        vm.prank(voter1);
        voting.vote(10); // 10 is an invalid candidate index
    }

    /*function testVoteRevertsAfterDeadline() public {
        voting.registerVoter(voter1);

        // Fast forward time to after the deadline
        uint deadline = voting.getVotingDeadline();
        vm.warp(deadline + 1); // Just 1 second after is enough

        vm.expectRevert(votingperiodover.selector);
        vm.prank(voter1);
        voting.vote(0); // Should revert
    }*/
    function testVoteRevertsAfterDeadline() public {
        vm.prank(owner);
        voting.startVoting();
        vm.prank(owner);
        voting.registerVoter(voter1);
        vm.warp(block.timestamp + votingDuration + 1); // Move time past the voting period
        vm.expectRevert(VotingSystem.VotingPeriodIsOver.selector);
        vm.prank(voter1);
        voting.vote(0); // Should revert
    }

    /*function testGetWinners() public {
        vm.prank(owner);
        voting.startVoting();
        // Register voters
        vm.prank(owner);
        voting.registerVoter(voter1);
        vm.prank(owner);
        voting.registerVoter(voter2);
        vm.prank(owner);
        voting.registerVoter(voter3);

        vm.prank(voter1);
        voting.vote(0); // Voter1 votes for Alice
        vm.prank(voter2);
        voting.vote(0); // Voter2 votes for Alice
        vm.prank(voter3);
        voting.vote(1); // Voter3 votes for Bob
        vm.prank(owner);
        voting.endVoting();
        vm.prank(owner);
        string memory winner = voting.getWinners();
        // You can now add an assertion if needed
        assertEq(winner, "Alice", "winner should be Alice ");
    } */
    function testGetWinners() public {
        // Make all owner-only calls under one prank
        vm.startPrank(owner);
        voting.startVoting();
        voting.registerVoter(voter1);
        voting.registerVoter(voter2);
        voting.registerVoter(voter3);
        vm.stopPrank();

        // Voters cast votes
        vm.prank(voter1);
        voting.vote(0); // Voter1 votes for Alice

        vm.prank(voter2);
        voting.vote(0); // Voter2 votes for Alice

        vm.prank(voter3);
        voting.vote(1); // Voter3 votes for Bob

        // Owner ends voting
        vm.prank(owner);
        voting.endVoting();

        // Owner gets winners
        vm.prank(owner);
        string memory winner = voting.getWinners();

        // Assert the result
        assertEq(winner, "Alice", "winner should be Alice");
    }

    /* function testGetWinnerswithNoCandidate() public {
        string[] memory emptyCandidateList;
        VotingSystem freshVoting = new VotingSystem(
            emptyCandidateList,
            votingDuration
        );

        freshVoting.registerVoter(voter1);
        freshVoting.registerVoter(voter2);
        freshVoting.registerVoter(voter3);

        vm.expectRevert(VotingSystem.NoCandidatesAvailable.selector);
        freshVoting.getWinners(); // Should revert
    }
*/
    function testGetWinnerWithNoVotes() public {
        vm.prank(owner);
        voting.registerVoter(voter1);
        vm.prank(owner);
        voting.registerVoter(voter2);
        vm.prank(owner);
        voting.registerVoter(voter3);

        vm.warp(block.timestamp + votingDuration + 1); // Move time past the voting period
        vm.expectRevert(VotingSystem.NoVotesCast.selector);
        vm.prank(owner);
        voting.getWinners(); // Should revert
    }

    function testOnlyOwnerCanRegisterVoter() public {
        vm.expectRevert("Only the owner can do this");
        vm.prank(voter1);
        voting.registerVoter(voter2); // Voter1 tries to register Voter2
    }

    function testOnlyOwnerCanAddCandidates() public {
        vm.expectRevert("Only the owner can do this");
        vm.prank(voter1);
        voting.addCandidate("David"); // Voter1 tries to add a candidate
    }

    function testOnlyOwnerCanEndVoting() public {
        vm.expectRevert("Only the owner can do this");
        vm.prank(voter1);
        voting.endVoting(); // Voter1 tries to end voting
    }

    function testIfTheCanidatesSetUpIsCorrect() public {
        VotingSystem.Candidate[] memory candidatesList = voting.getCandidates();

        // ckecking out if the candidtates are exactly 3
        assertEq(candidatesList.length, 3, "Candidates count must be 3");

        // check if each votecount is 0
        for (uint i = 0; i < candidatesList.length; i++) {
            assertEq(candidatesList[i].voteCount, 0, "Vote count must be 0");
        }
    }

    function testIfRegisteredVotersAppearInRegisteredVoters() public {
        vm.startPrank(owner);
        voting.registerVoter(voter1);
        voting.registerVoter(voter2);
        voting.registerVoter(voter3);
        vm.stopPrank();

        assertTrue(
            voting.registeredVoters(voter1),
            "Voter1 should be registered"
        );

        assertTrue(
            voting.registeredVoters(voter2),
            "Voter2 should be registered"
        );

        assertTrue(
            voting.registeredVoters(voter3),
            "voter3 should be registered"
        );
    }

    function testRegisteredVotersEmitevent() public {
        // Expect the voterRegistered event to be emitted with voter1
        vm.expectEmit(true, false, false, false);
        emit VotingSystem.voterRegistered(voter1);
        vm.prank(owner);
        voting.registerVoter(voter1);
    }

    function testRevertIfRegisteredVoterTriesToRegisterAgain() public {
        vm.prank(owner);
        // First registration should work
        voting.registerVoter(voter1);

        // Expect revert on second registration
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingSystem.VoterAlreadyRegistered.selector,
                voter1
            )
        );
        vm.prank(owner);
        voting.registerVoter(voter1); // should fail
    }

    function testAddCandidateEmitEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, false, false, false);
        emit VotingSystem.candidatesAdded("David");

        voting.addCandidate("David");
    }

    function testRevertifCandidteAlreadyExist() public {
        vm.prank(owner);
        voting.addCandidate("David");
        vm.expectRevert("Candidate already exists");
        vm.prank(owner);
        voting.addCandidate("David");
    }

    function testforincreasevotecount() public {
        vm.startPrank(owner);
        voting.startVoting();
        voting.registerVoter(voter1);
        vm.stopPrank();
        vm.prank(voter1);
        voting.vote(0); // Voter1 votes for Alice
        vm.prank(owner);
        VotingSystem.Candidate[] memory candidateList = voting.getCandidates();
        assertEq(candidateList[0].voteCount, 1, "Alice should have 1 vote");
    }

    function testifVoterisAddedtohasVotedlist() public {
        vm.startPrank(owner);
        voting.startVoting();
        voting.registerVoter(voter1);
        vm.stopPrank();
        vm.prank(voter1);
        voting.vote(0); // voter1 votes for alice
        assertTrue(
            voting.hasVoted(voter1),
            "Voter1 should be in the hasVoted list"
        );
    }

    function testcanstartVoting() public {
        //simulate the owner
        vm.prank(owner);
        // start the voting
        voting.startVoting();
        // asert that the voting status is true
        bool status = voting.getVotingStatus();
        assertTrue(status, "Voting should be started");
    }

    function testcanendvoting() public {
        //simulate the owner
        vm.startPrank(owner);
        // start the voting
        voting.startVoting();
        //end the voting
        voting.endVoting();
        // asert that the voting status is false
        bool status = voting.getVotingStatus();
        vm.stopPrank();
        assertFalse(status, "Voting should be ended");
    }

    function testResetElectionClearsVoterrsVotesandCandidatesdata() public {
        vm.prank(owner);
        voting.startVoting();
        vm.prank(owner);
        voting.registerVoter(voter1);
        vm.prank(voter1);
        voting.vote(0); // Voter1 votes for Alice

        // Call the owner to reset election
        vm.prank(owner);
        string[] memory newCandidates = new string[](2);
        newCandidates[0] = "Zara";
        newCandidates[1] = "John";
        voting.resetElection(newCandidates, 2 days);

        // ✅ Check if registeredVoters list is cleared
        assertEq(
            voting.getRegisteredVoterList().length,
            0,
            "registeredVoter list should be empty after calling resetElection"
        );

        // ✅ Check if hasVoted list is cleared
        assertEq(
            voting.gethasvotedList().length,
            0,
            "hasVoted list should be empty after calling resetElection"
        );

        // ✅ Check that new candidates were added correctly
        vm.prank(owner);
        (string[] memory names, uint[] memory votes) = voting.getResults();
        assertEq(
            names.length,
            2,
            "Candidate list should have 2 new candidates"
        );
        assertEq(names[0], "Zara", "First candidate should be Zara");
        assertEq(names[1], "John", "Second candidate should be John");
        assertEq(votes[0], 0, "Zara should have 0 votes after reset");
        assertEq(votes[1], 0, "John should have 0 votes after reset");
    }

    function testResetElectionSetsNewDeadline() public {
        // Start the voting
        vm.prank(owner);
        voting.startVoting();

        // Call the owner to reset election
        vm.prank(owner);
        string[] memory newCandidates = new string[](2);
        newCandidates[0] = "Zara";
        newCandidates[1] = "John";
        voting.resetElection(newCandidates, 2 days);
        // Check if the voting deadline is set to 2 days from now
        uint newDeadLine = block.timestamp + 2 days;
        assertEq(
            voting.getVotingDeadline(),
            newDeadLine,
            "Voting deadline should be set to 2 days from now"
        );
    }

    function testRevertIfDuplicateCandidatesAreAdded() public {
        // start the voting
        vm.prank(owner);
        voting.startVoting();
        // add a candidate
        vm.prank(owner);
        voting.addCandidate("Alice");
        // try to add the same candidate again
        vm.expectRevert("Candidate already exists");
        vm.prank(owner);
        voting.addCandidate("Alice");
    }

    function testifGetWinnerreturnsthecorrectwinner() public {
        vm.startPrank(owner);
        voting.startVoting();
        //register voters
        voting.registerVoter(voter1);
        voting.registerVoter(voter2);
        voting.registerVoter(voter3);
        vm.stopPrank();
        // start voting
        vm.prank(voter1);
        voting.vote(0); // Voter1 votes for Alice
        vm.prank(voter2);
        voting.vote(0); // Voter2 votes for Alice
        vm.prank(voter3);
        voting.vote(1); // Voter3 votes for Bob
        vm.prank(owner);
        voting.endVoting();
        // checking if it brings up the correct winner
        vm.prank(owner);
        string memory winner = voting.getWinners();
        assertEq(winner, "Alice", "Winner should be Alice");
    }

    /* function testRevertIfNoCandidateIsaddedAndGetWinneriscalled() public {
        // deploy a new contract with no candidates
        string[] memory emptycandidatelist;
        uint256 twoDays = 2 days;

        VotingSystem freshvoting = new VotingSystem(
            emptycandidatelist,
            twoDays
        );

        // start voting
        vm.prank(owner);
        voting.startVoting();
        // end voting
        vm.prank(owner);
        voting.endVoting();
        // expecting to revert
        vm.expectRevert(VotingSystem.NoCandidatesAvailable.selector);
        voting.getWinners(); // Should revert */

    function testRevertGetWinnerIfVotingIsStillOngoing() public {
        vm.prank(owner);
        voting.startVoting();
        vm.expectRevert(VotingSystem.VotingStillOngoing.selector);
        vm.prank(owner);
        voting.getWinners(); // Should revert
    }

    function testToAllowVoterToVoteForACandidate() public {
        vm.prank(owner);
        voting.startVoting();
        // Register the voter
        vm.prank(owner);
        voting.registerVoter(voter1);
        // Voter1 votes for Alice
        vm.prank(voter1);
        voting.vote(0);
        // Check if the vote was counted
        vm.prank(owner);
        VotingSystem.Candidate[] memory candidates = voting.getCandidates();
        assertEq(candidates[0].voteCount, 1, "Alice should have 1 vote");
    }

    function testVoteRevertIfVotingIsNotStarted() public {
        vm.prank(owner);
        voting.registerVoter(voter1);
        // Attempt to vote before starting the voting
        vm.prank(voter1);
        // Expect the revert with the custom error
        vm.expectRevert(VotingSystem.VotingHasNotStarted.selector);
        voting.vote(0); // Should revert
    }

    function testRevertIfVotingIsEnded() public {
        vm.prank(owner);
        voting.startVoting();
        vm.prank(owner);
        voting.endVoting();
        vm.expectRevert(VotingSystem.VotingHasNotStarted.selector);
        voting.vote(0); // Should revert
    }

    function testifaddcandidatesaddcandidatescorrectly() public {
        vm.prank(owner);
        voting.addCandidate("paul");
        VotingSystem.Candidate[] memory candidates = voting.getCandidates();
        assertEq(candidates[3].name, "paul", "Candidate name should be paul");
    }

    function testifaddcandidatesemitseventcorrectly() public {
        string memory newcandidate = "dave";
        // Expect the event to be emitted
        vm.expectEmit(true, false, false, false);
        emit VotingSystem.candidatesAdded(newcandidate);
        // Add the candidate
        vm.prank(owner);
        voting.addCandidate(newcandidate);
        // Check if the candidate was added
        VotingSystem.Candidate[] memory candidates = voting.getCandidates();
        assertEq(
            candidates[3].name,
            newcandidate,
            "Candidate name should be dave"
        );
    }

    function testifstartingvotingchangesvotingstatus() public {
        vm.prank(owner);
        voting.startVoting();
        bool status = voting.getVotingStatus();
        assertTrue(status, "voting status should be true after starting");
    }

    function teststartvotingshouldfailifalreadystarted() public {
        vm.prank(owner);
        voting.startVoting();
        vm.expectRevert("Already voting");
        vm.prank(owner);
        voting.startVoting(); // Should revert
    }

    function testifregistervoteremitseventcorrectly() public {
        // expect the event to be emitted
        vm.expectEmit(true, false, false, false);
        emit VotingSystem.voterRegistered(voter1);
        // register the voter
        vm.prank(owner);
        voting.registerVoter(voter1);
        // check if the voter was registered
        assertTrue(voting.registeredVoters(voter1), "voter already registered");
    }
}
