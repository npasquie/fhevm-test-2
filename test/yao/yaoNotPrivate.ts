import { expect } from "chai";
import { ethers } from "hardhat";

import type { YaoNotPrivate } from "../../types";
import { createInstances } from "../instance";
import { getSigners, initSigners } from "../signers";

interface YaoNotPrivateContext {
  yao: YaoNotPrivate;
}

describe("TestYaoNotPrivate", function () {
  const ctx: YaoNotPrivateContext = {} as YaoNotPrivateContext;

  before(async function () {
    await initSigners();
    this.signers = await getSigners();
  });

  beforeEach(async function () {
    ctx.yao = await deployYaoNotPrivateFixture();
    this.contractAddress = await ctx.yao.getAddress();
    this.instances = await createInstances(this.signers);
  });

  it("should find the richest user", async function () {
    const [alice, bob, carol] = await ethers.getSigners();
    await ctx.yao.connect(alice).submitWealth(100);
    await ctx.yao.connect(bob).submitWealth(200);
    await ctx.yao.connect(carol).submitWealth(300);
    const richest = await ctx.yao.richest();
    expect(richest).to.equal(carol.address);
  });
});

async function deployYaoNotPrivateFixture(): Promise<YaoNotPrivate> {
  const signers = await getSigners();

  const contractFactory = await ethers.getContractFactory("YaoNotPrivate");
  const contract = await contractFactory
    .connect(signers.alice)
    .deploy(signers.alice.address, signers.bob.address, signers.carol.address);
  await contract.waitForDeployment();

  return contract;
}
