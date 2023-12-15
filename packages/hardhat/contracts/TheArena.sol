// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { Errors } from "./libraries/Errors.sol";

contract TheArena is ERC721, VRFConsumerBaseV2 {
	event MintFighter(Fighter indexed fighter);
	event NewLevel(Fighter indexed fighter, uint256 indexed level, uint256 indexed weaponIndex, uint256 statIncreased);
	event RequestNewLevel(Fighter indexed fighter, uint256 indexed level, uint256 indexed requestId);
	event Fight(uint256 indexed fighterId, uint256 indexed opponentId, bool indexed isWinner);

	VRFCoordinatorV2Interface private immutable vrfCoordinator;
	bytes32 private immutable keyHash;
	uint64 private immutable subscriptionId;

	uint256 private _tokenIdCounter;

	uint256[34] public weaponsScoreUnit; // To initialize in contructor? (constant/immutable ?)

	mapping(uint256 => Fighter) public fighters;
	mapping(uint256 => RandomRequest) public randomRequests;

	enum ActionRequest {
		FIGHT,
		LEVEL
	}

	struct RandomRequest {
		bool exists;
		bool finalized;
		uint256[] randomWords;
		uint256 fighterId;
		uint256 opponentId;
		ActionRequest action;
	}

	struct Fighter {
		uint256 tokenId; // Incrémentation basique ou mettre des infos dedans ? Faire un ERC721 et go sur IPFS avec les metadatas
		string name;
		uint256 level;
		uint256 xp; // Nécessaire ? Comment gérer l'xp en fonction des level ? Faire que ce soit plus dur
		string grade; // uint?
		uint256 strength;
		uint256 agility;
		uint256 rapidity;
		bool[34] weapons; // Weapons & Skills, passer le bool en true quand on en gagne une (Checker si je peux pas mettre un bool[] plutôt)
		uint256 weaponsScore; // Ajouter le score du weapon au score déjà existant avec les valeurs unitaires des scores dans _weaponsScoreUnit
		uint8 dailyFights;
		uint256 firstFightTime;
	}

	constructor(
		address _vrfCoordinatorAddr,
		bytes32 _keyHash,
		uint64 _subscriptionId
	) ERC721("Fighter", "FGHT") VRFConsumerBaseV2(_vrfCoordinatorAddr) {
		vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorAddr);
		keyHash = _keyHash;
		subscriptionId = _subscriptionId;
	}

	function mintFighter(string memory _name) public payable returns (uint256) {
		if (msg.value != 0.001 ether) revert Errors.MintValueError();

		uint256 tokenId = _tokenIdCounter;

		bool[34] memory resetWeapons;
		Fighter memory newFighter = Fighter(
			tokenId,
			_name,
			1,
			0,
			"Padawan",
			2,
			2,
			2,
			resetWeapons,
			0,
			0,
			block.timestamp
		);

		// newFighter = _newLevelReward(newFighter);

		_safeMint(msg.sender, tokenId);
		_tokenIdCounter += 1;

		fighters[tokenId] = newFighter;

		emit MintFighter(newFighter);

		return tokenId;
	}

	function newLevel(uint256 _fighterId) public {
		if (ownerOf(_fighterId) != msg.sender) revert Errors.NotTheOwner();

		Fighter memory fighter = fighters[_fighterId];
		uint256 xpRequired = (fighter.level ^ 2) * 20; // Checker si la formule convient. Checker si y'a des issues avec les maths comme ça.

		if (fighter.xp < xpRequired) revert Errors.NotEnoughXP();

		uint256 requestId = vrfCoordinator.requestRandomWords(keyHash, subscriptionId, 3, 500000, 3);

		randomRequests[requestId] = RandomRequest(true, false, new uint256[](0), _fighterId, 0, ActionRequest.LEVEL);

		fighters[_fighterId].level += 1;

		emit RequestNewLevel(fighter, fighter.level, requestId);
	}

	function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
		if (!randomRequests[_requestId].exists) revert Errors.DoNotExist();

		randomRequests[_requestId].finalized = true;
		randomRequests[_requestId].randomWords = _randomWords;

		if (randomRequests[_requestId].action == ActionRequest.LEVEL) {
			_newLevelReward(randomRequests[_requestId]);
		}
	}

	function _newLevelReward(Fighter memory _fighter) internal returns (Fighter memory) {
		uint256 dice1 = _getRandomValue(0, 12);
		uint256 dice2 = _getRandomValue(0, 12);
		uint256 dice3 = _getRandomValue(0, 12);
		uint256 weaponIndex = dice1 + dice2 + dice3;

		if (_fighter.weapons[weaponIndex]) {
			_fighter.strength += 3;
			_fighter.agility += 3;
			_fighter.rapidity += 3;
		} else {
			_fighter.weapons[weaponIndex] = true;
			_fighter.weaponsScore += weaponsScoreUnit[weaponIndex];
		}

		// Soit 'weaponIndex' mais on peut savoir à l'avance la stat qui monte en fonction de l'index du weapon
		// Soit 'dice1' mais faut un multiple de 3 (ou 4) sinon la probabilité entre chaque stat à monter n'est pas égale et ça se verra à grande échelle
		uint256 increaseStat = dice1 % 4;

		if (increaseStat == 0) {
			_fighter.strength += 3;
		} else if (increaseStat == 1) {
			_fighter.agility += 3;
		} else if (increaseStat == 2) {
			_fighter.rapidity += 3;
		}

		return _fighter; // Return le nouveau fighter, et les nouveaux attributs ?
	}
}
