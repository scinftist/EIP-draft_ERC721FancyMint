**EIP Draft : new IERC721 implementation to eliminate minting fee ERC721FancyMint**

**eip: eip-draft_ERC721FancyMint**\
**title: ERC721FancyMint** \
**author: scinftist.eth  (shypink@protonmail.com)**\
**status: draft not submitted**\
**type: ERC**\
**created: 2022-11-3**\
requires (*optional): <EIP 165 721 2309>

# Abstract
This standard proposes another implementation to `IERC721` Non-Fungible Tokens (NFTs) to eliminate minting fee of fixed length collection.

# Motivation
As of today there is 3 way to create a collection.

1. Minting the tokens ahead so people can see it and find it trough market places. this includes minting fee for creators!

2. create a contract and people mint the tokens, with first come first served strategy. <br> people cant see the Tokens before hand. and users don't know what they get.

3. using just in time minting or Lazy minting. that is only accessible trough one platform.<br> this limits the creators to one platform.

 this implementation is like creator minted arbitrary number of tokens before hand without using gas fee on minting process.

**benefits**:

1. no minting fee, any number of token mint in constructor with `O(1)` execution.

2. user can view the tokens before purchasing.

3. tokens are accessible trough all Ethereum platforms.

**caveat**

1. any number of tokens should be minted at deployment time, an there is no further `_mint()` or `_safeMint()` function available.

2. this token does not support `_burn()` function.

# Specification
1. `maxSupply` is desired number of token that we want to mint
2. `preOwner` is the address that all tokens will be transferred to


## Interface

* this interface is needed for Enumerable extension (`IERC721Enumerable`) of this contract.

```
// get the preOwner of a tokens
function preOwner() external view returns(address);


// get the maxSupply of a token
function maxSupply() external view returns(uint256);

```

The `maxSupply_` MUST NOT be 0.
The `preOwnwer_` MUST NOT be 0x0 (i.e. zero address).


## Implementation

proposed changes to 
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)
for full Implementation see Reference Implementation.
```
//proposed changes

contract ERC721FancyMint is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC2309
{
     *@dev my proposal
     */

    //max
    uint256 private _maxSupply;
    //NFT owner
    address private _preOwner;

    
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        address preOwner_
    ) {

        require(preOwner_ != address(0), "preOwner can NOT be address(0)");
        require(0 < maxSupply_, "maxSupply_ should not be zero!");
        _name = name_;
        _symbol = symbol_;

        //@dev my proposal

        _maxSupply = maxSupply_;
        _preOwner = preOwner_;
        // blance of preOwner
        _balances[preOwner_] = maxSupply_;

        // see eip-2309 examples for batch creation
        emit ConsecutiveTransfer(0, maxSupply_ - 1, address(0), preOwner_);
    }

    function ownerOf(uint256 tokenId) view return(address) {
    if (tokenId < _maxSupply {
      return _owners[tokenId] ? _owners[tokenId] : _preOwner;
    }
  }



    //-----------------------
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function preOwner() public view returns (address) {
        return _preOwner;
    }

// and _mint() _safeMint() _burn() are removed from openZeppelin ERC721 Implementation V4.7.0



}


```

# Rationale
since `EIP-2309` make the creation of arbitrary number of Tokens possible.

this changes make this possible.

since the default value of `_balances` mapping is `0`.

* At creation time we assigned `maxSupply` to `_balances[preOwner]`  from IERC721 interface point of view, preOwner has maxSupply number of tokens as it's balance.

* this contract consider `tokenIds` range from `0` to `( maxSupply - 1 )`.

* to handle owners addresses, `_ownerOf(tokenId)` has been changed, If the `_owners[tokenId]` is the defualt value `0x0` (i.e address(0) )  & the `tokenId` is smaller than `maxSupply` it returns `preOwner`. else it returns the value that is stored in mapping.

these changes wont affect the functionality of `IERC721`.

* the interface is consist of two external functions, they are necessary for Enumerable (`IERC721Enumerable`) extension of this standard.

```
/**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }



    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
```

  for values greater equal than `maxSupply`, `_ownerOf(tokenId)` will alweys return   `0x0` i.e address(0). therefore token `_exist()` is `false` for these values.

 for values smaller than `maxSupply`, if `_owners[tokenId]` is not `0x0` address(0) the owner is the returned value.

 since there is no other function that uses `_ownerOf(tokenId)`, the behavior of the contract is the same as `ERC721` implementation of `ERC721` by OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

 these function that where omitted
 1.  `_burn(uint256 tokenId)` 
 2. `_mint(address to, uint256 tokenId) `
 3. `_safeMint(address to, uint256 tokenId, bytes memory data)`
 4. `_safeMint(address to, uint256 tokenId)`


# Backwards Compatibility

   this standard is fully compatible with all IERC721.

* since this implementation does not support any _burn function event Transfer() to 0x0 (i.e. address(0) ) will never happen.

*  `Transfer()` event from account `from` address `0x0` (i.e. address(0) ) won't happen because there will be only 1 minting event that happens in `constructor()` and token creation emits via `ConsecutiveTransfer()` event
```
ConsecutiveTransfer(0, maxSupply_ - 1, address(0), preOwner_)
```

# Test Cases

 Test cases were Implemented in PR:
 [../assets/eip-draft_ERC721FancyMint/testCase.sol](https://github.com/shypink/EIP-draft_ERC721FancyMint/tree/master/assets/eip-draft_FancyMint/testCase.sol)

some of the tokens has been listed for sale for testing

[Test Case 1 on goerli testnet with 5000 tokens](https://goerli.etherscan.io/address/0xae3a99bd429238a6d2a48749a1e007c1fcf39053)

[Test case 1 on OpenSea with 5000 tokens](https://testnets.opensea.io/collection/fancy-first-try)

some of the tokens has been listed for sale for testing but this test case includes 6000 token but opensea fails to show some tokens (`tokenId` 5000 to 5999), i think it's due to bad implementation of `EIP-2309`, I'm getting in touch with them, and I wish to hear about your thoughts on this matter.

see [EIP-2309 examples](https://eips.ethereum.org/EIPS/eip-2309) 

> "Batch token creation:<br> emit ConsecutiveTransfer(1, 100000, address(0), to Address);"

[Test Case 2 on goerli testnet with 6000 tokens](https://goerli.etherscan.io/address/0x39095ebb95f3576f522a16fba4a21c2c109f4e98)

[Test case 2 on OpenSea with 6000 tokens](https://testnets.opensea.io/collection/fancy-second-try)


# Reference Implementation


 Test cases where Implemented in PR:
 [../assets/eip-draft_ERC721FancyMint/ERC721FancyMint.sol](https://github.com/shypink/EIP-draft_ERC721FancyMint/tree/master/assets/eip-draft_FancyMint/ERC721FancyMint.sol)

# Security Considerations

This EIP standard can completely protect the rights of the owner, the owner can change the NFT user and use period at any time.
 
 but if some how user burns a token, the owner of token will be set to `0x0` (i.e. address(0) ) the token won't be destroyed and it will assigned to preOwner. I don't know if it occurs or not, since the `_burn()` function is removed and `_trandfer()` function has require that prevent transfer `_to` address(0) `0x0`. I wish to hear from you if you can assure me on this.

 ```
 require(to != address(0), "ERC721: transfer to the zero address");
 ```

# Copyright


Copyright and related rights waived via CC0.