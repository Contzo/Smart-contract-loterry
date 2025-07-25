# 🎰 Smart Contract Lottery

This repository is a personal implementation of the [Cyfrin Foundry Smart Contract Lottery Course](https://github.com/Cyfrin/foundry-smart-contract-lottery-cu), using [Foundry](https://book.getfoundry.sh/) to build, test, and deploy a decentralized lottery smart contract.

## 🧱 What It Does

The lottery smart contract allows users to:
- Enter the lottery by paying a set entrance fee
- Automatically pick a random winner using Chainlink VRF
- Run on a scheduled interval using Chainlink Keepers (Automation)

It showcases integration with:
- ✅ Chainlink VRF v2.5 (for randomness)
- ✅ Chainlink Keepers / Automation
- ✅ Foundry framework for development and testing

---

## 🛠 Tech Stack

- [Solidity](https://soliditylang.org/)
- [Foundry](https://book.getfoundry.sh/)
- [Chainlink VRF & Automation](https://chain.link/)
- [Anvil](https://book.getfoundry.sh/reference/anvil/) (for local testing)

---

## 🚀 Getting Started

### Prerequisites
- [Foundry installed](https://book.getfoundry.sh/getting-started/installation)
- Node.js & npm (for frontend or scripts if extended)
- `.env` file with the following:
  ```bash
  PRIVATE_KEY=your_wallet_private_key
  ETHERSCAN_API_KEY=your_etherscan_key
  RPC_URL=your_rpc_endpoint
