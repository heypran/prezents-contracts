import { Contract } from "ethers"
import { task, types } from "hardhat/config"

task("deploy:quizApp", "Deploy Quiz App contract")
  .addOptionalParam<boolean>("logs", "Logs ", true, types.boolean)
  .setAction(async ({ logs }, { ethers }): Promise<Contract> => {
    const ContractFactory = await ethers.getContractFactory("QuizApp")
    // const [owner] = await ethers.getSigners()

    const contract = await ContractFactory.deploy()
    await contract.deployed()

    logs && console.log(`QuizApp contract has been deployed to: ${contract.address}`)

    return contract
  })
