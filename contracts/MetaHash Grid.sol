// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MetaHashGrid
 * @dev A distributed storage system with grid-based metadata and hash verification
 */
contract MetaHashGrid {
    struct GridNode {
        bytes32 contentHash;
        string metadata;
        address owner;
        uint256 timestamp;
        uint256 accessCount;
        bool isEncrypted;
    }
    
    struct GridCoordinate {
        int256 x;
        int256 y;
        int256 z;
    }
    
    mapping(bytes32 => GridNode) public grid;
    mapping(address => bytes32[]) public userNodes;
    mapping(bytes32 => GridCoordinate) public nodeCoordinates;
    
    uint256 public totalNodes;
    uint256 public constant STORAGE_FEE = 0.001 ether;
    
    event NodeCreated(bytes32 indexed nodeId, address indexed owner, int256 x, int256 y, int256 z);
    event NodeAccessed(bytes32 indexed nodeId, address accessor);
    event NodeUpdated(bytes32 indexed nodeId, string newMetadata);
    
    function createNode(int256 x, int256 y, int256 z, string memory content, string memory metadata) external payable {
        require(msg.value >= STORAGE_FEE, "Insufficient storage fee");
        
        bytes32 nodeId = keccak256(abi.encodePacked(x, y, z, msg.sender, block.timestamp));
        require(grid[nodeId].owner == address(0), "Node already exists");
        
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        bool isEncrypted = bytes(metadata).length > 0 && keccak256(abi.encodePacked(metadata)) != keccak256(abi.encodePacked(""));
        
        grid[nodeId] = GridNode({
            contentHash: contentHash,
            metadata: metadata,
            owner: msg.sender,
            timestamp: block.timestamp,
            accessCount: 0,
            isEncrypted: isEncrypted
        });
        
        nodeCoordinates[nodeId] = GridCoordinate(x, y, z);
        userNodes[msg.sender].push(nodeId);
        totalNodes++;
        
        emit NodeCreated(nodeId, msg.sender, x, y, z);
    }
    
    function accessNode(bytes32 nodeId) external {
        require(grid[nodeId].owner != address(0), "Node does not exist");
        
        grid[nodeId].accessCount++;
        emit NodeAccessed(nodeId, msg.sender);
    }
    
    function updateMetadata(bytes32 nodeId, string memory newMetadata) external {
        require(grid[nodeId].owner == msg.sender, "Not the owner");
        
        grid[nodeId].metadata = newMetadata;
        emit NodeUpdated(nodeId, newMetadata);
    }
    
    function verifyContent(bytes32 nodeId, string memory content) external view returns (bool) {
        bytes32 contentHash = keccak256(abi.encodePacked(content));
        return grid[nodeId].contentHash == contentHash;
    }
    
    function getNodesByUser(address user) external view returns (bytes32[] memory) {
        return userNodes[user];
    }
    
    function getMyNodes() external view returns (bytes32[] memory) {
        return userNodes[msg.sender];
    }
    
    function getNodeInfo(bytes32 nodeId) external view returns (
        bytes32 contentHash,
        string memory metadata,
        address owner,
        uint256 timestamp,
        uint256 accessCount,
        bool isEncrypted
    ) {
        GridNode memory node = grid[nodeId];
        return (
            node.contentHash,
            node.metadata,
            node.owner,
            node.timestamp,
            node.accessCount,
            node.isEncrypted
        );
    }
    
    function getCoordinates(bytes32 nodeId) external view returns (int256 x, int256 y, int256 z) {
        GridCoordinate memory coord = nodeCoordinates[nodeId];
        return (coord.x, coord.y, coord.z);
    }
    
    function generateNodeId(int256 x, int256 y, int256 z) external view returns (bytes32) {
        return keccak256(abi.encodePacked(x, y, z, msg.sender, block.timestamp));
    }
}