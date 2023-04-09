import fs from "fs"
import hre, { ethers } from "hardhat"
import { bn, getDeployments, saveDeployments } from "../utils"
import { BigNumber, BigNumberish } from "ethers"

async function main() {
    // ==== Read Configuration ====
    const [deployer] = await hre.ethers.getSigners()

    let deployments = getDeployments()

    const Multicall2 = await ethers.getContractFactory("Multicall2")
    const multicall = await Multicall2.deploy()

    deployments.misc["Multicall2"] = multicall.address
    saveDeployments(deployments)
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
