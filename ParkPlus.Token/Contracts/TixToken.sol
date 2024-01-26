// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IServiceLocator.sol";
/**
	TixToken acts as a service locator and provides utility to register services.
 **/
contract TixToken is ERC20PresetMinterPauser, Ownable, IServiceLocator {	
	struct ServiceRegistration {
		address destination;
		address owner;
		string spec;
	}
	bytes32 public constant SERVICE_WORKER = keccak256("SERVICE_WORKER");
	bytes32 public constant BALANCER = keccak256("BALANCER");
	mapping(bytes32 => ServiceRegistration) public repository;
	uint public _registrationFee;
	uint public _counter;

	constructor(uint256 initialSupply) ERC20PresetMinterPauser("Toolblox Token", "TIX") {
		address sender = _msgSender();
		_setupRole(SERVICE_WORKER, sender);
		_setupRole(BALANCER, sender);
		_mint(sender, initialSupply);
	}

	function setRegistrationFee(uint fee) public {
		require(hasRole(BALANCER, _msgSender()), "TixToken: must have balancer role to update fees");		
		_registrationFee = fee;
	}
	
	function registerService(string calldata name, string calldata spec, address destination, address newOwner) override public whenNotPaused
	{
		require(newOwner != address(0), "TixToken: Invalid owner requested");
		require(destination != address(0), "TixToken: Invalid owner requested");
		address sender = _msgSender();
		bool senderIsService = hasRole(SERVICE_WORKER, sender);

		//the registrant of the request is either the delegated newOwner (if the sender is service worker), or just the msg.sender
		address registrant = senderIsService ? newOwner : sender;

		bytes32 nameHash = keccak256(abi.encodePacked(name));
		address currentOwner = repository[nameHash].owner;

		if (currentOwner == address(0))
		{
			//first time registration
			if (_registrationFee > 0)
			{
				//if no owner, means first registration, requires fee
				//method: transfer fee back to owner() (buyback) or burn if owner is address(0).
				require(balanceOf(registrant) >= _registrationFee, "TixToken: Not enough TIX to register a service");
				_transfer(registrant, owner(), _registrationFee);
			}
		}
		else{
			//update available only to current owner
			require(currentOwner == registrant, "TixToken: Must own the service or to update");
		}

		//book service address to the newOwner
		_registerService(nameHash, destination, spec, newOwner);
	}

	function registerServices(bytes32[] calldata names, ServiceRegistration[] calldata destinations) public {
		require(hasRole(SERVICE_WORKER, _msgSender()), "TixToken: must have service worker role to register services");
		require(names.length == destinations.length, "Input lengths must match");
		for (uint i = 0; i < names.length; i++) {
			bytes32 name = names[i];
			ServiceRegistration calldata destination = destinations[i];
			_registerService(name, destination.destination, destination.spec, destination.owner);
		}
	}

	function areServicesRegistered(bytes32[] calldata names, address[] calldata destinations) external view returns (bool) {
		for (uint i = 0; i < names.length; i++) {
			if (repository[names[i]].destination != destinations[i]) {
				return false;
			}
		}
		return true;
	}

	function getService(bytes32 name) override external view returns (address) {
		return repository[name].destination;
	}

	function _registerService(bytes32 name, address destination, string memory spec, address owner) private
	{
		repository[name] = ServiceRegistration(destination, owner, spec);
		emit ServiceRegistered(name, destination, spec);
	}

	event ServiceRegistered(bytes32 _name, address _destination, string _spec);
}