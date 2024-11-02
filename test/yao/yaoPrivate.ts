import { expect } from "chai";
import { ethers } from "hardhat";

import type { YaoPrivate } from "../../types";
import { awaitAllDecryptionResults } from "../asyncDecrypt";
import { createInstances } from "../instance";
import { getSigners, initSigners } from "../signers";

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
    const input = this.instances.alice.createEncryptedInput(this.contractAddress, this.signers.alice.address);
    input.add64(100);
    const encryptedWealthSubmission = input.encrypt();
    const tx = await ctx.yao["submitWealth"](
      encryptedWealthSubmission.handles[0],
      encryptedWealthSubmission.inputProof,
    );
    await tx.wait();
    await awaitAllDecryptionResults();
    const richest = await ctx.yao["richest"]();
    expect(richest).to.equal(this.signers.alice.address);
  });
});

async function deployYaoPrivateFixture(): Promise<YaoPrivate> {
  const signers = await getSigners();

  const contractFactory = await ethers.getContractFactory("YaoPrivate");
  const contract = await contractFactory
    .connect(signers.alice)
    .deploy(signers.alice.address, signers.bob.address, signers.carol.address);
  await contract.waitForDeployment();

  return contract;
}
