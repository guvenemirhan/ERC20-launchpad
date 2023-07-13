// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "../interfaces/IUniswapV2Factory.sol";

library LPLib {
    /**
     * @notice Check if the given token is an LP token.
     * @dev This function uses the UniswapV2Pair interface to try and call the 'factory' method on the given token.
     * If the call is successful, the function further checks if the token is a valid LP token using _isValidLpToken helper function.
     * If the token is a valid LP token, the address of the factory that created the LP token is returned.
     * If the call to the 'factory' method fails, it implies that the token is not an LP token and a revert operation is executed.
     * @param currency The address of the token to be checked.
     * @return factory The address of the UniswapV2 factory that created the token if it's an LP token.
     *
     * Requirements:
     * - The currency must be a valid LP token.
     */
    function isLPToken(
        address currency
    ) internal view returns (address factory) {
        try IUniswapV2Pair(currency).factory() returns (address result) {
            require(_isValidLpToken(currency, result), "Token is not LP token");
            factory = result;
        } catch {
            revert("Token is not LP token");
        }
        return factory;
    }

    /**
     * @notice Check if the given token is a valid LP token created by the provided UniswapV2 factory.
     * @dev This function compares the pair address returned by the 'getPair' method of the UniswapV2 factory with the token address.
     * If the pair address matches the token address, the function returns true indicating the token is a valid LP token.
     * @param token The address of the token to be checked.
     * @param factory The address of the UniswapV2 factory that supposedly created the token.
     * @return true if the token is a valid LP token created by the provided UniswapV2 factory, false otherwise.
     */
    function _isValidLpToken(
        address token,
        address factory
    ) private view returns (bool) {
        IUniswapV2Pair pair = IUniswapV2Pair(token);
        address factoryPair = IUniswapV2Factory(factory).getPair(
            pair.token0(),
            pair.token1()
        );
        return factoryPair == token;
    }
}
