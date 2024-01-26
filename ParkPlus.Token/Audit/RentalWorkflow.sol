// SPDX-License-Identifier: UNLICENSED

// This smart contract code is proprietary.
// Unauthorized copying, modification, or distribution is strictly prohibited.
// For licensing inquiries or permissions, contact info@toolblox.net.

pragma solidity ^0.8.0;
import "../Contracts/WorkflowBase.sol";
import "../Contracts/OwnerPausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/*
	### Rental Smart Contract:
	
	The described workflow represents a car rental process on a blockchain. It uses smart contracts to automate and secure the rental transactions, ensuring transparency, trust, and efficiency between the renter and the owner.
	
	### Use Cases:
	
	1.  **Registering a Car for Rent**:
	
	    *   The owner can register a car for rent by providing its name, collateral amount, and price per day.
	    *   Only the owner has the authority to register a car.
	2.  **Starting the Rental Process**:
	
	    *   A renter can start the rental process by specifying the number of days they want to rent and the allowance they're willing to pay.
	    *   The renter pays a collateral to the workflow, which acts as a security deposit.
	    *   The start time of the rental is automatically recorded.
	3.  **Charging During the Rental Period**:
	
	    *   The owner can charge the renter for the days the car has been in use.
	    *   The number of days to charge is calculated based on the current time and the start time of the rental.
	    *   The leftover charge is calculated based on the days charged and the price per day.
	4.  **Ending the Rental Process**:
	
	    *   The owner or the renter can end the rental, calculating any additional fees based on the number of days the car was rented and any overtime charges.
	    *   The end time of the rental is automatically recorded.
	5.  **Settling Payments**:
	
	    *   After the rental period, the owner can finalize the charges.
	    *   The renter's collateral can be used to cover any leftover charges.
	    *   If there are no additional charges, the collateral is returned to the renter.
	6.  **Making the Car Available Again**:
	
	    *   Once the rental process is completed, the owner can make the car available for rent again.
	    *   All rental details are reset to their initial state.
	7.  **Updating Car Details**:
	
	    *   The owner can update the car's details, such as its name, collateral amount, and price per day, at any point when the car is available or in use.
	
	### Rentals on blockchain
	
	1.  **Transparency**: All transactions and states of the rental process are recorded on the blockchain, ensuring that both parties can view and verify the details.
	
	2.  **Trust**: The use of collateral ensures that renters are incentivized to return the car in good condition. If any issues arise, the collateral can be used to cover damages or additional charges.
	
	3.  **Automation**: The smart contract automates various steps of the rental process, such as calculating charges, recording start and end times, and settling payments, reducing manual intervention and potential errors.
	
	4.  **Security**: Smart contracts are tamper-proof. Once deployed, the rules cannot be changed, ensuring that both parties adhere to the agreed-upon terms.
	
	5.  **Efficiency**: Payments and settlements are done instantly through the blockchain, eliminating the need for intermediaries and reducing transaction times.
	
	In conclusion, using a smart contract for car rentals streamlines the process, reduces disputes, and ensures a fair and transparent transaction for both renters and owners.
	
	**Testing**
	
	Use testnet tokens to test. Tokens can be acquired here: https://faucet.polygon.technology/ (Test ERC20).
