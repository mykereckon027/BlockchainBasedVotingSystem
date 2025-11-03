// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title VotingSystem 
 * @notice Simple on-chain voting contract with phases, events, and protections
 * @dev Owner manages candidates and election lifecycle. Voters register themselves.
 */
contract VotingSystem {
    /*//////////////////////////////////////////////////////////////
                               DATA STRUCTURES
    //////////////////////////////////////////////////////////////*/

    struct Candidate {
        string name;
        uint256 voteCount;
        bool exists;
    }

    enum Phase {
        Registration, // candidates can be added, voters can register
        Voting,       // registered voters can cast votes
        Ended         // voting ended, results can be read
    }

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    address public immutable i_owner;
    Phase public s_phase;

    // candidate id => Candidate
    mapping(uint256 => Candidate) private s_candidates;
    uint256 private s_candidateCount;

    // voter address => registered?
    mapping(address => bool) private s_registered;
    // voter address => voted?
    mapping(address => bool) private s_hasVoted;
    // voter address => voted candidate id
    mapping(address => uint256) private s_voteOf;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event CandidateAdded(uint256 indexed candidateId, string name);
    event VoterRegistered(address indexed voter);
    event VoteCast(address indexed voter, uint256 indexed candidateId);
    event PhaseChanged(Phase indexed newPhase);
    event ElectionReset();

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error NotOwner();
    error AlreadyRegistered();
    error NotRegistered();
    error AlreadyVoted();
    error CandidateNotFound();
    error InvalidPhase();
    error CandidateExists();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        i_owner = msg.sender;
        s_phase = Phase.Registration;
    }

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    modifier inPhase(Phase expected) {
        if (s_phase != expected) revert InvalidPhase();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Add a candidate (owner only) during Registration phase
    function addCandidate(string calldata name) external onlyOwner inPhase(Phase.Registration) {
        // Avoid adding empty names
        bytes memory nm = bytes(name);
        require(nm.length > 0, "Candidate name required");

        // Basic uniqueness check: naive (string equality loop would be expensive),
        // we rely on owner discipline. We still mark candidate exists.
        uint256 id = s_candidateCount;
        s_candidates[id] = Candidate({name: name, voteCount: 0, exists: true});
        s_candidateCount++;
        emit CandidateAdded(id, name);
    }

    /// @notice Start voting (owner only). Transitions from Registration -> Voting
    function startVoting() external onlyOwner inPhase(Phase.Registration) {
        require(s_candidateCount > 0, "No candidates");
        s_phase = Phase.Voting;
        emit PhaseChanged(s_phase);
    }

    /// @notice End voting (owner only). Transitions Voting -> Ended
    function endVoting() external onlyOwner inPhase(Phase.Voting) {
        s_phase = Phase.Ended;
        emit PhaseChanged(s_phase);
    }

    /// @notice Reset election (owner only). Clears candidates and voters. Back to Registration.
    /// @dev Use with caution — this wipes on-chain state related to this election
    function resetElection() external onlyOwner {
        // reset candidate storage mapping
        for (uint256 i = 0; i < s_candidateCount; i++) {
            delete s_candidates[i];
        }
        s_candidateCount = 0;

        // Note: clearing per-voter mappings is expensive on-chain in general.
        // For simplicity here we do not iterate over all addresses (not possible),
        // but in testing / small deployments owner can redeploy if needed.
        // We emit an event to signal reset; frontends should treat this as a fresh election.
        s_phase = Phase.Registration;
        emit ElectionReset();
        emit PhaseChanged(s_phase);
    }

    /*//////////////////////////////////////////////////////////////
                              VOTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Register yourself as a voter during Registration phase
    function register() external inPhase(Phase.Registration) {
        if (s_registered[msg.sender]) revert AlreadyRegistered();
        s_registered[msg.sender] = true;
        emit VoterRegistered(msg.sender);
    }

    /// @notice Cast vote for candidateId during Voting phase
    function vote(uint256 candidateId) external inPhase(Phase.Voting) {
        if (!s_registered[msg.sender]) revert NotRegistered();
        if (s_hasVoted[msg.sender]) revert AlreadyVoted();
        if (candidateId >= s_candidateCount || !s_candidates[candidateId].exists) revert CandidateNotFound();

        s_candidates[candidateId].voteCount += 1;
        s_hasVoted[msg.sender] = true;
        s_voteOf[msg.sender] = candidateId;

        emit VoteCast(msg.sender, candidateId);
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTERS
    //////////////////////////////////////////////////////////////*/

    function getCandidate(uint256 candidateId) external view returns (string memory name, uint256 votes) {
        if (candidateId >= s_candidateCount || !s_candidates[candidateId].exists) revert CandidateNotFound();
        Candidate storage c = s_candidates[candidateId];
        return (c.name, c.voteCount);
    }

    function totalCandidates() external view returns (uint256) {
        return s_candidateCount;
    }

    function isRegistered(address voter) external view returns (bool) {
        return s_registered[voter];
    }

    function hasVoted(address voter) external view returns (bool) {
        return s_hasVoted[voter];
    }

    function votedFor(address voter) external view returns (uint256) {
        require(s_hasVoted[voter], "Voter hasn't voted");
        return s_voteOf[voter];
    }

    /// @notice Get winner candidate id (ties resolved by first found highest votes)
    function getWinner() external view inPhase(Phase.Ended) returns (uint256 winnerId, string memory winnerName, uint256 votes) {
        uint256 topId = 0;
        uint256 topVotes = 0;
        for (uint256 i = 0; i < s_candidateCount; i++) {
            Candidate storage c = s_candidates[i];
            if (c.exists && c.voteCount > topVotes) {
                topVotes = c.voteCount;
                topId = i;
            }
        }
        return (topId, s_candidates[topId].name, topVotes);
    }
}
