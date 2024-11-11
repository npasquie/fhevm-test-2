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

describe("TestYaoPrivate", function () {
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
    submitWealthWith(this.instances.bob, 200);
    submitWealthWith(this.instances.alice, 100);
    const richest = await ctx.yao["richest"]();
    console.log(richest);
    console.log(this.signers.bob.address);
    expect(richest).to.equal(this.signers.bob.address);
  });

  async function submitWealthWith(user: FhevmInstances[keyof FhevmInstances], wealthValue: number) {
    const input = user.createEncryptedInput(ctx.yao.getAddress(), user.address);
    input.add64(wealthValue);
    const encryptedWealthSubmission = input.encrypt();
    const tx = await ctx.yao["submitWealth"](
      encryptedWealthSubmission.handles[0],
      encryptedWealthSubmission.inputProof,
    );
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