*/
contract RentalWorkflow  is WorkflowBase, Ownable, ReentrancyGuard, OwnerPausable{
	struct Rental {
		uint id;
		string name;
		address renter;
		uint startTime;
		uint pricePerDay;
		uint daysCharged;
		uint collateral;
		uint leftoverCharge;
		uint64 numberOfDays;
		uint64 status;
	}
	mapping(uint => Rental) public items;
	address public token = 0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1;
	function _assertOrAssignRenter(Rental memory item) private view {
		address renter = item.renter;
		if (renter != address(0))
		{
			require(_msgSender() == renter, "Invalid Renter");
			return;
		}
		item.renter = _msgSender();
	}
	constructor()  {
		_transferOwnership(_msgSender());
	}
	function setOwner(address _newOwner) public {
		transferOwnership(_newOwner);
	}
/*
	Available statuses:
	3 Available
	1 In use (owner Renter)
	2 Returned
	4 Settled
	5 Completed
*/
	function _assertStatus(Rental memory item, uint64 status) private pure {
		require(item.status == status, "Cannot run Workflow action; unexpected status");
	}
	function getItem(uint256 id) public view returns (Rental memory) {
		Rental memory item = items[id];
		require(item.id == id, "Cannot find item with given id");
		return item;
	}
	function getLatest(uint256 cnt) public view returns(Rental[] memory) {
		uint256[] memory latestIds = getLatestIds(cnt);
		Rental[] memory latestItems = new Rental[](latestIds.length);
		for (uint256 i = 0; i < latestIds.length; i++) latestItems[i] = items[latestIds[i]];
		return latestItems;
	}
	function getPage(uint256 cursor, uint256 howMany) public view returns(Rental[] memory) {
		uint256[] memory ids = getPageIds(cursor, howMany);
		Rental[] memory result = new Rental[](ids.length);
		for (uint256 i = 0; i < ids.length; i++) result[i] = items[ids[i]];
		return result;
	}
/*
	### Transition: 'Start rent'
	This transition begins from `Available` and leads to the state `In use`.
	
	First, an allowance in the amount of `Allowance` is approved to the workflow.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Rental identifier
	* `Number of days` (Integer)
	* `Allowance` (Money)
	
	#### Access Restrictions
	Access is specifically restricted to the user with the address from the `Renter` property. If `Renter` property is not yet set then the method caller becomes the objects `Renter`.
	
	#### Checks and updates
	The following checks are done before any changes take place:
	
	* The condition ``Allowance == ( Number of days * Price per day )`` needs to be true or the following error will be returned: *"Allowance is correct?"*.
	
	The following properties will be updated on blockchain:
	
	* `Number of days` (Integer)
	
	The following calculations will be done and updated:
	
	* `Start time` = `now`
	
	#### Payment Process
	In the end a payment is made.
	A payment in the amount of `Collateral` is made from caller to the workflow.
*/
	function startRent(uint256 id,uint64 numberOfDays,uint allowance) external whenNotPaused nonReentrant returns (uint256) {
		Rental memory item = getItem(id);
		_assertOrAssignRenter(item);
		_assertStatus(item, 3);
		require(allowance == ( numberOfDays * item.pricePerDay ), "Allowance is correct?");
		item.numberOfDays = numberOfDays;
		item.startTime = block.timestamp;
		item.status = 1;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		if (address(this) != address(0) && item.collateral > 0){
			safeTransferFromExternal(token, _msgSender(), address(this), item.collateral);
		}
		return id;
	}
/*
	### Transition: 'Charge'
	This transition begins from `In use` and leads to the state `In use`.
	
	#### Access Restrictions
	Access is exclusively limited to the owner of the workflow.
	
	#### Checks and updates
	The following calculations will be done and updated:
	
	*  `Days to charge` = `( ( now - Start time ) / ( ( 24 * 60 ) * 60 ) ) - Days charged`
	* `Days charged` = `Days charged + Days to charge`
	* `Leftover charge` = `Days to charge * Price per day`
	
	#### Payment Process
	In the end a payment is made.
	A payment in the amount of `Leftover charge` is made from the address specified in the `Renter` property to the workflow owner.
*/
	function charge(uint256 id) external onlyOwner whenNotPaused nonReentrant returns (uint256) {
		Rental memory item = getItem(id);
		_assertStatus(item, 1);
		uint daysToCharge = ( ( block.timestamp - item.startTime ) / ( ( 24 * 60 ) * 60 ) ) - item.daysCharged;
		item.daysCharged = item.daysCharged + daysToCharge;
		item.leftoverCharge = daysToCharge * item.pricePerDay;
		item.status = 1;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		if (owner() != address(0) && item.renter != address(0) && item.leftoverCharge > 0){
			safeTransferFromExternal(token, item.renter, owner(), item.leftoverCharge);
		}
		return id;
	}
/*
	### Transition: 'End rental'
	#### Notes
	
	This transition can be run by either the owner or the renter of the item.
	This transition begins from `In use` and leads to the state `Returned`.
	
	#### Access Restrictions
	Access only granted if caller is in any of these roles: Renter, Workflow owner.
	
	#### Checks and updates
	The following calculations will be done and updated:
	
	*  `Nominal fee` = `( Number of days - Days charged ) * Price per day`
	*  `End time` = `Start time + ( ( ( Number of days * 24 ) * 60 ) * 60 )`
	* `Leftover charge` = `Nominal fee + ( ( now > End time ) ? ( ( End time - now ) * ( ( ( Price per day / 24 ) / 60 ) / 60 ) ) : 0 )`
*/
	function endRental(uint256 id) external whenNotPaused nonReentrant returns (uint256) {
		Rental memory item = getItem(id);
		require(item.renter == _msgSender() || owner() == _msgSender(), "Access restricted to: renter, workflow owner");
		_assertStatus(item, 1);
		uint nominalFee = ( item.numberOfDays - item.daysCharged ) * item.pricePerDay;
		uint endTime = item.startTime + ( ( ( item.numberOfDays * 24 ) * 60 ) * 60 );
		item.leftoverCharge = nominalFee + ( ( block.timestamp > endTime ) ? ( ( endTime - block.timestamp ) * ( ( ( item.pricePerDay / 24 ) / 60 ) / 60 ) ) : 0 );
		item.status = 2;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Register item'
	This transition creates a new object and puts it into `Available` state.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Name` (Text)
	* `Collateral` (Money)
	* `Price per day` (Money)
	
	#### Access Restrictions
	Access is exclusively limited to the owner of the workflow.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Collateral` (Money)
	* `Price per day` (Money)
*/
	function registerItem(string calldata name,uint collateral,uint pricePerDay) external onlyOwner whenNotPaused nonReentrant returns (uint256) {
		uint256 id = _getNextId();
		Rental memory item;
		item.id = id;
		items[id] = item;
		item.name = name;
		item.collateral = collateral;
		item.pricePerDay = pricePerDay;
		item.status = 3;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Final charge'
	This transition begins from `Returned` and leads to the state `Settled`. But only if the condition `Charge amount == Leftover charge` is true; otherwise it leads to state `Returned`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Rental identifier
	* `Charge amount` (Money)
	
	#### Access Restrictions
	Access is exclusively limited to the owner of the workflow.
	
	#### Checks and updates
	The following checks are done before any changes take place:
	
	* The condition ``Charge amount <= Leftover charge`` needs to be true or the following error will be returned: *"Cannot charge more than leftover"*.
	
	#### Payment Process
	In the end a payment is made.
	A payment in the amount of `Charge amount` is made from the address specified in the `Renter` property to the workflow owner.
*/
	function finalCharge(uint256 id,uint chargeAmount) external onlyOwner whenNotPaused nonReentrant returns (uint256) {
		Rental memory item = getItem(id);
		_assertStatus(item, 2);
		require(chargeAmount <= item.leftoverCharge, "Cannot charge more than leftover");

		item.status = ( chargeAmount == item.leftoverCharge ) ? 4 : 2;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		if (owner() != address(0) && item.renter != address(0) && chargeAmount > 0){
			safeTransferFromExternal(token, item.renter, owner(), chargeAmount);
		}
		return id;
	}
/*
	### Transition: 'Charge with collateral'
	This transition begins from `Returned` and leads to the state `Settled`.
	
	#### Access Restrictions
	Access is exclusively limited to the owner of the workflow.
	
	#### Checks and updates
	The following checks are done before any changes take place:
	
	* The condition ``Collateral >= Leftover charge`` needs to be true or the following error will be returned: *"Has collateral"*.
	
	The following calculations will be done and updated:
	
	* `Collateral` = `Collateral - Leftover charge`
	
	#### Payment Process
	In the end a payment is made.
	A payment in the amount of `Collateral` is made from workflow to the workflow owner.
*/
	function chargeWithCollateral(uint256 id) external onlyOwner whenNotPaused nonReentrant returns (uint256) {
		Rental memory item = getItem(id);
		_assertStatus(item, 2);
		require(item.collateral >= item.leftoverCharge, "Has collateral");
		item.collateral = item.collateral - item.leftoverCharge;
		item.status = 4;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Release collateral'
	This transition begins from `Settled` and leads to the state `Completed`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Rental identifier
	* `Charge amount` (Money)
	* `Evidence` (Text)
	
	#### Checks and updates
	The following checks are done before any changes take place:
	
	* The condition ``Collateral >= Charge amount`` needs to be true or the following error will be returned: *"Has collateral?"*.
	
	The following calculations will be done and updated:
	
	* `Collateral` = `Collateral - Charge amount`
	
	#### Payment Process
	At the end of the transition 2 payments are made.
	
	A payment in the amount of `Charge amount` is made from workflow to the workflow owner.
	
	A payment in the amount of `Collateral` is made from workflow to the address specified in the `Renter` property.
*/
	function releaseCollateral(uint256 id,uint chargeAmount,string calldata /*evidence*/) external whenNotPaused nonReentrant returns (uint256) {
		Rental memory item = getItem(id);
		_assertStatus(item, 4);
		require(item.collateral >= chargeAmount, "Has collateral?");
		item.collateral = item.collateral - chargeAmount;
		item.status = 5;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		if (item.renter != address(0) && item.collateral > 0){
			safeTransferExternal(token, item.renter, item.collateral);
		}
		return id;
	}
/*
	### Transition: 'Make available'
	This transition begins from `Completed` and leads to the state `Available`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Rental identifier
	* `Name` (Text)
	* `Collateral` (Money)
	* `Price per day` (Money)
	
	#### Access Restrictions
	Access is exclusively limited to the owner of the workflow.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Collateral` (Money)
	* `Price per day` (Money)
	
	The following calculations will be done and updated:
	
	* `Renter` = `empty`
	* `Start time` = `0`
	* `Leftover charge` = `0`
	* `Days charged` = `0`
	* `Number of days` = `0`
*/
	function makeAvailable(uint256 id,string calldata name,uint collateral,uint pricePerDay) external onlyOwner whenNotPaused nonReentrant returns (uint256) {
		Rental memory item = getItem(id);
		_assertStatus(item, 5);
		item.name = name;
		item.collateral = collateral;
		item.pricePerDay = pricePerDay;
		item.renter = address(0);
		item.startTime = 0;
		item.leftoverCharge = 0;
		item.daysCharged = 0;
		item.numberOfDays = 0;
		item.status = 3;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'Update'
	This transition begins from `Available` and leads to the state `Available`.
	
	#### Transition Parameters
	For this transition, the following parameters are required: 
	
	* `Id` (Integer) - Rental identifier
	* `Name` (Text)
	* `Collateral` (Money)
	* `Price per day` (Money)
	
	#### Access Restrictions
	Access is exclusively limited to the owner of the workflow.
	
	#### Checks and updates
	The following properties will be updated on blockchain:
	
	* `Name` (String)
	* `Collateral` (Money)
	* `Price per day` (Money)
*/
	function update(uint256 id,string calldata name,uint collateral,uint pricePerDay) external onlyOwner whenNotPaused nonReentrant returns (uint256) {
		Rental memory item = getItem(id);
		_assertStatus(item, 3);
		item.name = name;
		item.collateral = collateral;
		item.pricePerDay = pricePerDay;
		item.status = 3;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		return id;
	}
/*
	### Transition: 'End and settle'
	#### Notes
	
	This method tries to end the rental and settle all charges in one call. It assumes there is no outstanding claims and collateral can be fully returned.
	This transition begins from `In use` and leads to the state `Completed`.
	
	#### Access Restrictions
	Access is exclusively limited to the owner of the workflow.
	
	#### Checks and updates
	The following calculations will be done and updated:
	
	*  `Nominal fee` = `( Number of days - Days charged ) * Price per day`
	*  `End time` = `Start time + ( ( ( Number of days * 24 ) * 60 ) * 60 )`
	* `Leftover charge` = `Nominal fee + ( ( now > End time ) ? ( ( End time - now ) * ( ( ( Price per day / 24 ) / 60 ) / 60 ) ) : 0 )`
	
	#### Payment Process
	At the end of the transition 2 payments are made.
	
	A payment in the amount of `Collateral` is made from workflow to the address specified in the `Renter` property.
	
	A payment in the amount of `Leftover charge` is made from the address specified in the `Renter` property to the workflow owner.
*/
	function endAndSettle(uint256 id) external onlyOwner whenNotPaused nonReentrant returns (uint256) {
		Rental memory item = getItem(id);
		_assertStatus(item, 1);
		uint nominalFee = ( item.numberOfDays - item.daysCharged ) * item.pricePerDay;
		uint endTime = item.startTime + ( ( ( item.numberOfDays * 24 ) * 60 ) * 60 );
		item.leftoverCharge = nominalFee + ( ( block.timestamp > endTime ) ? ( ( endTime - block.timestamp ) * ( ( ( item.pricePerDay / 24 ) / 60 ) / 60 ) ) : 0 );
		item.status = 5;
		items[id] = item;
		emit ItemUpdated(id, item.status);
		if (item.renter != address(0) && item.collateral > 0){
			safeTransferExternal(token, item.renter, item.collateral);
		}
		if (owner() != address(0) && item.renter != address(0) && item.leftoverCharge > 0){
			safeTransferFromExternal(token, item.renter, owner(), item.leftoverCharge);
		}
		return id;
	}
}