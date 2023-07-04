// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title EchoHolders contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
contract EchoHolders is ERC721Enumerable, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // Base URI
    string private _baseURIextended;
    uint256 public MAX_SUPPLY;
    uint256 public NFT_PRICE;
    uint256 public MAX_PER_MINT = 10;
    uint256 public MAX_RESERVE = 150;
    uint256 public reservedAmount;
    bytes32 public root;

    enum Status {
        PublicSale,
        PrivateSale1,
        PrivateSale2,
        Stop
    }

    Status public presale;

    mapping(address => uint256) public privateSale1;
    mapping(address => uint256) public privateSale2;
    mapping(address => uint256) public publicSale;

    constructor(
        uint256 _maxSupply,
        uint256 _nftPrice
    ) ERC721("EchoHolders", "EchoNFT") {
        MAX_SUPPLY = _maxSupply;
        NFT_PRICE = _nftPrice;

        presale = Status.Stop;
    }

    function withdraw(uint _amount) public payable onlyOwner {
        address payable recipient = payable(msg.sender);
        recipient.transfer(_amount);
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function setNftPrice(uint256 _nftPrice) external onlyOwner {
        NFT_PRICE = _nftPrice;
    }

    /**
     * Mint NFTs by owner
     */
    function reserveNFTs(address _to, uint256 _amount) external onlyOwner {
        require(_to != address(0), "Invalid address to reserve.");
        require(reservedAmount.add(_amount) <= MAX_RESERVE, "Invalid amount");

        for (uint256 i = 0; i < _amount; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(_to, totalSupply());
            }
        }
        reservedAmount = reservedAmount.add(_amount);
    }

    /**
     * @dev Return the base URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    /**
     * @dev Return the base URI
     */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Set the base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        _baseURIextended = baseURI_;
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function verifyLeaf(bytes32[] memory proof, address sender) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(keccak256(abi.encodePacked(sender))));
        return MerkleProof.verify(proof, root, leaf);
    }

    function buy(uint256 amount, bytes32[] memory proof) public payable {
        require(presale != Status.Stop, 'Presale isnt available at this moment');
        if(presale == Status.PrivateSale1){
            // Private sale is 5 NFT per wallet and 0.25ETH per NFT
            require(verifyLeaf(proof, msg.sender), "Not whitelisted.");
            require(NFT_PRICE.mul(amount) == msg.value, "ETH value sent is not correct");
            require(privateSale1[msg.sender].add(amount) <= MAX_PER_MINT, "exceed maximum amount");

            privateSale1[msg.sender] = privateSale1[msg.sender].add(amount);
            _mintTo(msg.sender, amount);
        }if(presale == Status.PrivateSale2){
            // Private sale is 10 NFT per wallet and 0.28ETH per NFT
            require(verifyLeaf(proof, msg.sender), "Not whitelisted.");
            require(NFT_PRICE.mul(amount) == msg.value, "ETH value sent is not correct");
            require(privateSale2[msg.sender].add(amount) <= MAX_PER_MINT, "exceed maximum amount");

            privateSale2[msg.sender] = privateSale2[msg.sender].add(amount);
            _mintTo(msg.sender, amount);
        }else if(presale == Status.PublicSale){
            // Public sale is 10 NFT per wallet and 0.3ETH per NFT
            require(NFT_PRICE.mul(amount) == msg.value, "ETH value sent is not correct");
            require(publicSale[msg.sender].add(amount) <= MAX_PER_MINT, "exceed maximum amount");

            publicSale[msg.sender] = publicSale[msg.sender].add(amount);
            _mintTo(msg.sender, amount);
        }

    }

    function updateStatus(uint256 _NFT_PRICE, uint _MAX_PER_MINT, Status _newStatus) public payable onlyOwner {
        NFT_PRICE = _NFT_PRICE;
        MAX_PER_MINT = _MAX_PER_MINT;
        presale = _newStatus;
    }

    function _mintTo(address account, uint amount) internal {
        require(totalSupply().add(amount) <= MAX_SUPPLY, "Mint would exceed max supply.");

        for (uint256 i = 0; i < amount; i++) {
            if (totalSupply() < MAX_SUPPLY) {
                _safeMint(account, totalSupply());
            }
        }
    }
}
