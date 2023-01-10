// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FancyEnumerable_extension/ERC721FancyMintEnumRef.sol";
import "@openzeppelin/contracts@4.7.0/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts@4.7.0/utils/Base64.sol";

contract Fancy2 is ERC721FancyMintEnum, Ownable {
    using Strings for uint256;

    //
    address private preOwner_ = 0x66aB6D9362d4F35596279692F0251Db635165871;
    uint256 private maxSupply_ = 5000;
    //

    string private head =
        '<svg width="240" height="80" viewBox="0 0 240 80" xmlns="http://www.w3.org/2000/svg"><rect width="200" height="40" style="fill:rgb(255,0,255);stroke-width:3;stroke:rgb(0,0,0)" /><text x="20" y="70" >';
    string private tail = "</text></svg>";

    constructor()
        ERC721FancyMint("Fancy second try", "fst", maxSupply_, preOwner_)
    {}

    function singleMint() public {
        _mint(msg.sender, totalSupply());
    }

    function generateSVG(uint256 id) internal view returns (string memory) {
        // string memory _svgString = head;

        return string(abi.encodePacked(head, id.toString(), tail));
    }

    function constructTokenURI(uint256 id)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"image": "data:image/svg+xml;base64,',
                                Base64.encode(bytes(generateSVG(id))),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function tokenURI(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(id), "token does not exist!");
        return constructTokenURI(id);
    }
}
