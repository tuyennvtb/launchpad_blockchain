import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";

require('dotenv').config();

const { API_URL, PRIVATE_KEY } = process.env;

//console.log(PRIVATE_KEY)

const config: HardhatUserConfig = {
  solidity: {
   version: "0.8.17",
   settings: {
      optimizer: {
        enabled: true,
        runs: 500,
      },
      "viaIR": true,
    }
  },
  defaultNetwork: "goerli",
   networks: {
      hardhat: {},
      goerli: {
         //url: "https://rpc.ankr.com/eth_goerli",
         url: "https://goerli.blockpi.network/v1/rpc/public",
         chainId: 0x5,
         accounts: [`0x${PRIVATE_KEY}`],
         gas: "auto",
         gasPrice: "auto"
      },
      base20: {
         //url: "https://rpc.ankr.com/eth_goerli",
         url: "https://goerli.base.org",
         chainId: 84531,
         accounts: [`0x${PRIVATE_KEY}`],
         gas: "auto",
         gasPrice: "auto"
      },
      base20mainnet: {
         //url: "https://rpc.ankr.com/eth_goerli",
         url: "https://mainnet.base.org",
         chainId: 8453,
         accounts: [`0x${PRIVATE_KEY}`],
         gas: "auto",
         gasPrice: "auto"
      },
      testnet: {
         url: "https://data-seed-prebsc-1-s1.binance.org:8545",
         chainId: 97,
          gasPrice: 20000000000,
          accounts: [`${PRIVATE_KEY}`],
      },
      bnbmainnet: {
         url: "https://bsc-dataseed.binance.org/",
         chainId: 56,
          gasPrice: 20000000000,
          accounts: [`${PRIVATE_KEY}`],
      },
      arbmainnet: {
         url: "https://arb1.arbitrum.io/rpc",
         chainId: 42161,
         accounts: [`0x${PRIVATE_KEY}`],
         gas: "auto",
         gasPrice: "auto"
      },
      ethmainnet: {
         url: "https://ethereum.publicnode.com",
         chainId: 1,
         accounts: [`0x${PRIVATE_KEY}`],
         gas: "auto",
         gasPrice: "auto"
      }
      
   },
   etherscan: {
      //apiKey: "M82FC55BRH7PSF2AR1DIT1XTUS49QFKHC8", // Your Etherscan API key
      //apiKey: "H8MGW5TQYUFXEZI7FWMMEADSK9QG63HT58", //bsc scan
      //apiKey: "YMFMXCQPZXT7PKNJ7WWDGQ7UYWAWMKGHAX", //etherscan
      apiKey: {
         "goerli": "YMFMXCQPZXT7PKNJ7WWDGQ7UYWAWMKGHAX",
         "base20": "PLACEHOLDER_STRING",
         "base20mainnet": "ZRPA4FG5XDGANUFPKJ8G781RFS4INNRDEB"
        },
      customChains: [
      {
         network: "base20",
         chainId: 84531,
         urls: {
         apiURL: "https://api-goerli.basescan.org/api",
         browserURL: "https://goerli.basescan.org"
         }
      },
      {
         network: "base20mainnet",
         chainId: 8453,
         urls: {
         apiURL: "https://api.basescan.org/api",
         browserURL: "https://basescan.org"
         }
      }
      ]
    },
};

export default config;
