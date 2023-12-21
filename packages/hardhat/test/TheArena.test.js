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
