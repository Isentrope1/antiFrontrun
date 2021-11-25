//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract NameRegistry {

    struct RegistrationInfo {
        address owner;
        uint expiration;
        uint preregisterTimestamp;
        uint registerTimestamp;

    }
    
    event RegistrationUpdated(string indexed name, address indexed owner);

    uint public registrationDelay;
    uint public registrationPeriod;
    uint public pricePerChar;

    mapping(bytes32 => uint) public preRegistrations;
    mapping(string => RegistrationInfo) public registrations;

    constructor(uint _registrationDelay, uint _registrationPeriod, uint _pricePerChar) {
        registrationDelay = _registrationDelay;
        registrationPeriod = _registrationPeriod;
        pricePerChar = _pricePerChar;
    }
    
    function costOfName(string memory name) public view returns (uint) {
        return bytes(name).length * pricePerChar;
    }

    // returns (0,0) if not registed, in delay period, or expired
    function ownerAndExpirationTime(string memory name) public view returns (address, uint) {
        RegistrationInfo storage info = registrations[name];
        if(info.owner == address(0)) return (address(0), 0);
        if(block.timestamp < info.registerTimestamp + registrationDelay) return (address(0), 0);
        if(block.timestamp > info.expiration) return (address(0), 0);
        return (info.owner, info.expiration);
    }

    function preRegister(bytes32 hashOfNameAndSalt) public {
        bytes32 key = keccak256(abi.encodePacked(msg.sender, hashOfNameAndSalt));
        require(preRegistrations[key] == 0, "alreadyPreregistered");
        preRegistrations[key] = block.timestamp;
    }

    function register(string memory name, bytes32 salt) public payable {
        (address owner, ) = ownerAndExpirationTime(name);

        RegistrationInfo storage info = registrations[name];
        //extend reservation if already owned
        if(owner == msg.sender) {
           info.expiration = block.timestamp + registrationPeriod;
           if(msg.value > 0) require(payable(msg.sender).send(msg.value));
           return;
        }

        //check that msg.sender is earliest preregister
        bytes32 hashOfNameAndSalt = keccak256(abi.encodePacked(name, salt));
        uint preregTimestamp = preRegistrations[keccak256(abi.encodePacked(msg.sender, hashOfNameAndSalt))];
        require(preregTimestamp != 0, "notPreregistered");
        uint earliestPrereg = info.preregisterTimestamp;
        require(earliestPrereg == 0 || preregTimestamp <= earliestPrereg || block.timestamp > info.expiration, "notEarliestPrereg");

        //check cost
        uint cost = costOfName(name); 
        // could omit require, but wanted error message
        require(msg.value >= cost, "insufficientPayment");
        uint extraPayment = msg.value - cost;
        if(extraPayment > 0) require(payable(msg.sender).send(extraPayment));

        //refund cost to previous owner
        if(owner != address(0) && cost > 0) require(payable(owner).send(cost));

        registrations[name] = RegistrationInfo({owner: msg.sender, expiration: block.timestamp + registrationPeriod, preregisterTimestamp: preregTimestamp, registerTimestamp: block.timestamp});
        emit RegistrationUpdated(name, msg.sender);
    }
}
