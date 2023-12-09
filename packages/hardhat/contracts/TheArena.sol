// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import { Errors } from "./libraries/Errors.sol";

contract TheArena is ERC721 {
	event MintFighter(Fighter indexed fighter);
	event NewLevel(Fighter indexed fighter, uint256 indexed level);

	uint256 private _tokenIdCounter;

	bool[10] public weaponsScoreUnit; // To initialize (constant/immutable ?)

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

		bool[10] memory newWeapons;
		Fighter memory newFighter = Fighter(tokenId, _name, 1, 0, "Padawan", 2, 2, 2, newWeapons, 0, 0, 0);

		//newFighter = _newLevelReward(newFighter);

		_safeMint(msg.sender, tokenId);
		_tokenIdCounter += 1;

		fighters[tokenId] = newFighter;

		emit MintFighter(newFighter);

		return tokenId;
	}
}
