**EIP Draft : new IERC721 implementation to eliminate minting fee ERC721FancyMint**

**eip: eip-draft_ERC721FancyMint**\
**title: ERC721FancyMint** \
**author: scinftist.eth  (shypink@protonmail.com)**\
**status: draft not submitted**\
**type: ERC**\
**created: 2022-11-3**\
requires (*optional): <EIP 165 721 2309>

# Abstract
This standard proposes another implementation to `IERC721` Non-Fungible Tokens (NFTs) to enable batch minting for fixed length collection at construction of the contract and regaining single `_mint()` capability after deployment while providing ERC721Enumerable extension.

# Motivation
As of today there is 3 way to create a collection.

1. Minting the tokens ahead so people can see it and find it trough market places. this includes minting fee for creators!

2. create a contract and people mint the tokens, with first come first served strategy. <br> people cant see the Tokens before hand. and users don't know what they get.

3. using just in time minting or Lazy minting. that is only accessible trough one platform.<br> this limits the creators to one platform.

 this implementation is like creator minted arbitrary number of tokens before hand without using gas fee on minting process.

**benefits**:

1.  any number of token mint in constructor with `O(1)` execution.

2. user can view the tokens before purchasing.

3. tokens are accessible trough all Ethereum platforms.

**caveat**

* this token does not support `_burn()` function.

# Specification
1. `maxSupply` is desired number of token that we want to mint
2. `preOwner` is the address that all tokens will be transferred to


## Interface

* this interface is needed for Enumerable extension (`IERC721Enumerable`) of this contract.

```
// get the preOwner of a tokens
function preOwner() public view returns(address);


// get the maxSupply of a token
function maxSupply() public view returns(uint256);

```

The `preOwnwer_` MUST NOT be 0x0 (i.e. zero address).
The `preOwner_` MUST NOT change.

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
    address private immutable _preOwner;

    
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

    /**@dev my proposal
     * i
     *for values greater equal than maxSupply, ownerOf(tokenId) will alweys return zero address 0x0 i.e address(0).
     * therefor token _exist() is false for these values.
     * for values smaller than maxSupply, if _owners[tokenId] is not address 0 the owner is the returned value.
     *If the _owners[tokenId] is the defualt value 0x0 (i.e address(0) )  & the tokenId is smaller than maxSupply it returns preOwner.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        address owner = _owners[tokenId];
        if (owner == address(0) && (tokenId < _maxSupply)) {
            return _preOwner;
        }
        return owner;
    }

\\**@dev update _maxSupply in minting
*
*/
function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
            _maxSupply += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }



    //-----------------------
    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function preOwner() public view returns (address) {
        return _preOwner;
    }

 \\\ _burn() is removed from openZeppelin ERC721 Implementation V4.7.0



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

 this function that where omitted from ERC721.sol openZeppelin v4.7.0
 *  `_burn(uint256 tokenId)` 



# Backwards Compatibility

   this standard is fully compatible with all IERC721.

* since this implementation does not support any _burn function event Transfer() to 0x0 (i.e. address(0) ) will never happen.

*  `Transfer()` event from account `from` address `0x0` (i.e. address(0) ) won't happen in batch minting there will be only 1 minting event that happens in `constructor()` and token creation emits via `ConsecutiveTransfer()` event, and after that token creation handles via
```
ConsecutiveTransfer(0, maxSupply_ - 1, address(0), preOwner_)
```

# Test Cases

this test case was created before: adding _mint() for single mint functionality
 Test cases were Implemented in PR:
 [Fancy Project : Premeium](https://opensea.io/collection/fancy-project-premeium)

and 

[minting 2**256 -1 ERC721 with IERC721Enumarable capability](https://ethereum-magicians.org/t/proof-of-concept-minting-2-256-1-erc721-with-ierc721enumarable-capability/12467)
some of the tokens has been listed for sale for testing



# Reference Implementation


 Test cases where Implemented in PR:
 [../assets/eip-draft_ERC721FancyMint/ERC721FancyMint.sol](https://github.com/shypink/EIP-draft_ERC721FancyMint/tree/master/assets/eip-draft_FancyMint/ERC721FancyMint.sol)

## extension 
[ERC721FancyMintEnumarable](https://github.com/shypink/EIP-draft_ERC721FancyMint/tree/master/assets/eip-draft_FancyMint/FancyEnumerable_extension)
# Security Considerations

This EIP standard can completely protect the rights of the owner, the owner can change the NFT user and use period at any time.
 
 but if some how user burns a token, the owner of token will be set to `0x0` (i.e. address(0) ) the token won't be destroyed and it will assigned to preOwner. I don't know if it occurs or not, since the `_burn()` function is removed and `_trandfer()` function has require that prevent transfer `_to` address(0) `0x0`. I wish to hear from you if you can assure me on this.

 ```
 require(to != address(0), "ERC721: transfer to the zero address");
 ```

# Copyright


Copyright and related rights waived via CC0.