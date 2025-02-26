import {
  readdirSync,
  statSync,
  readFileSync,
  existsSync,
  mkdirSync,
  writeFileSync,
} from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { format } from "prettier";

const __dirname = dirname(fileURLToPath(import.meta.url));

const generatedContractComment = `
/**
 * This file is autogenerated by Scaffold-ETH.
 * You should not edit it manually or your changes might be overwritten.
 */`;

function getDirectories(path) {
  if (!existsSync(path)) {
    return [];
  }

  return readdirSync(path).filter(function (file) {
    return statSync(join(path, file)).isDirectory();
  });
}

function getFiles(path) {
  return readdirSync(path).filter(function (file) {
    return statSync(join(path, file)).isFile();
  });
}

function parseTransactionRun(filePath) {
  try {
    const content = readFileSync(filePath, "utf8");
    const broadcastData = JSON.parse(content);
    return broadcastData.transactions || [];
  } catch (error) {
    console.warn(`Warning: Could not parse ${filePath}:`, error.message);
    return [];
  }
}

function getDeploymentHistory(broadcastPath) {
  const files = getFiles(broadcastPath);
  const deploymentHistory = new Map();

  // Sort files to process them in chronological order
  const runFiles = files
    .filter(
      (file) =>
        file.startsWith("run-") &&
        file.endsWith(".json") &&
        !file.includes("run-latest")
    )
    .sort((a, b) => {
      // Extract run numbers and compare them
      const runA = parseInt(a.match(/run-(\d+)/)?.[1] || "0");
      const runB = parseInt(b.match(/run-(\d+)/)?.[1] || "0");
      return runA - runB;
    });

  for (const file of runFiles) {
    const transactions = parseTransactionRun(join(broadcastPath, file));

    for (const tx of transactions) {
      if (tx.transactionType === "CREATE") {
        // Store or update contract deployment info
        deploymentHistory.set(tx.contractAddress, {
          contractName: tx.contractName,
          address: tx.contractAddress,
          deploymentFile: file,
          transaction: tx,
        });
      }
    }
  }

  return Array.from(deploymentHistory.values());
}

function getArtifactOfContract(contractName) {
  const current_path_to_artifacts = join(
    __dirname,
    "..",
    `out/${contractName}.sol`
  );

  if (!existsSync(current_path_to_artifacts)) return null;

  const artifactJson = JSON.parse(
    readFileSync(`${current_path_to_artifacts}/${contractName}.json`)
  );

  return artifactJson;
}

function getInheritedFromContracts(artifact) {
  let inheritedFromContracts = [];
  if (artifact?.ast) {
    for (const astNode of artifact.ast.nodes) {
      if (astNode.nodeType == "ContractDefinition") {
        if (astNode.baseContracts.length > 0) {
          inheritedFromContracts = astNode.baseContracts.map(
            ({ baseName }) => baseName.name
          );
        }
      }
    }
  }
  return inheritedFromContracts;
}

function getInheritedFunctions(mainArtifact) {
  const inheritedFromContracts = getInheritedFromContracts(mainArtifact);
  const inheritedFunctions = {};
  for (const inheritanceContractName of inheritedFromContracts) {
    const artifact = getArtifactOfContract(inheritanceContractName);
    if (artifact) {
      const {
        abi,
        ast: { absolutePath },
      } = artifact;
      for (const abiEntry of abi) {
        if (abiEntry.type == "function") {
          inheritedFunctions[abiEntry.name] = absolutePath;
        }
      }
    }
  }
  return inheritedFunctions;
}

// Function to find the implementation contract for a proxy
function findProxyImplementation(deploymentHistory, chainId) {
  // Look for the implementation contract in the deployment transactions
  for (const deployment of deploymentHistory) {
    if (deployment.contractName === "ERC1967Proxy") {
      // Try to find the implementation address from the constructor arguments
      const tx = deployment.transaction;
      if (tx && tx.arguments && tx.arguments.length >= 1) {
        // The first argument to ERC1967Proxy constructor is the implementation address
        const implementationAddress = tx.arguments[0];
        
        // Find the contract at this address
        const implementationDeployment = deploymentHistory.find(
          (d) => d.address.toLowerCase() === implementationAddress.toLowerCase()
        );
        
        if (implementationDeployment) {
          return {
            proxyAddress: deployment.address,
            implementationName: implementationDeployment.contractName,
            implementationAddress: implementationDeployment.address
          };
        }
      }
    }
  }
  
  return null;
}

