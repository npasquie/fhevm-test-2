import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";

import type { YaoPrivate } from "../../types";
import { awaitAllDecryptionResults } from "../asyncDecrypt";
import { createInstances } from "../instance";
import { getSigners, initSigners } from "../signers";
import type { FhevmInstances } from "../types";

interface YaoPrivateContext {
  yao: YaoPrivate;
}

describe.only("TestYaoPrivate", function () {
  const ctx: YaoPrivateContext = {} as YaoPrivateContext;

  before(async function () {
    await initSigners();
    this.signers = await getSigners();
  });

  beforeEach(async function () {
    ctx.yao = await deployYaoPrivateFixture();
    this.contractAddress = await ctx.yao.getAddress();
    this.instances = await createInstances(this.signers);
  });

  it("should find the richest user", async function () {
    submitWealthWith(this.signers.bob, this.instances.bob, 200);
    submitWealthWith(this.signers.alice, this.instances.alice, 100);

    console.log(this.contractAddress);

    const richest = await ctx.yao.richest();
    expect(richest).to.equal(this.signers.bob.address);
  });

  async function submitWealthWith(
    userSigner: HardhatEthersSigner,
    userInstance: FhevmInstances[keyof FhevmInstances],
    wealthValue: number,
  ) {
    console.log("yao addr", await ctx.yao.getAddress());
    console.log("userAdd", userSigner.address);
    const input = userInstance.createEncryptedInput(await ctx.yao.getAddress(), userSigner.address);
    input.add64(wealthValue);
    const encryptedWealthSubmission = input.encrypt();

    console.log(encryptedWealthSubmission.handles[0]);
    console.log(encryptedWealthSubmission.inputProof);

    const tx = await ctx.yao
      .connect(userSigner)
      .submitWealth(encryptedWealthSubmission.handles[0], encryptedWealthSubmission.inputProof);
    await tx.wait();
    await awaitAllDecryptionResults();
  }
});

async function deployYaoPrivateFixture(): Promise<YaoPrivate> {
  const signers = await getSigners();

  const contractFactory = await ethers.getContractFactory("YaoPrivate");
  const contract = await contractFactory.connect(signers.alice).deploy([signers.alice.address, signers.bob.address]);
  await contract.waitForDeployment();

  return contract;
}
