// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Escrow.sol";
import "../src/MockERC20.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Escrow escrow = new Escrow();
        MockERC20 tokenA = new MockERC20("Token A", "TKA");
        MockERC20 tokenB = new MockERC20("Token B", "TKB");

        escrow.addToken(address(tokenA));
        escrow.addToken(address(tokenB));

        address[3] memory accounts = [
            0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
        ];

        for (uint i = 0; i < accounts.length; i++) {
            tokenA.mint(accounts[i], 1000 ether);
            tokenB.mint(accounts[i], 1000 ether);
        }

        vm.stopBroadcast();

        console.log("deploy_escrow=", address(escrow));
        console.log("deploy_tokenA=", address(tokenA));
        console.log("deploy_tokenB=", address(tokenB));
    }
}
