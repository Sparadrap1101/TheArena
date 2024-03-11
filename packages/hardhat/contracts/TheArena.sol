// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { Errors } from "./libraries/Errors.sol";

contract TheArena is ERC721, VRFConsumerBaseV2 {
	event MintFighter(Fighter indexed fighter, uint256 indexed requestId);
	event NewLevel(Fighter indexed fighter, uint256 indexed level, uint256 indexed weaponIndex, uint256 statIncreased);
	event RequestNewLevel(Fighter indexed fighter, uint256 indexed level, uint256 indexed requestId);
	event Fight(uint256 indexed fighterId, uint256 indexed opponentId, bool indexed isWinner, uint256 newXp);
	event RequestFight(uint256 indexed fighterId, uint256 indexed opponentId, uint256 indexed requestId);

	VRFCoordinatorV2Interface private immutable vrfCoordinator;
	bytes32 private immutable keyHash;
	uint64 private immutable subscriptionId;

	uint256 private _tokenIdCounter;

	uint256[34] public weaponsScoreUnit;

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
		uint64 _subscriptionId,
		uint256[34] memory _weaponsScoreUnit
	) ERC721("Fighter", "FGHT") VRFConsumerBaseV2(_vrfCoordinatorAddr) {
		vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorAddr);
		keyHash = _keyHash;
		subscriptionId = _subscriptionId;
		weaponsScoreUnit = _weaponsScoreUnit;
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

		uint256 requestId = vrfCoordinator.requestRandomWords(keyHash, subscriptionId, 3, 1000000, 3);
		randomRequests[requestId] = RandomRequest(true, false, new uint256[](0), tokenId, 0, ActionRequest.LEVEL);

		_safeMint(msg.sender, tokenId);
		_tokenIdCounter += 1;

		fighters[tokenId] = newFighter;

		emit MintFighter(newFighter, requestId);

		return tokenId;
	}

	function newLevel(uint256 _fighterId) public {
		if (ownerOf(_fighterId) != msg.sender) revert Errors.NotTheOwner();

		Fighter memory fighter = fighters[_fighterId];
		uint256 xpRequired = (fighter.level ^ 2) * 20; // Checker si la formule convient. Checker si y'a des issues avec les maths comme ça.

		if (fighter.xp < xpRequired) revert Errors.NotEnoughXP();

		uint256 requestId = vrfCoordinator.requestRandomWords(keyHash, subscriptionId, 3, 1000000, 3);
		randomRequests[requestId] = RandomRequest(true, false, new uint256[](0), _fighterId, 0, ActionRequest.LEVEL);

		fighters[_fighterId].level += 1;

		emit RequestNewLevel(fighter, fighter.level, requestId);
	}

	function fight(uint256 _fighterId, uint256 _opponentId) public {
		if (ownerOf(_fighterId) != msg.sender) revert Errors.NotTheOwner();
		if (ownerOf(_opponentId) == address(0)) revert Errors.DoNotExist(); // This ou checker si le level est >= 1 ?

		Fighter memory fighter = fighters[_fighterId];

		if (fighter.xp >= (fighter.level ^ 2) * 20) revert Errors.NeedToLevelUp();

		if (fighter.firstFightTime < (block.timestamp - 12 hours)) {
			fighter.dailyFights = 0;
			fighter.firstFightTime = block.timestamp;
		}
		if (fighter.dailyFights >= 3) revert Errors.TooManyFights();

		// Add un check pour ne pas fight plusieurs fois une même brute dans la journée ?

		uint256 requestId = vrfCoordinator.requestRandomWords(keyHash, subscriptionId, 3, 1000000, 1);
		randomRequests[requestId] = RandomRequest(
			true,
			false,
			new uint256[](0),
			_fighterId,
			_opponentId,
			ActionRequest.FIGHT
		);

		fighter.dailyFights += 1;

		fighters[_fighterId] = fighter;

		emit RequestFight(_fighterId, _opponentId, requestId);
	}

	function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
		if (!randomRequests[_requestId].exists) revert Errors.DoNotExist();

		randomRequests[_requestId].finalized = true;
		randomRequests[_requestId].randomWords = _randomWords;

		if (randomRequests[_requestId].action == ActionRequest.LEVEL) {
			_newLevelReward(randomRequests[_requestId]);
		} else {
			_fightExecution(randomRequests[_requestId]);
		}
	}

	function _newLevelReward(RandomRequest memory _request) internal {
		uint256 dice1 = _request.randomWords[0] % 12;
		uint256 dice2 = _request.randomWords[1] % 12;
		uint256 dice3 = _request.randomWords[2] % 12;
		uint256 weaponIndex = dice1 + dice2 + dice3;

		Fighter memory fighter = fighters[_request.fighterId];

		if (fighter.weapons[weaponIndex]) {
			fighter.strength += 3;
			fighter.agility += 3;
			fighter.rapidity += 3;
		} else {
			fighter.weapons[weaponIndex] = true;
			fighter.weaponsScore += weaponsScoreUnit[weaponIndex];
		}

		// 'dice1' needs to be multiple of 4 for an equal proba of each stats
		uint256 increaseStat = dice1 % 4;

		if (increaseStat == 0) {
			fighter.strength += 3;
		} else if (increaseStat == 1) {
			fighter.agility += 3;
		} else if (increaseStat == 2) {
			fighter.rapidity += 3;
		}

		fighters[_request.fighterId] = fighter;

		emit NewLevel(fighter, fighter.level, weaponIndex, increaseStat);
	}

	function _fightExecution(RandomRequest memory _request) internal {
		uint256 randomNumber = _request.randomWords[0] % 100;

		Fighter memory fighter = fighters[_request.fighterId];
		Fighter memory opponent = fighters[_request.opponentId];

		bool isWinner = randomNumber < 50; // 50% for now, find equation for fight winner proba determination

		uint256 newXp = (fighter.level * 2) + 20;
		if (isWinner) newXp = ((fighter.level * 4) + 40) / (fighter.level / opponent.level);

		fighter.xp += newXp;

		fighters[_request.fighterId] = fighter;

		emit Fight(_request.fighterId, _request.opponentId, isWinner, newXp);
	}

	function withdrawFunds() public {
		(bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		require(success, "Failed");
	}
}
