import { expect } from "chai"
import { Signer } from "ethers"
import { ethers } from "hardhat"
import { QuizApp } from "../build/typechain/QuizApp"
import { groth16 } from "snarkjs"

describe("QuizApp", () => {
  let quizAppContract: QuizApp
  let accounts: Signer[]

  before(async () => {
    accounts = await ethers.getSigners()

    const quizApp = await ethers.getContractFactory("QuizApp")
    quizAppContract = await quizApp.deploy()
  })

  // it("", async () => {

  //   await expect(transaction)
  //     .to.emit(ageCheckContract, "AgeVerfied")
  //     .withArgs(await accounts[0].getAddress(), true)
  // })
})
