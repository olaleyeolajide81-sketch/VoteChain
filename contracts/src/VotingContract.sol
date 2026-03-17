// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenContract.sol";
import "./ProposalContract.sol";
import "./VoteStorageContract.sol";

/**
 * @title VotingContract
 * @dev Main voting contract for VoteChain platform on Stellar
 * @notice Handles secure voting mechanisms and vote counting
 */
contract VotingContract {
    // Events
    event VoteCast(address indexed voter, bytes32 indexed proposalId, uint256 voteWeight, uint256 timestamp);
    event VoteRevoked(address indexed voter, bytes32 indexed proposalId, uint256 timestamp);
    event VotingPeriodStarted(bytes32 indexed proposalId, uint256 startTime, uint256 endTime);
    event VotingPeriodEnded(bytes32 indexed proposalId, uint256 endTime);
    event QuorumReached(bytes32 indexed proposalId, uint256 totalWeight);
    
    // Structs
    struct Vote {
        address voter;
        bytes32 proposalId;
        uint256 voteWeight;
        uint256 choice; // For single choice: 0/1, for multiple choice: bitmask
        uint256 timestamp;
        bool isValid;
    }
    
    struct VotingPeriod {
        bytes32 proposalId;
        uint256 startTime;
        uint256 endTime;
        uint256 quorumRequired;
        uint256 totalVotesWeight;
        bool isActive;
        bool quorumReached;
    }
    
    // State variables
    TokenContract public governanceToken;
    ProposalContract public proposalContract;
    VoteStorageContract public voteStorage;
    
    mapping(bytes32 => VotingPeriod) public votingPeriods;
    mapping(address => mapping(bytes32 => bool)) public hasVoted;
    mapping(bytes32 => mapping(uint256 => uint256)) public voteResults; // proposalId => choice => weight
    
    uint256 public constant MIN_VOTING_PERIOD = 1 days;
    uint256 public constant MAX_VOTING_PERIOD = 30 days;
    uint256 public constant DEFAULT_QUORUM = 51; // 51%
    
    // Modifiers
    modifier onlyActiveProposal(bytes32 proposalId) {
        require(votingPeriods[proposalId].isActive, "Voting: Proposal not active");
        require(block.timestamp >= votingPeriods[proposalId].startTime, "Voting: Voting not started");
        require(block.timestamp <= votingPeriods[proposalId].endTime, "Voting: Voting period ended");
        _;
    }
    
    modifier onlyValidVoter(address voter) {
        require(governanceToken.balanceOf(voter) > 0, "Voting: Must hold governance tokens");
        require(!hasVoted[voter][msg.sender], "Voting: Already voted on this proposal");
        _;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == address(proposalContract) || msg.sender == owner(), "Voting: Not authorized");
        _;
    }
    
    address private owner;
    
    constructor(address _tokenAddress, address _proposalAddress, address _voteStorageAddress) {
        owner = msg.sender;
        governanceToken = TokenContract(_tokenAddress);
        proposalContract = ProposalContract(_proposalAddress);
        voteStorage = VoteStorageContract(_voteStorageAddress);
    }
    
    /**
     * @dev Starts voting period for a proposal
     * @param proposalId ID of the proposal
     * @param duration Voting period duration in seconds
     * @param quorumRequired Quorum percentage required (0-100)
     */
    function startVotingPeriod(
        bytes32 proposalId,
        uint256 duration,
        uint256 quorumRequired
    ) external onlyAuthorized {
        require(duration >= MIN_VOTING_PERIOD && duration <= MAX_VOTING_PERIOD, "Voting: Invalid duration");
        require(quorumRequired > 0 && quorumRequired <= 100, "Voting: Invalid quorum");
        
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + duration;
        
        votingPeriods[proposalId] = VotingPeriod({
            proposalId: proposalId,
            startTime: startTime,
            endTime: endTime,
            quorumRequired: quorumRequired,
            totalVotesWeight: 0,
            isActive: true,
            quorumReached: false
        });
        
        emit VotingPeriodStarted(proposalId, startTime, endTime);
    }
    
    /**
     * @dev Casts a vote on a proposal
     * @param proposalId ID of the proposal
     * @param choice Vote choice (0 for against, 1 for for, bitmask for multiple choice)
     * @param proof Optional zero-knowledge proof for anonymous voting
     */
    function castVote(
        bytes32 proposalId,
        uint256 choice,
        bytes calldata proof
    ) external onlyActiveProposal(proposalId) onlyValidVoter(msg.sender) {
        uint256 voteWeight = governanceToken.getVotingPower(msg.sender);
        require(voteWeight > 0, "Voting: No voting power");
        
        // Record vote
        hasVoted[msg.sender][proposalId] = true;
        votingPeriods[proposalId].totalVotesWeight += voteWeight;
        voteResults[proposalId][choice] += voteWeight;
        
        // Store vote in storage contract
        Vote memory vote = Vote({
            voter: msg.sender,
            proposalId: proposalId,
            voteWeight: voteWeight,
            choice: choice,
            timestamp: block.timestamp,
            isValid: true
        });
        
        voteStorage.storeVote(vote, proof);
        
        // Check if quorum is reached
        uint256 totalSupply = governanceToken.totalSupply();
        uint256 currentQuorum = (votingPeriods[proposalId].totalVotesWeight * 100) / totalSupply;
        
        if (currentQuorum >= votingPeriods[proposalId].quorumRequired && !votingPeriods[proposalId].quorumReached) {
            votingPeriods[proposalId].quorumReached = true;
            emit QuorumReached(proposalId, votingPeriods[proposalId].totalVotesWeight);
        }
        
        emit VoteCast(msg.sender, proposalId, voteWeight, block.timestamp);
    }
    
    /**
     * @dev Revokes a previously cast vote
     * @param proposalId ID of the proposal
     */
    function revokeVote(bytes32 proposalId) external onlyActiveProposal(proposalId) {
        require(hasVoted[msg.sender][proposalId], "Voting: No vote to revoke");
        
        // Get original vote from storage
        Vote memory originalVote = voteStorage.getVote(msg.sender, proposalId);
        require(originalVote.isValid, "Voting: Invalid vote");
        
        // Remove vote
        hasVoted[msg.sender][proposalId] = false;
        votingPeriods[proposalId].totalVotesWeight -= originalVote.voteWeight;
        voteResults[proposalId][originalVote.choice] -= originalVote.voteWeight;
        
        // Invalidate vote in storage
        voteStorage.invalidateVote(msg.sender, proposalId);
        
        emit VoteRevoked(msg.sender, proposalId, block.timestamp);
    }
    
    /**
     * @dev Ends voting period for a proposal
     * @param proposalId ID of the proposal
     */
    function endVotingPeriod(bytes32 proposalId) external onlyAuthorized {
        require(votingPeriods[proposalId].isActive, "Voting: Proposal not active");
        require(block.timestamp >= votingPeriods[proposalId].endTime, "Voting: Voting period not ended");
        
        votingPeriods[proposalId].isActive = false;
        emit VotingPeriodEnded(proposalId, block.timestamp);
    }
    
    /**
     * @dev Gets voting results for a proposal
     * @param proposalId ID of the proposal
     * @return results Array of choice weights
     */
    function getVotingResults(bytes32 proposalId) external view returns (uint256[] memory results) {
        // This would return results based on proposal type
        // Implementation depends on proposal structure
        results = new uint256[](2); // For simple yes/no votes
        results[0] = voteResults[proposalId][0]; // Against
        results[1] = voteResults[proposalId][1]; // For
        return results;
    }
    
    /**
     * @dev Checks if a proposal has reached quorum
     * @param proposalId ID of the proposal
     * @return True if quorum is reached
     */
    function isQuorumReached(bytes32 proposalId) external view returns (bool) {
        return votingPeriods[proposalId].quorumReached;
    }
    
    /**
     * @dev Gets voting power of an address
     * @param voter Address to check
     * @return Voting power
     */
    function getVotingPower(address voter) external view returns (uint256) {
        return governanceToken.getVotingPower(voter);
    }
    
    /**
     * @dev Gets remaining voting time for a proposal
     * @param proposalId ID of the proposal
     * @return Remaining time in seconds
     */
    function getRemainingVotingTime(bytes32 proposalId) external view returns (uint256) {
        if (block.timestamp >= votingPeriods[proposalId].endTime) {
            return 0;
        }
        return votingPeriods[proposalId].endTime - block.timestamp;
    }
    
    /**
     * @dev Transfers ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Voting: Only owner");
        owner = newOwner;
    }
}
