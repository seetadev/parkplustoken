// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OwnerPausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IServiceLocator.sol";

contract ServiceDeployer is Ownable, OwnerPausable, ReentrancyGuard {	
	IServiceLocator serviceLocator;	
	uint public counter;

	constructor(IServiceLocator _serviceLocator) {
		serviceLocator = _serviceLocator;
	}

	function deploy(string calldata name, string calldata spec, bytes calldata code) public whenNotPaused nonReentrant returns (address)
	{
		address sender = _msgSender();
		//pre-compute the destination address
		counter = counter + 1;
		address predictedAddress = _computeAddress(code, keccak256(abi.encodePacked(counter, sender)));

		//book service address to the sender
		serviceLocator.registerService(name, spec, predictedAddress, sender);		

		//deploy and check if address is the same as precomputed
		address destination = _deploy(code, keccak256(abi.encodePacked(counter, sender)));
		require(predictedAddress == destination, "Deployed address mismatch");
		emit ServiceDeployed(keccak256(abi.encodePacked(name)), destination);

		//call setOwner() init method on the service to transfer ownership to sender
		(bool success, ) = destination.call(abi.encodeWithSignature("setOwner(address)", sender));
		require(success, "Owner cannot be set");
		return destination;
	}

	function _computeAddress(bytes memory _initCode, bytes32 _salt) private view returns (address) {
		bytes32 codeHash = keccak256(_initCode);
		bytes32 rawAddress = keccak256(abi.encodePacked(bytes1(0xff), address(this), _salt, codeHash));
		return address(uint160(uint(rawAddress)));
	}
	
	function _deploy(bytes memory _initCode, bytes32 _salt) private returns (address createdContract)
    {
        assembly {
            createdContract := create2(0, add(_initCode, 0x20), mload(_initCode), _salt)
			if iszero(extcodesize(createdContract)) {
				revert(0, 0)
			}
        }
    }

	event ServiceDeployed(bytes32 _name, address _destination);
}