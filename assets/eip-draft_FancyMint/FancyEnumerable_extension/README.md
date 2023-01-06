# ERC721FancyMintEnumerable

## Abstract
minting massive number of via EIP-2309 was shown to be possible via other projects, but they could not maintain the IERC721Enumerable capability.
specialy `tokenOfOwnerByIndex()` 
> IERC721Enumerable:
```
/**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
```
this function is vital to Dapps. to find out tokenIds of a user.
the no project that I've seen that try to mint NFT in large batches while having this function the colosest thing that I've seen is [ERC721AQueryable.sol](https://github.com/chiru-labs/ERC721A/blob/main/contracts/extensions/ERC721AQueryable.sol) from chiru-labs.
> that has this interface
```
 /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(`totalSupply`) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
```
that has O(collectionSize) time complexity, and they should check the ownership of all tokens againts user address. and that limits that implementation. 
"bigger the collection longer the call."

## This Implementation

this extension is of today fit toward fixed length collection with `maxSupply` and a `preOwner` that you can read more in previous article.
* this collection as of now does not the mint() and burn() functionality. and it's a work in proggress. please join the discussion on [Ethereum-magician](https://ethereum-magicians.org/t/use-zero-gas-0-gwei-for-minting-any-number-of-nft/12403)

* most of the code is inspired by openZeppelin v4.7.0

----
## the code:

first `totalSupply()`:
```
/**
     * @dev See {IERC721Enumerable-totalSupply}.
     also see maxSupply ERC721FancyMint
     */
    function totalSupply() public view virtual override returns (uint256) {
        return ERC721FancyMint.maxSupply();
    }

```

second `tokenByIndex(index)`:

```
 /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    /**
     * @dev handling tokens index virtualy
     */

function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721FancyMintEnum.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return index;
    }

```
## the third part `tokenOfOwnerByIndex( owner,  index)`:

this part introduce a two new storage:

```

// Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

```
this to handle the token for others tha preOwner.

```
/**
     * @dev this part handle _preOwner tokens to index and tokens index to tokens
     */
    //preOwner _indexHandelr index - >tid
    mapping(uint256 => uint256) private _preOwnerIndexHandler;
    // preOwner _tokenHandler tid -> index
    mapping(uint256 => uint256) private _preOwnerTokenHandler;

```


changing the {_beforeTokenTransfer} Hook to

```
/** @dev it's my proposal
     save me */

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        address _preOwner = ERC721FancyMint.preOwner();

        if (from == address(0)) {
            //does not support minting
            revert("fromm == zero, does not support minting");
        } else if (from != to) {
            if (from == _preOwner) {
                _removeTokenFromPreOwner(tokenId);
            } else {
                _removeTokenFromOwnerEnumeration(from, tokenId);
            }
        }
        if (to == address(0)) {
            //does not support burning
            revert("to == zero, does not support burning");
        } else if (to != from) {
            if (to == _preOwner) {
                _addTokenToPreOwner(tokenId);
            } else {
                _addTokenToOwnerEnumeration(to, tokenId);
            }
        }
    }
```

## this need the to introduce complementary functions 

1. remove from enumaration

 these two that both remove token from enumaration, one for other `owners` and one for `preOwner`
```
//implemented the same as openZeppelin V4.7.0
_removeTokenFromOwnerEnumeration(from, tokenId);
```

```
 _removeTokenFromPreOwner(tokenId);

``` 

2. add to enumaration

these two that both add token to enumaration, one for other `owners` and one for `preOwner`

```
//implemented the same as openZeppelin V4.7.0
_addTokenToOwnerEnumeration(address to, uint256 tokenId)

```
```
/**@dev me
     * it's like _addTokenToOwnerEnumeration function but for the _preOwner.
     */
    function _addTokenToPreOwner(uint256 tokenId)
    
```

3. for handling preOwner Token -> index , index -> token

this two function got introduced.
```
 /**@dev my proposal
     * @param  _index  get it and return tokenId for preOwner
     *
     * since we add 1 in to avoid confusion with defual value of the mapping we  subtract 1 to get tokenIndex
     * if token hasn't been transferd from preOwner the _preOwnerIndexHandler is 0 (defualt value) so we use virtual Indexing to create a value
     */

    function preIndex(uint256 _index) internal view returns (uint256) {
        uint256 virtual_index = _preOwnerIndexHandler[_index];
        if (virtual_index == 0) {
            return _index; //tokenId
        } else {
            return virtual_index - 1; //tokenId
        }
    }

    /**@dev my proposal
     * @param  _tokenId  get it and return tokenIndex for preOwner
     *
     * since we add 1 in to avoid confusion with defual value of the mapping we  subtract 1 to get tokenId
     *if token hasn't been transferd from preOwner the _preOwnerTokenHandler is 0 (defualt value) so we use virtual Indexing to create a value
     */

    function preToken(uint256 _tokenId) internal view returns (uint256) {
        uint256 virtual_token = _preOwnerTokenHandler[_tokenId];
        if (virtual_token == 0) {
            return _tokenId; //index
        } else {
            return virtual_token - 1; //index
        }
    }
```
so know we implment `_addTokenToPreOwner(uint256 tokenId)` and `_removeTokenFromPreOwner(uint256 tokenId)` like this:
```
  function _removeTokenFromPreOwner(uint256 tokenId) internal {
        address _preOwner = ERC721FancyMint.preOwner();
        uint256 lastTokenIndex = ERC721FancyMint.balanceOf(_preOwner) - 1;
        uint256 tokenIndex = preToken(tokenId);
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = preIndex(lastTokenIndex);
            // Move the last token to the slot of the to delete token ,and add 1 to avoid confusion with defualt  value of _preOwnerIndexHandler mapping  that is 0
            _preOwnerIndexHandler[tokenIndex] = lastTokenId + 1;
            // Update the moved token's index and add 1 to avoid confusion with defualt value of _preOwnerTokenHandler mapping that is 0
            _preOwnerTokenHandler[lastTokenId] = tokenIndex + 1;
        }

        // This also deletes the contents at the last position of the array
        delete _preOwnerIndexHandler[lastTokenIndex];
        delete _preOwnerTokenHandler[tokenId];
    }
```
```
function _addTokenToPreOwner(uint256 tokenId) private {
        address _preOwner = ERC721FancyMint.preOwner();
        uint256 length = ERC721FancyMint.balanceOf(_preOwner);
        // add 1 to tokenId to avoid confusion with default value of _preOwnerIndexHandler mapping that is 0
        _preOwnerIndexHandler[length] = tokenId + 1;
        // add 1 to length(that is used for Index) to avoid confusion with default value of _preOwnerTokenHandler mapping that is 0
        _preOwnerTokenHandler[tokenId] = length + 1;
    }

```