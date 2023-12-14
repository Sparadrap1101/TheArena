// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import { Errors } from "./libraries/Errors.sol";

contract TheArena is ERC721 {
	event MintFighter(Fighter indexed fighter);
	event NewLevel(Fighter indexed fighter, uint256 indexed level);

	uint256 private _tokenIdCounter;

	uint256[10] public weaponsScoreUnit; // To initialize in contructor? (constant/immutable ?)

	mapping(uint256 => Fighter) public fighters;

	struct Fighter {
		uint256 tokenId; // Incrémentation basique ou mettre des infos dedans ? Faire un ERC721 et go sur IPFS avec les metadatas
		string name;
		uint256 level;
		uint256 xp; // Nécessaire ? Comment gérer l'xp en fonction des level ? Faire que ce soit plus dur
		string grade; // uint?
		uint256 strength;
		uint256 agility;
		uint256 rapidity;
		bool[10] weapons; // Weapons & Skills, passer le bool en true quand on en gagne une
		uint256 weaponsScore; // Ajouter le score du weapon au score déjà existant avec les valeurs unitaires des scores dans _weaponsScoreUnit
		uint8 dailyFights;
		uint256 firstFightTime;
	}

	constructor() ERC721("Fighter", "FGHT") {}

	function mintFighter(string memory _name) public payable returns (uint256) {
		if (msg.value != 0.001 ether) revert Errors.MintValueError();

		uint256 tokenId = _tokenIdCounter;

		bool[10] memory resetWeapons;
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

		newFighter = _newLevelReward(newFighter);

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

		fighter = _newLevelReward(fighter);
		fighter.level += 1;

		fighters[_fighterId] = fighter;

		emit NewLevel(fighter, fighter.level); // Add the new weapon in the event ?
	}

	// Random & reward logic for the new level
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