function processAllDeployments(broadcastPath) {
  const scriptFolders = getDirectories(broadcastPath);
  const allDeployments = new Map();
  const proxyImplementations = new Map(); // Map to store proxy -> implementation relationships

  scriptFolders.forEach((scriptFolder) => {
    const scriptPath = join(broadcastPath, scriptFolder);
    const chainFolders = getDirectories(scriptPath);

    chainFolders.forEach((chainId) => {
      const chainPath = join(scriptPath, chainId);
      const deploymentHistory = getDeploymentHistory(chainPath);

      // Find proxy implementations first
      const proxyInfo = findProxyImplementation(deploymentHistory, chainId);
      if (proxyInfo) {
        proxyImplementations.set(`${chainId}-ERC1967Proxy`, proxyInfo.implementationName);
        console.log(`Found proxy implementation for chain ${chainId}: ERC1967Proxy -> ${proxyInfo.implementationName}`);
      }

      deploymentHistory.forEach((deployment) => {
        const timestamp = parseInt(
          deployment.deploymentFile.match(/run-(\d+)/)?.[1] || "0"
        );
        const key = `${chainId}-${deployment.contractName}`;

        // Only update if this deployment is newer
        if (
          !allDeployments.has(key) ||
          timestamp > allDeployments.get(key).timestamp
        ) {
          allDeployments.set(key, {
            ...deployment,
            timestamp,
            chainId,
            deploymentScript: scriptFolder,
          });
        }
      });
    });
  });

  const allContracts = {};

  allDeployments.forEach((deployment) => {
    const { chainId, contractName } = deployment;
    const artifact = getArtifactOfContract(contractName);

    if (artifact) {
      if (!allContracts[chainId]) {
        allContracts[chainId] = {};
      }

      // Check if this is a proxy contract
      const isProxy = contractName === "ERC1967Proxy";
      const implementationName = proxyImplementations.get(`${chainId}-ERC1967Proxy`);
      
      if (isProxy && implementationName) {
        // Get the implementation artifact
        const implementationArtifact = getArtifactOfContract(implementationName);
        
        if (implementationArtifact) {
          // Use the implementation's ABI for the proxy
          allContracts[chainId][contractName] = {
            address: deployment.address,
            abi: implementationArtifact.abi, // Use implementation ABI
            inheritedFunctions: getInheritedFunctions(implementationArtifact),
            deploymentFile: deployment.deploymentFile,
            deploymentScript: deployment.deploymentScript,
            isProxy: true,
            implementationName: implementationName,
          };
          console.log(`Using ${implementationName} ABI for ERC1967Proxy on chain ${chainId}`);
        } else {
          // Fallback to proxy ABI if implementation artifact not found
          allContracts[chainId][contractName] = {
            address: deployment.address,
            abi: artifact.abi,
            inheritedFunctions: getInheritedFunctions(artifact),
            deploymentFile: deployment.deploymentFile,
            deploymentScript: deployment.deploymentScript,
          };
        }
      } else {
        // Regular contract (not a proxy)
        allContracts[chainId][contractName] = {
          address: deployment.address,
          abi: artifact.abi,
          inheritedFunctions: getInheritedFunctions(artifact),
          deploymentFile: deployment.deploymentFile,
          deploymentScript: deployment.deploymentScript,
        };
      }
    }
  });

  return allContracts;
}

function main() {
  const current_path_to_broadcast = join(__dirname, "..", "broadcast");
  const current_path_to_deployments = join(__dirname, "..", "deployments");

  const Deploymentchains = getFiles(current_path_to_deployments);
  const deployments = {};

  // Load existing deployments from deployments directory
  Deploymentchains.forEach((chain) => {
    if (!chain.endsWith(".json")) return;
    chain = chain.slice(0, -5);
    var deploymentObject = JSON.parse(
      readFileSync(`${current_path_to_deployments}/${chain}.json`)
    );
    deployments[chain] = deploymentObject;
  });

  // Process all deployments from all script folders
  const allGeneratedContracts = processAllDeployments(
    current_path_to_broadcast
  );

  // Update contract keys based on deployments if they exist
  Object.entries(allGeneratedContracts).forEach(([chainId, contracts]) => {
    Object.entries(contracts).forEach(([contractName, contractData]) => {
      const deployedName = deployments[chainId]?.[contractData.address];
      if (deployedName) {
        // If we have a deployment name, use it instead of the contract name
        allGeneratedContracts[chainId][deployedName] = contractData;
        delete allGeneratedContracts[chainId][contractName];
      }
    });
  });

  const NEXTJS_TARGET_DIR = "../nextjs/contracts/";

  // Ensure target directories exist
  if (!existsSync(NEXTJS_TARGET_DIR)) {
    mkdirSync(NEXTJS_TARGET_DIR, { recursive: true });
  }

  // Generate the deployedContracts content
  const fileContent = Object.entries(allGeneratedContracts).reduce(
    (content, [chainId, chainConfig]) => {
      return `${content}${parseInt(chainId).toFixed(0)}:${JSON.stringify(
        chainConfig,
        null,
        2
      )},`;
    },
    ""
  );

  // Write the files
  const fileTemplate = (importPath) => `
    ${generatedContractComment}
    import { GenericContractsDeclaration } from "${importPath}";

    const deployedContracts = {${fileContent}} as const;

    export default deployedContracts satisfies GenericContractsDeclaration;
  `;

  writeFileSync(
    `${NEXTJS_TARGET_DIR}deployedContracts.ts`,
    format(fileTemplate("~~/utils/scaffold-eth/contract"), {
      parser: "typescript",
    })
  );

  console.log(
    `📝 Updated TypeScript contract definition file on ${NEXTJS_TARGET_DIR}deployedContracts.ts`
  );
}

try {
  main();
} catch (error) {
  console.error("Error:", error);
  process.exitCode = 1;
}
