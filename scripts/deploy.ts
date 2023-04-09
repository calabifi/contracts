import hre from "hardhat"

import { getChainId, sh } from "./utils"

async function main() {
    const [deployer] = await hre.ethers.getSigners()
    const chainId = await getChainId(hre)

    console.log(`Starting full deployment on network ${hre.network.name} (${chainId})`)
    console.log(`Deployer account: ${deployer.address}\n`)

    const scripts: string[] = [
        // "0_deploy_tokens.ts",
        "1_deploy_swap.ts",
        // "2_deploy_misc.ts",
        // "3_deploy_farm.ts",
        // "4_deploy_vault.ts",
    ]

    for (const script of scripts) {
        console.log(
            "\n===========================================\n",
            script,
            "\n===========================================\n"
        )
        await sh(`yarn hardhat run scripts/deployment/${script}`)
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
