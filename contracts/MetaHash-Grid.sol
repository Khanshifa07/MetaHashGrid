// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MetaHashGrid
 * @dev A decentralized registry for timestamped content hashes with simple metadata
 * @notice Users can register, update, and query hashed items on-chain
 */
contract MetaHashGrid {
    
    // State variables
    address public owner;
    uint256 public totalRecords;
    uint256 public totalOwners;
    
    struct HashRecord {
        address owner;
        bytes32 dataHash;
        uint256 createdAt;
        uint256 updatedAt;
        string tag;
        bool isActive;
    }
    
    // id => record
    mapping(uint256 => HashRecord) public records;
    
    // owner => list of ids
    mapping(address => uint256[]) public ownerToIds;
    
    // owner => whether already counted
    mapping(address => bool) public isKnownOwner;
    
    // Events
    event HashRegistered(
        uint256 indexed id,
        address indexed owner,
        bytes32 dataHash,
        string tag,
        uint256 timestamp
    );
    
    event HashUpdated(
        uint256 indexed id,
        bytes32 oldHash,
        bytes32 newHash,
        uint256 timestamp
    );
    
    event HashDeactivated(
        uint256 indexed id,
        address indexed owner,
        uint256 timestamp
    );
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    modifier onlyRecordOwner(uint256 id) {
        require(records[id].owner == msg.sender, "Not record owner");
        _;
    }
    
    modifier recordExists(uint256 id) {
        require(records[id].owner != address(0), "Record does not exist");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Function 1: Register a new hash
     * @param dataHash The keccak256 or other precomputed hash of the content
     * @param tag A short label or category for the record
     * @notice Stores a new immutable ID pointing to user-owned hashed content
     */
    function registerHash(bytes32 dataHash, string calldata tag) external returns (uint256 id) {
        require(dataHash != bytes32(0), "Invalid hash");
        
        id = totalRecords;
        totalRecords += 1;
        
        if (!isKnownOwner[msg.sender]) {
            isKnownOwner[msg.sender] = true;
            totalOwners += 1;
        }
        
        records[id] = HashRecord({
            owner: msg.sender,
            dataHash: dataHash,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            tag: tag,
            isActive: true
        });
        
        ownerToIds[msg.sender].push(id);
        
        emit HashRegistered(id, msg.sender, dataHash, tag, block.timestamp);
    }
    
    /**
     * @dev Function 2: Update hash for an existing record
     * @param id The record id
     * @param newHash New hash to be associated with this record
     * @notice Only record owner can update; preserves original createdAt
     */
    function updateHash(uint256 id, bytes32 newHash)
        external
        recordExists(id)
        onlyRecordOwner(id)
    {
        require(newHash != bytes32(0), "Invalid hash");
        require(records[id].isActive, "Record not active");
        
        bytes32 old = records[id].dataHash;
        records[id].dataHash = newHash;
        records[id].updatedAt = block.timestamp;
        
        emit HashUpdated(id, old, newHash, block.timestamp);
    }
    
    /**
     * @dev Function 3: Deactivate a record
     * @param id The record id
     * @notice Marks the record as inactive but keeps full history on-chain
     */
    function deactivateHash(uint256 id)
        external
        recordExists(id)
        onlyRecordOwner(id)
    {
        require(records[id].isActive, "Already inactive");
        records[id].isActive = false;
        
        emit HashDeactivated(id, msg.sender, block.timestamp);
    }
    
    /**
     * @dev Function 4: Get record details
     * @param id The record id
     * @return owner_ Record owner
     * @return dataHash Record hash
     * @return createdAt Record creation time
     * @return updatedAt Record last update time
     * @return tag Record tag
     * @return isActive Whether record is active
     */
    function getRecord(uint256 id)
        external
        view
        recordExists(id)
        returns (
            address owner_,
            bytes32 dataHash,
            uint256 createdAt,
            uint256 updatedAt,
            string memory tag,
            bool isActive
        )
    {
        HashRecord memory rec = records[id];
        return (
            rec.owner,
            rec.dataHash,
            rec.createdAt,
            rec.updatedAt,
            rec.tag,
            rec.isActive
        );
    }
    
    /**
     * @dev Function 5: Get all record IDs owned by a user
     * @param user The address of the user
     * @return Array of record IDs
     */
    function getOwnedIds(address user) external view returns (uint256[] memory) {
        return ownerToIds[user];
    }
    
    /**
     * @dev Function 6: Transfer contract ownership
     * @param newOwner New owner address
     * @notice Only current owner can transfer ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address previous = owner;
        owner = newOwner;
        emit OwnershipTransferred(previous, newOwner);
    }
    
    /**
     * @dev Get basic stats for the grid
     */
    function getStats() external view returns (uint256 _totalRecords, uint256 _totalOwners) {
        return (totalRecords, totalOwners);
    }
}
