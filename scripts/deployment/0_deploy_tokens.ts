import fs from "fs"
import hre, { ethers } from "hardhat"
import { bn, getDeployments, saveDeployments } from "../utils"

async function main() {
    // ==== Read Configuration ====
    const [deployer] = await hre.ethers.getSigners()

    let deployments = getDeployments()

    const initialSupply = format(600000)

    const MockERC20 = await ethers.getContractFactory("MockERC20")
    const WETH9 = await ethers.getContractFactory("WETH9")

    // const wfil = await WETH9.deploy()
    // deployments.tokens["wFIL"] = wfil.address
    // saveDeployments(deployments)

    // // await wait()

    // const dct = await MockERC20.deploy("DCT", "DCT", initialSupply)
    // deployments.tokens["DCT"] = dct.address
    // saveDeployments(deployments)

    // // await wait()

    // const dib = await MockERC20.deploy("DIB", "DIB", initialSupply)
    // deployments.tokens["DIB"] = dib.address
    // saveDeployments(deployments)

    // // await wait()

    // // Wallaroo
    // const wlr = await MockERC20.deploy("WLR", "WLR", initialSupply)
    // deployments.tokens["WLR"] = wlr.address
    // saveDeployments(deployments)

    // // await wait()

    // const mav = await MockERC20.deploy("MAV", "MAV", initialSupply)
    // deployments.tokens["MAV"] = mav.address
    // saveDeployments(deployments)

    // // await wait()

    // const calabi = await MockERC20.deploy("CALABI", "CALABI", initialSupply)
    // deployments.tokens["CALABI"] = calabi.address
    // saveDeployments(deployments)
}

function format(x: number, decimals: number = 18) {
    return bn(`${x}e${decimals}`).toString()
}

let count = 1
async function wait() {
    console.debug(`>>> [${count}] Waiting...`)
    count += 1
    return new Promise((resolve) => setTimeout(resolve, 4500))
}

main().catch((error) => {
    console.error(error)
    process.exitCode = 1
})
