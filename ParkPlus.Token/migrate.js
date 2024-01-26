const { ethers } = require('ethers');
const fs = require('fs');
const csv = require('csv-parser');
const createCsvWriter = require('csv-writer').createObjectCsvWriter;

// Get command line arguments
const args = process.argv.slice(2);
if (args.length !== 4) {
    console.error("Usage: node migrate.js OLD_CONTRACT_ADDRESS NEW_CONTRACT_ADDRESS RPC_URL PRIVATE_KEY");
    process.exit(1);
}

const [oldContractAddress, newContractAddress, rpcUrl, privateKey] = args;

// Load the ABI
const abi = JSON.parse(fs.readFileSync('./bin/TixToken.abi', 'utf8'));
const oldabi = JSON.parse(fs.readFileSync('./TixToken.old.abi', 'utf8'));

// Connect to the provider
let provider = new ethers.providers.JsonRpcProvider(rpcUrl);
let wallet = new ethers.Wallet(privateKey, provider);

const csvWriter = createCsvWriter({
    path: 'cache.csv',
    header: [
        {id: 'blockNumber', title: 'BLOCKNUMBER'},
        {id: 'serviceName', title: 'SERVICE_NAME'}
    ],
    append: true
});

const BATCH_SIZE = 20;

async function migrate() {
    const oldContract = new ethers.Contract(oldContractAddress, oldabi, wallet);
    const newContract = new ethers.Contract(newContractAddress, abi, wallet);

    let lastProcessedBlock = 0;
    let cachedServiceNames = new Set();
    // Read cache.csv if it exists
    if (fs.existsSync('cache.csv')) {
        fs.createReadStream('cache.csv')
            .pipe(csv({ headers: false }))
            .on('data', (row) => {
                const values = Object.values(row);
                if (values.length >= 2 && values[0] && values[1]) {
                    lastProcessedBlock = Math.max(lastProcessedBlock, parseInt(values[0]));
                    cachedServiceNames.add(values[1].toString());
                }
            })
            .on('end', processMigration);
    } else {
        processMigration();
    }

    async function processMigration() {
        const logs = await provider.getLogs({
            address: oldContractAddress,
            fromBlock: lastProcessedBlock + 1,
            toBlock: 'latest',
            topics: [ethers.utils.id("ServiceRegistered(bytes32,address)")]
        });

        let uniqueServiceNames = new Set([...cachedServiceNames]);
        let serviceDestinations = {};

        for (let log of logs) {
            const event = oldContract.interface.parseLog(log);
            uniqueServiceNames.add(event.args._name);
            csvWriter.writeRecords([{ blockNumber: log.blockNumber, serviceName: event.args._name }]);
        }
        let batchedNames = [];
        let batchedDestinations = [];

        for (let serviceName of uniqueServiceNames) {
            const serviceRegistration = await oldContract.repository(serviceName);
            const newRegistration = await newContract.repository(serviceName);

            if (newRegistration.destination != serviceRegistration.destination || newRegistration.owner != serviceRegistration.owner)
            {
                batchedNames.push(serviceName);
                batchedDestinations.push({
                    destination: serviceRegistration.destination,
                    owner: serviceRegistration.owner, // or wherever the owner address is coming from
                    spec: ''
                });
            }
            serviceDestinations[serviceName] = serviceRegistration.destination;

            if (batchedNames.length >= BATCH_SIZE) {
                console.log("pushing" + JSON.stringify(batchedNames));
                console.log("pushing" + JSON.stringify(batchedDestinations));
                await newContract.registerServices(batchedNames, batchedDestinations);
                batchedNames = [];
                batchedDestinations = [];
            }
        }

        // Process any remaining services that didn't fit into a full batch
        if (batchedNames.length > 0) {
            console.log("pushing" + JSON.stringify(batchedNames));
            console.log("pushing" + JSON.stringify(batchedDestinations));
            await newContract.registerServices(batchedNames, batchedDestinations);
        }

        // Verification
        const registeredAddresses = [...uniqueServiceNames].map(name => serviceDestinations[name]);
        const areAllRegistered = await newContract.areServicesRegistered([...uniqueServiceNames], registeredAddresses);

        if (areAllRegistered) {
            console.log("Migration completed successfully!");
        } else {
            console.error("Error: Not all services were registered correctly.");
        }
    }
}

migrate().catch(console.error);
