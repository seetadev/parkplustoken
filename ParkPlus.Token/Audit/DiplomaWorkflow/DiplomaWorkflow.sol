// SPDX-License-Identifier: UNLICENSED

// This smart contract code is proprietary.
// Unauthorized copying, modification, or distribution is strictly prohibited.
// For licensing inquiries or permissions, contact info@toolblox.net.

pragma solidity ^0.8.19;
import "../../Contracts/WorkflowBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../../Contracts/NonTransferrableERC721.sol";
contract DiplomaWorkflow  is WorkflowBase, Ownable, ERC721, ERC721Enumerable, NonTransferrableERC721{
	struct Diploma {
		uint id;
		uint64 status;
		string name;
		string description;
		string image;
		address holder;
	}
	mapping(uint => Diploma) public items;
	function _assertOrAssignHolder(Diploma memory item) private view {
		address holder = item.holder;
		if (holder != address(0))
		{
			require(_msgSender() == holder, "Invalid Holder");
			return;
		}
		item.holder = _msgSender();
	}
	constructor() NonTransferrableERC721("Diploma - Diplomas as NFTs", "CERT") {
		_transferOwnership(_msgSender());
	}
	function setOwner(address _newOwner) public {
		transferOwnership(_newOwner);
	}
/*
	Available statuses:
	0 Issued (owner Holder)
*/
	function _assertStatus(Diploma memory item, uint64 status) private pure {
		require(item.status == status, "Cannot run Workflow action; unexpected status");
	}
	function getItem(uint256 id) public view returns (Diploma memory) {
		Diploma memory item = items[id];
		require(item.id == id, "Cannot find item with given id");
		return item;
	}
	function getLatest(uint256 cnt) public view returns(Diploma[] memory) {
		uint256[] memory latestIds = getLatestIds(cnt);
		Diploma[] memory latestItems = new Diploma[](latestIds.length);
		for (uint256 i = 0; i < latestIds.length; i++) latestItems[i] = items[latestIds[i]];
		return latestItems;
	}
	function getPage(uint256 cursor, uint256 howMany) public view returns(Diploma[] memory) {
		uint256[] memory ids = getPageIds(cursor, howMany);
		Diploma[] memory result = new Diploma[](ids.length);
		for (uint256 i = 0; i < ids.length; i++) result[i] = items[ids[i]];
		return result;
	}
	function getItemOwner(Diploma memory item) private view returns (address itemOwner) {
				if (item.status == 0) {
			itemOwner = item.holder;
		}
        else {
			itemOwner = address(this);
        }
        if (itemOwner == address(0))
        {
            itemOwner = address(this);
        }
	}
	function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override {
		super._afterTokenTransfer(from, to, firstTokenId, batchSize);
		if (from == to)
		{
			return;
		}
		Diploma memory item = getItem(firstTokenId);
		if (item.status == 0) {
			item.holder = to;
		}
	}
	function supportsInterface(bytes4 interfaceId) public view override(ERC721,ERC721Enumerable) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
	function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual override (ERC721,ERC721Enumerable,NonTransferrableERC721) {
		super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
	}
	function _baseURI() internal view virtual override returns (string memory) {
		return "https://nft.toolblox.net/api/metadata?workflowId=diplomas_as_nfts&id=";
	}
	function issue(string calldata name,string calldata description,string calldata image,address holder) external onlyOwner returns (uint256) {
		uint256 id = _getNextId();
		Diploma memory item;
		item.id = id;
		items[id] = item;
		item.name = name;
		item.description = description;
		item.image = image;
		item.holder = holder;
		item.status = 0;
		items[id] = item;
		address newOwner = getItemOwner(item);
		_mint(newOwner, id);
		emit ItemUpdated(id, item.status);
		return id;
	}
}