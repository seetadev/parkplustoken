const { expect } = require("chai");
const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const web3 = require('web3');
const fs = require('fs');

describe("WorkflowBase", function() {
    let workflowBase;

    beforeEach(async function() {
        // Assuming you have a fixture to deploy the WorkflowBase contract
        workflowBase = await loadFixture(deployWorkflowBase);
    });

    describe("getLatestIds", function() {
        it("should return an empty array if no IDs exist", async function() {
            const result = await workflowBase.getLatestIds(5);
            expect(result).to.be.an('array').that.is.empty;
        });

        it("should return all IDs if count is greater than total IDs", async function() {
            // Assuming you have a method to add items and increase the count
            await workflowBase.addItems(3); // Add 3 items for example

            const result = await workflowBase.getLatestIds(5);
            expect(result).to.have.lengthOf(3);
            expect(result).to.eql([1n, 2n, 3n]);
        });

        it("should return the latest 'cnt' IDs", async function() {
            await workflowBase.addItems(5); // Add 5 items

            const result = await workflowBase.getLatestIds(3);
            expect(result).to.have.lengthOf(3);
            expect(result).to.eql([3n, 4n, 5n]);
        });

        it("should return the correct IDs even if count is increased", async function() {
            await workflowBase.addItems(10); // Add 10 items

            const result = await workflowBase.getLatestIds(5);
            expect(result).to.have.lengthOf(5);
            expect(result).to.eql([6n, 7n, 8n, 9n, 10n]);
        });
    });
});

// Fixture to deploy the WorkflowBase contract
async function deployWorkflowBase() {
    const WorkflowBase = await ethers.getContractFactory("WorkflowBaseMock");
    return await WorkflowBase.deploy();
}
