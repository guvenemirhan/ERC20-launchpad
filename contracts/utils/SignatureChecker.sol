// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Presale} from "../interfaces/IPresale.sol";

abstract contract SignatureChecker is Ownable2Step {
    bytes32 private constant _PERMIT_TYPEHASH =
        0xe3aca7fab33e0dccb49669fa7f9baddb2a5592f009b2eab552bacb4dc72594e6;
    bytes32 private immutable _domainSeperator;
    address private _signer;

    /**
     * @notice Initializes the contract with the specified signer address and creates the domain separator.
     * @param signer The address of the signer.
     * @dev The signer address cannot be the zero address.
     * @dev The domain separator is generated using the EIP-712 standard and includes the contract's name, version, chain ID, and verifying contract address.
     */
    constructor(address signer) {
        require(signer != address(0));
        _signer = signer;
        _domainSeperator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("EIP712-Derive")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @notice Changes the signer address.
     * @param newSigner The new signer address.
     * @dev Only the contract owner can change the signer address.
     * @dev The new signer address cannot be the zero address.
     * @return A boolean indicating whether the signer address was successfully changed.
     */
    function changeSigner(address newSigner) external onlyOwner returns (bool) {
        require(
            newSigner != address(0),
            "New signer address cannot be a zero address"
        );
        _signer = newSigner;
        return true;
    }

    /**
     * @notice Recovers the signer address from the provided signature.
     * @param presale The Presale struct containing the data to be signed.
     * @param signature The signature to recover the signer address.
     * @return A boolean indicating whether the signature is valid and matches the signer address.
     */
    function recover(
        Presale memory presale,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeperator,
                keccak256(abi.encode(_PERMIT_TYPEHASH, presale))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = split(signature);
        address recoveredAddress = ecrecover(digest, v, r, s);
        bool success = recoveredAddress == _signer;
        return success;
    }

    /**
     * @notice Splits the provided signature into its components: v, r, and s.
     * @param signature The signature to split.
     * @return The components v, r, and s of the signature.
     * @dev Assumes that the signature is in the correct format (65 bytes).
     */
    function split(
        bytes memory signature
    ) public pure returns (uint8, bytes32, bytes32) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return (v, r, s);
        } else {
            revert("Wrong signature");
        }
    }
}
