// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TokenContract
 * @dev Governance token for VoteChain platform
 * @notice ERC20 token with voting power and staking capabilities
 */
contract TokenContract {
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event VotingPowerUpdated(address indexed user, uint256 oldPower, uint256 newPower);
    event TokensLocked(address indexed user, uint256 amount, uint256 unlockTime);
    event TokensUnlocked(address indexed user, uint256 amount);
    
    // ERC20 variables
    string public name = "VoteChain Token";
    string public symbol = "VCT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Voting power tracking
    mapping(address => uint256) public votingPower;
    mapping(address => uint256) public lockedTokens;
    mapping(address => uint256) public unlockTime;
    
    // Governance variables
    address public owner;
    mapping(address => bool) public minters;
    mapping(address => bool) public burners;
    
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 1 billion tokens
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 million tokens
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Token: Only owner");
        _;
    }
    
    modifier onlyMinter() {
        require(minters[msg.sender] || msg.sender == owner, "Token: Not authorized to mint");
        _;
    }
    
    modifier onlyBurner() {
        require(burners[msg.sender] || msg.sender == owner, "Token: Not authorized to burn");
        _;
    }
    
    modifier sufficientBalance(address from, uint256 amount) {
        require(balanceOf[from] >= amount, "Token: Insufficient balance");
        _;
    }
    
    modifier notLocked(address user, uint256 amount) {
        require(balanceOf[user] - lockedTokens[user] >= amount, "Token: Tokens are locked");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        minters[owner] = true;
        burners[owner] = true;
        
        // Mint initial supply to owner
        _mint(owner, INITIAL_SUPPLY);
    }
    
    /**
     * @dev Transfers tokens
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return True if successful
     */
    function transfer(address to, uint256 amount) external sufficientBalance(msg.sender, amount) notLocked(msg.sender, amount) returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @dev Approves spending
     * @param spender Spender address
     * @param amount Amount to approve
     * @return True if successful
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @dev Transfers from approved spender
     * @param from Sender address
     * @param to Recipient address
     * @param amount Amount to transfer
     * @return True if successful
     */
    function transferFrom(address from, address to, uint256 amount) external sufficientBalance(from, amount) notLocked(from, amount) returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Token: Insufficient allowance");
        
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }
    
    /**
     * @dev Mints new tokens
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external onlyMinter {
        require(totalSupply + amount <= MAX_SUPPLY, "Token: Max supply reached");
        _mint(to, amount);
    }
    
    /**
     * @dev Burns tokens
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external onlyBurner {
        require(balanceOf[msg.sender] >= amount, "Token: Insufficient balance to burn");
        
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        
        _updateVotingPower(msg.sender);
        
        emit Transfer(msg.sender, address(0), amount);
    }
    
    /**
     * @dev Locks tokens for voting
     * @param amount Amount to lock
     * @param lockDuration Lock duration in seconds
     */
    function lockTokens(uint256 amount, uint256 lockDuration) external {
        require(amount > 0, "Token: Amount must be greater than 0");
        require(balanceOf[msg.sender] >= amount, "Token: Insufficient balance");
        require(lockDuration >= 1 days, "Token: Minimum lock duration is 1 day");
        
        // Check if tokens are already locked
        if (unlockTime[msg.sender] > block.timestamp) {
            // Add to existing lock
            require(block.timestamp + lockDuration > unlockTime[msg.sender], "Token: New lock must extend existing lock");
            unlockTime[msg.sender] = block.timestamp + lockDuration;
        } else {
            unlockTime[msg.sender] = block.timestamp + lockDuration;
        }
        
        lockedTokens[msg.sender] += amount;
        _updateVotingPower(msg.sender);
        
        emit TokensLocked(msg.sender, amount, unlockTime[msg.sender]);
    }
    
    /**
     * @dev Unlocks tokens
     * @param amount Amount to unlock
     */
    function unlockTokens(uint256 amount) external {
        require(lockedTokens[msg.sender] >= amount, "Token: Insufficient locked tokens");
        require(block.timestamp >= unlockTime[msg.sender], "Token: Tokens are still locked");
        
        lockedTokens[msg.sender] -= amount;
        _updateVotingPower(msg.sender);
        
        emit TokensUnlocked(msg.sender, amount);
    }
    
    /**
     * @dev Gets voting power of an address
     * @param user Address to check
     * @return Voting power
     */
    function getVotingPower(address user) external view returns (uint256) {
        return votingPower[user];
    }
    
    /**
     * @dev Gets available balance (excluding locked tokens)
     * @param user Address to check
     * @return Available balance
     */
    function getAvailableBalance(address user) external view returns (uint256) {
        if (balanceOf[user] <= lockedTokens[user]) {
            return 0;
        }
        return balanceOf[user] - lockedTokens[user];
    }
    
    /**
     * @dev Gets lock information
     * @param user Address to check
     * @return lockedAmount, unlockTime
     */
    function getLockInfo(address user) external view returns (uint256 lockedAmount, uint256 unlockTimestamp) {
        return (lockedTokens[user], unlockTime[user]);
    }
    
    /**
     * @dev Checks if tokens are locked
     * @param user Address to check
     * @return True if tokens are locked
     */
    function isLocked(address user) external view returns (bool) {
        return unlockTime[user] > block.timestamp && lockedTokens[user] > 0;
    }
    
    /**
     * @dev Gets remaining lock time
     * @param user Address to check
     * @return Remaining lock time in seconds
     */
    function getRemainingLockTime(address user) external view returns (uint256) {
        if (unlockTime[user] <= block.timestamp) {
            return 0;
        }
        return unlockTime[user] - block.timestamp;
    }
    
    /**
     * @dev Adds minter
     * @param minter Address to add
     */
    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }
    
    /**
     * @dev Removes minter
     * @param minter Address to remove
     */
    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }
    
    /**
     * @dev Adds burner
     * @param burner Address to add
     */
    function addBurner(address burner) external onlyOwner {
        burners[burner] = true;
    }
    
    /**
     * @dev Removes burner
     * @param burner Address to remove
     */
    function removeBurner(address burner) external onlyOwner {
        burners[burner] = false;
    }
    
    /**
     * @dev Transfers ownership
     * @param newOwner New owner address
     */
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
    
    // Internal functions
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "Token: Cannot transfer to zero address");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        
        _updateVotingPower(from);
        _updateVotingPower(to);
        
        emit Transfer(from, to, amount);
    }
    
    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Token: Cannot mint to zero address");
        
        balanceOf[to] += amount;
        totalSupply += amount;
        
        _updateVotingPower(to);
        
        emit Transfer(address(0), to, amount);
    }
    
    function _updateVotingPower(address user) internal {
        uint256 oldPower = votingPower[user];
        uint256 newPower = _calculateVotingPower(user);
        
        if (oldPower != newPower) {
            votingPower[user] = newPower;
            emit VotingPowerUpdated(user, oldPower, newPower);
        }
    }
    
    function _calculateVotingPower(address user) internal view returns (uint256) {
        // Voting power is based on total balance minus locked tokens
        // Plus bonus for locked tokens (longer locks = more voting power)
        uint256 availableBalance = balanceOf[user] - lockedTokens[user];
        uint256 lockedBonus = 0;
        
        if (lockedTokens[user] > 0 && unlockTime[user] > block.timestamp) {
            // Calculate bonus based on lock duration
            uint256 lockDuration = unlockTime[user] - block.timestamp;
            uint256 maxLockDuration = 365 days;
            uint256 bonusPercentage = (lockDuration * 100) / maxLockDuration;
            lockedBonus = (lockedTokens[user] * bonusPercentage) / 100;
        }
        
        return availableBalance + lockedBonus;
    }
}
