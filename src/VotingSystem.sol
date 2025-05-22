// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/* custom error */
error youHaveAlreadyvoted();

contract VotingSystem {
    address public owner;
    uint private VotingDeadline;
    bool private VotingStatus;

    mapping(address => bool) public registeredVoters;
    mapping(address => bool) public hasVoted;
    mapping(string => bool) public candidatesExists;

    address[] private registeredVoterList;
    address[] private hasVotedList;

    struct Candidate {
        string name;
        uint voteCount;
    }

    Candidate[] private candidatesList;

    constructor(string[] memory candidateNames, uint _duration) {
        owner = msg.sender;
        setvotingdeadline(_duration);

        for (uint i = 0; i < candidateNames.length; i++) {
            candidatesList.push(Candidate(candidateNames[i], 0));
        }
    }

    // ERRORS
    error NoVotesCast();
    error NoCandidatesAvailable();
    error VotingPeriodIsOver();
    error InvalidCandidateIndex(uint index);
    error VoterAlreadyRegistered(address voter);
    error VotingStillOngoing();
    error VotingHasNotStarted();
    error VoterNotRegistered(address voter);

    // EVENTS
    // Events are used to notify other contracts of changes in the state of a contract or trigger an action.
    event voted(uint candidateIndex);
    event voterRegistered(address indexed voter);
    event candidatesAdded(string indexed name);
    event votingStarted();
    event votingEnded();
    event resultsGenerated();

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can do this");
        _;
    }

    function addCandidate(string memory _name) public onlyOwner {
        require(!candidatesExists[_name], "Candidate already exists");
        candidatesExists[_name] = true;
        candidatesList.push(Candidate(_name, 0));
        emit candidatesAdded(_name);
    }

    /*function removeCandidate(string memory _name) public onlyOwner {
        require(candidatesExists[_name], "Candidate does not exist");
        candidatesExists[_name] = false;

        for (uint i = 0; i < candidatesList.length; i++) {
            if (keccak256(abi.encodePacked(candidatesList[i].name)) ==
                keccak256(abi.encodePacked(_name))) {
                delete candidatesList[i];
                break;
            }
        }
    }*/
    function registerVoter(address _voter) public onlyOwner {
        if (registeredVoters[_voter]) revert VoterAlreadyRegistered(_voter);
        registeredVoters[_voter] = true;
        registeredVoterList.push(_voter);
        emit voterRegistered(_voter);
    }

    function vote(uint _candidateIndex) public {
        if (!VotingStatus) revert VotingHasNotStarted(); // Voting is not active
        if (!registeredVoters[msg.sender])
            revert VoterNotRegistered(msg.sender);
        if (hasVoted[msg.sender])
            revert youHaveAlreadyvoted(); /*(msg.sender);*/
        if (_candidateIndex >= candidatesList.length)
            revert InvalidCandidateIndex(_candidateIndex);
        if (block.timestamp >= VotingDeadline) revert VotingPeriodIsOver();

        candidatesList[_candidateIndex].voteCount += 1;
        hasVoted[msg.sender] = true;
        hasVotedList.push(msg.sender);
        emit voted(_candidateIndex);
    }

    function setvotingdeadline(uint _duration) internal onlyOwner {
        // _duration should be in seconds (e.g., 2 days = 2 * 24 * 60 * 60 = 172800)
        VotingDeadline = block.timestamp + _duration; // Voting deadline is the current time plus the specified duration
    }

    function startVoting() public onlyOwner {
        require(!VotingStatus, "Already voting");
        VotingStatus = true;
        emit votingStarted();
    }

    function endVoting() public onlyOwner {
        require(VotingStatus, "voting has ended");
        VotingStatus = false;
        emit votingEnded();
    }

    function resetElection(
        string[] memory newCandidateNames,
        uint newdDuration
    ) public onlyOwner {
        delete candidatesList;
        for (uint i = 0; i < registeredVoterList.length; i++) {
            delete registeredVoters[registeredVoterList[i]];
        }
        delete registeredVoterList;

        for (uint i = 0; i < hasVotedList.length; i++) {
            delete hasVoted[hasVotedList[i]];
        }
        delete hasVotedList;

        for (uint i = 0; i < newCandidateNames.length; i++) {
            // Check for duplicates using your candidateExists mapping
            require(
                !candidatesExists[newCandidateNames[i]],
                "Duplicate candidate"
            );
            candidatesList.push(Candidate(newCandidateNames[i], 0));
            candidatesExists[newCandidateNames[i]] = true;
        }
        for (uint i = 0; i < candidatesList.length; i++) {
            delete candidatesExists[candidatesList[i].name];
        }
        VotingStatus = false;
        VotingDeadline = block.timestamp + newdDuration;
    }

    function getWinners()
        public
        view
        onlyOwner
        returns (string memory Winnersname)
    {
        if (!(candidatesList.length > 0)) revert NoCandidatesAvailable();
        if (VotingStatus) revert VotingStillOngoing();
        // require(candidatesList.length > 0, "No candidates available");

        uint maxVote = 0;
        uint winnerIndex = 0;

        for (uint i = 0; i < candidatesList.length; i++) {
            if (candidatesList[i].voteCount > maxVote) {
                maxVote = candidatesList[i].voteCount;
                winnerIndex = i;
            }
        }

        // revert  if nobody has voted
        if (maxVote == 0) revert NoVotesCast();
        return candidatesList[winnerIndex].name;
    }

    /* Getters fuction */
    function getCandidates() public view returns (Candidate[] memory) {
        return candidatesList;
    }

    function getResults()
        public
        view
        onlyOwner
        returns (string[] memory names, uint[] memory votes)
    {
        uint length = candidatesList.length;

        names = new string[](length);
        votes = new uint[](length);

        for (uint i = 0; i < length; i++) {
            names[i] = candidatesList[i].name;
            votes[i] = candidatesList[i].voteCount;
        }

        return (names, votes);
    }

    function getVotingStatus() public view returns (bool) {
        return VotingStatus;
    }

    function getVotingDeadline() public view returns (uint) {
        return VotingDeadline;
    }

    function getRegisteredVoterList() public view returns (address[] memory) {
        return registeredVoterList;
    }

    function gethasvotedList() public view returns (address[] memory) {
        return hasVotedList;
    }
}
