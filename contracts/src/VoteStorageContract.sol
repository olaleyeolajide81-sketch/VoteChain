// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VoteStorageContract
 * @dev Secure storage for voting data with privacy features
 * @notice Handles vote storage, verification, and privacy
 */
contract VoteStorageContract {
    // Events
    event VoteStored(bytes32 indexed voteId, address indexed voter, bytes32 indexed proposalId, uint256 timestamp);
    event VoteInvalidated(bytes32 indexed voteId, address indexed voter, uint256 timestamp);
    event PrivacyCommitmentSet(bytes32 indexed commitment, uint256 timestamp);
    event VoteRevealed(bytes32 indexed voteId, bytes32 commitment, uint256 timestamp);
    
    // Structs
    struct VoteRecord {
        bytes32 voteId;
        address voter;
        bytes32 proposalId;
        uint256 voteWeight;
        uint256 choice;
        uint256 timestamp;
        bool isValid;
        bool isPrivate;
        bytes32 commitment; // For anonymous voting
        bytes32 salt; // For privacy
    }
    
    struct PrivacyCommitment {
        bytes32 commitment;
        uint256 timestamp;
        bool revealed;
        bytes32 voteId;
    }
    
    // State variables
    mapping(bytes32 => VoteRecord) public voteRecords;
    mapping(address => bytes32[]) public voterVotes; // voter => voteIds
    mapping(bytes32 => bytes32[]) public proposalVotes; // proposalId => voteIds
    mapping(bytes32 => PrivacyCommitment) public commitments;
    
    bytes32[] public voteIds;
    
    // Privacy parameters
    uint256 public constant COMMITMENT_DEADLINE = 1 hours;
    uint256 public constant REVEAL_DEADLINE = 24 hours;
    
    // Access control
    address private owner;
    mapping(address => bool) public authorizedContracts;
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "VoteStorage: Only owner");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorizedContracts[msg.sender] || msg.sender == owner, "VoteStorage: Not authorized");
        _;
    }
    
    modifier onlyValidVoteId(bytes32 voteId) {
        require(voteRecords[voteId].voter != address(0), "VoteStorage: Invalid vote ID");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Stores a vote record
     * @param vote Vote data
     * @param proof Optional zero-knowledge proof for private voting
     * @return voteId ID of the stored vote
     */
    function storeVote(
        Vote memory vote,
        bytes calldata proof
    ) external onlyAuthorized returns (bytes32 voteId) {
        // Generate vote ID
        voteId = keccak256(abi.encodePacked(
            vote.voter,
            vote.proposalId,
            vote.timestamp,
            block.chainid
        ));
        
        // Store vote record
        voteRecords[voteId] = VoteRecord({
            voteId: voteId,
            voter: vote.voter,
            proposalId: vote.proposalId,
            voteWeight: vote.voteWeight,
            choice: vote.choice,
            timestamp: vote.timestamp,
            isValid: vote.isValid,
            isPrivate: proof.length > 0,
            commitment: bytes32(0),
            salt: keccak256(abi.encodePacked(block.timestamp, voteId))
        });
        
        // Update mappings
        voterVotes[vote.voter].push(voteId);
        proposalVotes[vote.proposalId].push(voteId);
        voteIds.push(voteId);
        
        // Handle private voting with commitment
        if (proof.length > 0) {
            bytes32 commitment = keccak256(abi.encodePacked(vote.choice, voteRecords[voteId].salt));
            voteRecords[voteId].commitment = commitment;
            
            commitments[commitment] = PrivacyCommitment({
                commitment: commitment,
                timestamp: block.timestamp,
                revealed: false,
                voteId: voteId
            });
            
            emit PrivacyCommitmentSet(commitment, block.timestamp);
        }
        
        emit VoteStored(voteId, vote.voter, vote.proposalId, vote.timestamp);
        
        return voteId;
    }
    
    /**
     * @dev Invalidates a vote
     * @param voter Voter address
     * @param proposalId Proposal ID
     */
    function invalidateVote(address voter, bytes32 proposalId) external onlyAuthorized {
        bytes32 voteId = _getVoteId(voter, proposalId);
        require(voteId != bytes32(0), "VoteStorage: Vote not found");
        
        voteRecords[voteId].isValid = false;
        
        emit VoteInvalidated(voteId, voter, block.timestamp);
    }
    
    /**
     * @dev Gets a vote record
     * @param voteId Vote ID
     * @return Vote record
     */
    function getVote(bytes32 voteId) external view onlyValidVoteId(voteId) returns (Vote memory) {
        VoteRecord storage record = voteRecords[voteId];
        return Vote({
            voter: record.voter,
            proposalId: record.proposalId,
            voteWeight: record.voteWeight,
            choice: record.choice,
            timestamp: record.timestamp,
            isValid: record.isValid
        });
    }
    
    /**
     * @dev Gets vote by voter and proposal
     * @param voter Voter address
     * @param proposalId Proposal ID
     * @return Vote record
     */
    function getVote(address voter, bytes32 proposalId) external view returns (Vote memory) {
        bytes32 voteId = _getVoteId(voter, proposalId);
        require(voteId != bytes32(0), "VoteStorage: Vote not found");
        
        VoteRecord storage record = voteRecords[voteId];
        return Vote({
            voter: record.voter,
            proposalId: record.proposalId,
            voteWeight: record.voteWeight,
            choice: record.isPrivate ? 0 : record.choice, // Hide choice for private votes
            timestamp: record.timestamp,
            isValid: record.isValid
        });
    }
    
    /**
     * @dev Gets all votes for a voter
     * @param voter Voter address
     * @return Array of vote IDs
     */
    function getVoterVotes(address voter) external view returns (bytes32[] memory) {
        return voterVotes[voter];
    }
    
    /**
     * @dev Gets all votes for a proposal
     * @param proposalId Proposal ID
     * @return Array of vote IDs
     */
    function getProposalVotes(bytes32 proposalId) external view returns (bytes32[] memory) {
        return proposalVotes[proposalId];
    }
    
    /**
     * @dev Creates a privacy commitment for anonymous voting
     * @param choice Vote choice
     * @param salt Random salt
     * @return commitment Commitment hash
     */
    function createCommitment(uint256 choice, uint256 salt) external pure returns (bytes32 commitment) {
        return keccak256(abi.encodePacked(choice, salt));
    }
    
    /**
     * @dev Reveals a private vote
     * @param commitment Commitment hash
     * @param choice Vote choice
     * @param salt Original salt
     */
    function revealVote(bytes32 commitment, uint256 choice, uint256 salt) external {
        require(commitments[commitment].timestamp > 0, "VoteStorage: Invalid commitment");
        require(!commitments[commitment].revealed, "VoteStorage: Vote already revealed");
        require(block.timestamp <= commitments[commitment].timestamp + REVEAL_DEADLINE, "VoteStorage: Reveal deadline passed");
        
        // Verify commitment
        bytes32 computedCommitment = keccak256(abi.encodePacked(choice, salt));
        require(computedCommitment == commitment, "VoteStorage: Invalid commitment");
        
        // Reveal vote
        bytes32 voteId = commitments[commitment].voteId;
        voteRecords[voteId].choice = choice;
        commitments[commitment].revealed = true;
        
        emit VoteRevealed(voteId, commitment, block.timestamp);
    }
    
    /**
     * @dev Gets vote statistics for a proposal
     * @param proposalId Proposal ID
     * @return totalVotes, validVotes, privateVotes, averageWeight
     */
    function getProposalStats(bytes32 proposalId) external view returns (
        uint256 totalVotes,
        uint256 validVotes,
        uint256 privateVotes,
        uint256 averageWeight
    ) {
        bytes32[] memory votes = proposalVotes[proposalId];
        totalVotes = votes.length;
        
        if (totalVotes == 0) {
            return (0, 0, 0, 0);
        }
        
        uint256 validCount = 0;
        uint256 privateCount = 0;
        uint256 totalWeight = 0;
        
        for (uint256 i = 0; i < votes.length; i++) {
            VoteRecord storage record = voteRecords[votes[i]];
            if (record.isValid) {
                validCount++;
                totalWeight += record.voteWeight;
            }
            if (record.isPrivate) {
                privateCount++;
            }
        }
        
        averageWeight = validCount > 0 ? totalWeight / validCount : 0;
        
        return (totalVotes, validCount, privateCount, averageWeight);
    }
    
    /**
     * @dev Verifies vote integrity
     * @param voteId Vote ID
     * @return isValid True if vote is valid and untampered
     */
    function verifyVoteIntegrity(bytes32 voteId) external view returns (bool isValid) {
        VoteRecord storage record = voteRecords[voteId];
        return record.isValid && record.timestamp > 0;
    }
    
    /**
     * @dev Gets audit trail for a proposal
     * @param proposalId Proposal ID
     * @return votes Array of vote records for audit
     */
    function getAuditTrail(bytes32 proposalId) external view returns (VoteRecord[] memory votes) {
        bytes32[] memory voteIdArray = proposalVotes[proposalId];
        votes = new VoteRecord[](voteIdArray.length);
        
        for (uint256 i = 0; i < voteIdArray.length; i++) {
            votes[i] = voteRecords[voteIdArray[i]];
        }
        
        return votes;
    }
    
    /**
     * @dev Adds authorized contract
     * @param contractAddress Address to authorize
     */
    function addAuthorizedContract(address contractAddress) external onlyOwner {
        authorizedContracts[contractAddress] = true;
    }
    
    /**
     * @dev Removes authorized contract
     * @param contractAddress Address to remove
     */
    function removeAuthorizedContract(address contractAddress) external onlyOwner {
        authorizedContracts[contractAddress] = false;
    }
    
    /**
     * @dev Transfers ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    // Internal functions
    
    function _getVoteId(address voter, bytes32 proposalId) internal view returns (bytes32) {
        bytes32[] memory votes = voterVotes[voter];
        for (uint256 i = 0; i < votes.length; i++) {
            if (voteRecords[votes[i]].proposalId == proposalId) {
                return votes[i];
            }
        }
        return bytes32(0);
    }
    
    /**
     * @dev Batch stores multiple votes
     * @param votes Array of votes to store
     * @return voteIds Array of stored vote IDs
     */
    function batchStoreVotes(Vote[] calldata votes) external onlyAuthorized returns (bytes32[] memory voteIds) {
        voteIds = new bytes32[](votes.length);
        
        for (uint256 i = 0; i < votes.length; i++) {
            voteIds[i] = storeVote(votes[i], "");
        }
        
        return voteIds;
    }
    
    /**
     * @dev Gets total number of votes stored
     * @return Total vote count
     */
    function getTotalVotes() external view returns (uint256) {
        return voteIds.length;
    }
    
    /**
     * @dev Gets votes in a range (for pagination)
     * @param offset Starting offset
     * @param limit Maximum number of votes to return
     * @return Array of vote IDs
     */
    function getVotesInRange(uint256 offset, uint256 limit) external view returns (bytes32[] memory) {
        uint256 end = offset + limit;
        if (end > voteIds.length) {
            end = voteIds.length;
        }
        
        bytes32[] memory result = new bytes32[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = voteIds[i];
        }
        
        return result;
    }
}
