import { config as dotEnvConfig } from "dotenv"
dotEnvConfig()

import "@typechain/hardhat"
import "@nomiclabs/hardhat-ethers"
import "@nomiclabs/hardhat-waffle"
import "@nomiclabs/hardhat-etherscan"
import "hardhat-deploy"

const PRIVATE_KEY = process.env.PRIVATE_KEY || ""

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            chainId: 31337,
            gas: 12000000,
            blockGasLimit: 0x1fffffffffffff,
            allowUnlimitedContractSize: true,
            timeout: 1800000,
            mining: {
                auto: false,
                interval: 5000,
            },
        },
        fvm: {
            chainId: 0x13a,
            url: "https://api.node.glif.io",
            accounts: [PRIVATE_KEY],
        },
    },
    namedAccounts: {
        deployer: {
            default: 0,
        },
    },
    solidity: {
        settings: {
            evmVersion: "istanbul",
            outputSelection: {
                "*": {
                    "": ["ast"],
                    "*": [
                        "evm.bytecode.object",
                        "evm.deployedBytecode.object",
                        "abi",
                        "evm.bytecode.sourceMap",
                        "evm.deployedBytecode.sourceMap",
                        "metadata",
                    ],
                },
            },
        },
        compilers: [
            {
                version: "0.6.12",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 999999,
                    },
                },
            },
            {
                version: "0.8.0",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 999999,
                    },
                },
            },
            {
                version: "0.8.2",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 999999,
                    },
                },
            },
            {
                version: "0.8.7",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 999999,
                    },
                },
            },
            {
                version: "0.8.9",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 999999,
                    },
                },
            },
        ],
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "../src/constants/artifacts",
    },
    typechain: {
        outDir: "./typechain",
    },
    mocha: {
        timeout: 50000,
    },
}
