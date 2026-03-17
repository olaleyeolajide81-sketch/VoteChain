// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TokenContract.sol";
import "./VotingContract.sol";

/**
 * @title GovernanceContract
 * @dev Governance mechanisms for VoteChain platform
 * @notice Handles delegation, staking, and governance parameters
 */
contract GovernanceContract {
    // Events
    event DelegationSet(address indexed delegator, address indexed delegatee, uint256 timestamp);
    event DelegationRevoked(address indexed delegator, address indexed delegatee, uint256 timestamp);
    event StakeDeposited(address indexed staker, uint256 amount, uint256 lockPeriod, uint256 timestamp);
    event StakeWithdrawn(address indexed staker, uint256 amount, uint256 timestamp);
    event GovernanceParameterUpdated(string parameter, uint256 oldValue, uint256 newValue);
    event EmergencyActionTriggered(string action, address indexed initiator, uint256 timestamp);
    
    // Structs
    struct Delegation {
        address delegator;
        address delegatee;
        uint256 timestamp;
        bool isActive;
    }
    
    struct Stake {
        address staker;
        uint256 amount;
        uint256 lockPeriod;
        uint256 startTime;
        uint256 votingPower;
        bool isActive;
    }
    
    struct GovernanceParameter {
        string name;
        uint256 value;
        uint256 lastUpdated;
        bool isActive;
    }
    
    // State variables
    TokenContract public governanceToken;
    VotingContract public votingContract;
    
    mapping(address => address) public delegations; // delegator => delegatee
    mapping(address => Stake) public stakes;
    mapping(address => uint256) public totalVotingPower;
    mapping(string => GovernanceParameter) public parameters;
    
    uint256 public constant MIN_STAKE_AMOUNT = 1000 * 10**18; // 1000 tokens
    uint256 public constant MAX_LOCK_PERIOD = 365 days;
    uint256 public constant MIN_LOCK_PERIOD = 7 days;
    uint256 public constant UNSTAKE_DELAY = 7 days;
    
    // Governance parameters
    string public constant PARAM_MIN_PROPOSAL_THRESHOLD = "MIN_PROPOSAL_THRESHOLD";
    string public constant PARAM_VOTING_PERIOD = "VOTING_PERIOD";
    string public constant PARAM_QUORUM_REQUIRED = "QUORUM_REQUIRED";
    string public constant PARAM_EXECUTION_DELAY = "EXECUTION_DELAY";
    
    address private owner;
    bool public emergencyMode;
    mapping(address => bool) public emergencyPausers;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Governance: Only owner");
        _;
    }
    
    modifier onlyEmergencyPauser() {
        require(emergencyPausers[msg.sender] || msg.sender == owner, "Governance: Not authorized");
        _;
    }
    
    modifier notInEmergency() {
        require(!emergencyMode, "Governance: Emergency mode active");
        _;
    }
    
    constructor(address _tokenAddress, address _votingAddress) {
        owner = msg.sender;
        governanceToken = TokenContract(_tokenAddress);
        votingContract = VotingContract(_votingAddress);
        
        // Initialize default parameters
        _initializeParameters();
    }
    
    /**
     * @dev Sets voting delegation
     * @param delegatee Address to delegate voting power to
     */
    function setDelegation(address delegatee) external notInEmergency {
        require(delegatee != msg.sender, "Governance: Cannot delegate to self");
        require(delegatee != address(0), "Governance: Invalid delegatee");
        
        // Remove existing delegation if any
        if (delegations[msg.sender] != address(0)) {
            _updateVotingPower(delegations[msg.sender], false);
        }
        
        // Set new delegation
        delegations[msg.sender] = delegatee;
        _updateVotingPower(delegatee, true);
        
        emit DelegationSet(msg.sender, delegatee, block.timestamp);
    }
    
    /**
     * @dev Revokes voting delegation
     */
    function revokeDelegation() external notInEmergency {
        require(delegations[msg.sender] != address(0), "Governance: No delegation to revoke");
        
        address delegatee = delegations[msg.sender];
        delegations[msg.sender] = address(0);
        
        _updateVotingPower(delegatee, false);
        _updateVotingPower(msg.sender, true);
        
        emit DelegationRevoked(msg.sender, delegatee, block.timestamp);
    }
    
    /**
     * @dev Stakes tokens for governance participation
     * @param amount Amount of tokens to stake
     * @param lockPeriod Lock period in seconds
     */
    function stakeTokens(uint256 amount, uint256 lockPeriod) external notInEmergency {
        require(amount >= MIN_STAKE_AMOUNT, "Governance: Insufficient stake amount");
        require(lockPeriod >= MIN_LOCK_PERIOD && lockPeriod <= MAX_LOCK_PERIOD, "Governance: Invalid lock period");
        
        // Transfer tokens to this contract
        require(governanceToken.transferFrom(msg.sender, address(this), amount), "Governance: Transfer failed");
        
        // Create or update stake
        if (stakes[msg.sender].isActive) {
            // Add to existing stake
            stakes[msg.sender].amount += amount;
            stakes[msg.sender].votingPower = _calculateVotingPower(stakes[msg.sender].amount, stakes[msg.sender].lockPeriod);
        } else {
            // Create new stake
            stakes[msg.sender] = Stake({
                staker: msg.sender,
                amount: amount,
                lockPeriod: lockPeriod,
                startTime: block.timestamp,
                votingPower: _calculateVotingPower(amount, lockPeriod),
                isActive: true
            });
        }
        
        _updateVotingPower(msg.sender, true);
        
        emit StakeDeposited(msg.sender, amount, lockPeriod, block.timestamp);
    }
    
    /**
     * @dev Withdraws staked tokens
     * @param amount Amount of tokens to withdraw
     */
    function unstakeTokens(uint256 amount) external notInEmergency {
        require(stakes[msg.sender].isActive, "Governance: No active stake");
        require(amount <= stakes[msg.sender].amount, "Governance: Insufficient staked amount");
        require(block.timestamp >= stakes[msg.sender].startTime + stakes[msg.sender].lockPeriod, "Governance: Tokens still locked");
        
        // Update stake
        stakes[msg.sender].amount -= amount;
        stakes[msg.sender].votingPower = _calculateVotingPower(stakes[msg.sender].amount, stakes[msg.sender].lockPeriod);
        
        if (stakes[msg.sender].amount == 0) {
            stakes[msg.sender].isActive = false;
        }
        
        _updateVotingPower(msg.sender, true);
        
        // Transfer tokens back
        require(governanceToken.transfer(msg.sender, amount), "Governance: Transfer failed");
        
        emit StakeWithdrawn(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @dev Updates governance parameter
     * @param parameter Parameter name
     * @param value New parameter value
     */
    function updateParameter(string calldata parameter, uint256 value) external onlyOwner {
        require(_isValidParameter(parameter), "Governance: Invalid parameter");
        
        uint256 oldValue = parameters[parameter].value;
        parameters[parameter] = GovernanceParameter({
            name: parameter,
            value: value,
            lastUpdated: block.timestamp,
            isActive: true
        });
        
        emit GovernanceParameterUpdated(parameter, oldValue, value);
    }
    
    /**
     * @dev Triggers emergency action
     * @param action Emergency action type
     */
    function triggerEmergencyAction(string calldata action) external onlyEmergencyPauser {
        emergencyMode = true;
        
        // Implement specific emergency actions
        if (keccak256(bytes(action)) == keccak256(bytes("PAUSE_ALL"))) {
            // Pause all voting and staking operations
        } else if (keccak256(bytes(action)) == keccak256(bytes("FREEZE_TOKENS"))) {
            // Freeze all token transfers
        }
        
        emit EmergencyActionTriggered(action, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Gets total voting power including delegated power
     * @param voter Address to check
     * @return Total voting power
     */
    function getTotalVotingPower(address voter) external view returns (uint256) {
        uint256 ownPower = stakes[voter].votingPower;
        uint256 delegatedPower = 0;
        
        // Add power from delegations to this voter
        // This would require iterating through all delegations in practice
        // For simplicity, we'll use a separate tracking system
        
        return ownPower + delegatedPower;
    }
    
    /**
     * @dev Gets stake information
     * @param staker Address to check
     * @return Stake details
     */
    function getStakeInfo(address staker) external view returns (
        uint256 amount,
        uint256 lockPeriod,
        uint256 startTime,
        uint256 votingPower,
        bool isActive
    ) {
        Stake memory stake = stakes[staker];
        return (
            stake.amount,
            stake.lockPeriod,
            stake.startTime,
            stake.votingPower,
            stake.isActive
        );
    }
    
    /**
     * @dev Gets governance parameter value
     * @param parameter Parameter name
     * @return Parameter value
     */
    function getParameter(string calldata parameter) external view returns (uint256) {
        return parameters[parameter].value;
    }
    
    /**
     * @dev Checks if address can vote
     * @param voter Address to check
     * @return True if can vote
     */
    function canVote(address voter) external view returns (bool) {
        return totalVotingPower[voter] > 0;
    }
    
    /**
     * @dev Adds emergency pauser
     * @param pauser Address to add
     */
    function addEmergencyPauser(address pauser) external onlyOwner {
        emergencyPausers[pauser] = true;
    }
    
    /**
     * @dev Removes emergency pauser
     * @param pauser Address to remove
     */
    function removeEmergencyPauser(address pauser) external onlyOwner {
        emergencyPausers[pauser] = false;
    }
    
    /**
     * @dev Transfers ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    // Internal functions
    
    function _updateVotingPower(address voter, bool include) internal {
        uint256 power = stakes[voter].votingPower;
        
        if (include) {
            totalVotingPower[voter] = power;
        } else {
            totalVotingPower[voter] = 0;
        }
    }
    
    function _calculateVotingPower(uint256 amount, uint256 lockPeriod) internal pure returns (uint256) {
        // Voting power is proportional to amount and lock period
        // Longer lock periods get higher voting power
        uint256 lockBonus = (lockPeriod * 100) / MAX_LOCK_PERIOD; // 0-100% bonus
        return amount + (amount * lockBonus) / 100;
    }
    
    function _initializeParameters() internal {
        parameters[PARAM_MIN_PROPOSAL_THRESHOLD] = GovernanceParameter({
            name: PARAM_MIN_PROPOSAL_THRESHOLD,
            value: 1000 * 10**18, // 1000 tokens
            lastUpdated: block.timestamp,
            isActive: true
        });
        
        parameters[PARAM_VOTING_PERIOD] = GovernanceParameter({
            name: PARAM_VOTING_PERIOD,
            value: 7 days,
            lastUpdated: block.timestamp,
            isActive: true
        });
        
        parameters[PARAM_QUORUM_REQUIRED] = GovernanceParameter({
            name: PARAM_QUORUM_REQUIRED,
            value: 51, // 51%
            lastUpdated: block.timestamp,
            isActive: true
        });
        
        parameters[PARAM_EXECUTION_DELAY] = GovernanceParameter({
            name: PARAM_EXECUTION_DELAY,
            value: 1 days,
            lastUpdated: block.timestamp,
            isActive: true
        });
    }
    
    function _isValidParameter(string memory parameter) internal pure returns (bool) {
        return keccak256(bytes(parameter)) == keccak256(bytes(PARAM_MIN_PROPOSAL_THRESHOLD)) ||
               keccak256(bytes(parameter)) == keccak256(bytes(PARAM_VOTING_PERIOD)) ||
               keccak256(bytes(parameter)) == keccak256(bytes(PARAM_QUORUM_REQUIRED)) ||
               keccak256(bytes(parameter)) == keccak256(bytes(PARAM_EXECUTION_DELAY));
    }
}
