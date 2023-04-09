import fs from "fs"
import hre, { ethers } from "hardhat"
import { bn, getDeployments, saveDeployments } from "../utils"
import { BigNumber, BigNumberish } from "ethers"

async function main() {
    // ==== Read Configuration ====
    const [deployer] = await hre.ethers.getSigners()

    let deployments = getDeployments()
    let calabiFactory
    let calabiRouter02

    const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

    const CalabiFactory = await ethers.getContractFactory("CalabiFactory")
    calabiFactory = await CalabiFactory.deploy(deployer.address)
    deployments.swap["CalabiFactory"] = calabiFactory.address
    saveDeployments(deployments)

    const CalabiRouter02 = await ethers.getContractFactory("CalabiRouter02")
    calabiRouter02 = await CalabiRouter02.deploy(
        deployments.swap.CalabiFactory,
        deployments.tokens.wFIL
    )
    deployments.swap["CalabiRouter02"] = calabiRouter02.address
    saveDeployments(deployments)

    // calabiFactory = await ethers.getContractAt("CalabiFactory", deployments.swap.CalabiFactory)

    // await calabiFactory.createPair(
    //     deployments.tokens.wFIL,
    //     deployments.tokens.USDC
    // )
    // await wait()
}

let count = 1
async function wait() {
    console.debug(`>>> [${count}] Waiting...`)
    count += 1
    return new Promise((resolve) => setTimeout(resolve, 4500))
}

function format(x: number, decimals: number = 18) {
    return bn(`${x}e${decimals}`).toString()
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
