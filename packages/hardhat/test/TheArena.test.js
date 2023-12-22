// HAPPY PATH //

// Constructor :
// // - Verify if 'weaponsScoreUnit' is set
// // - Verify if Chainlink VRF works well

// MintFighter :
// // - Verify it creates the NFT with msg.value of '0.001 eth'
// // - Verify it returns the 'tokenId'
// // - Verify the tokenId has been incremented
// // - Verify it has the good name
// // - Verify the new Fighter is stored in 'fighters[]' mapping
// // - Verify the new Request is stored in 'randomRequests[]' mapping
// // - Verify the new Fighter is owned by msg.sender
// // - Verify the NFT balance of the owner has been incremented
// // - Verify the event 'MintFighter()' is emit

// NewLevel :
// // - Verify Fighter level has been incremented
// // - Verify the new Request has been created and stored in the mapping
// // - Verify the event 'RequestNewLevel()' is emit
// // - Verify weapon & stats has been added to the Fighter
// // - Verify it is randomly choose
// // - Verify the event 'NewLevel()' is emit

// Fight :
// // - Verify 'dailyFights' has been incremented
// // - Verify the Fighter can fight if he have less than 3 fights
// // - Verify the Fighter can fight if his 3 fights were more than 12 hours ago
// // - Verify 'firstFightTime' and 'dailyFights' reset for the case above
// // - Verify the new Request has been created and stored in the mapping
// // - Verify the event 'RequestFight()' is emit
// // - Verify the new xp has been added to the Fighter
// // - Verify the fight winner is randomly choose
// // - Verify the event 'Fight()' is emit

// Verify 'withdrawFunds()' function works

// NON HAPPY PATH //

// Constructor :
// // - Verify it reverts if a value is missing
// // - Verify it reverts or prevent if VRFCoordinator is fake (?)

// MintFighter :
// // - Verify it reverts if value is not '0.001 eth'
// // - Verify it reverts if name is not a string
