# VotingSystem Smart Contract

---

## Overview

**VotingSystem** is a Solidity-based decentralized voting smart contract designed to provide a secure, transparent, and tamper-resistant way to conduct elections on the Ethereum blockchain. This project demonstrates how to deploy, interact with, and test a voting system using **Foundry**, a powerful Ethereum development toolkit.

The system supports key features like:

- Candidate management (adding and listing candidates)
- Voter registration
- Vote casting with validation
- Controlled voting period (start and end)
- Fetching voting results and winners
- Resetting elections for reuse

This project is an excellent foundation for learning smart contract development, state management, and Foundry scripting for deployment and interaction.

---

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Setup & Installation](#setup--installation)
- [Deployment](#deployment)
- [Running Tests](#running-tests)
- [Interaction Scripts](#interaction-scripts)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- **Candidate Management:**  
  Add candidates before or during elections (depending on contract logic).

- **Voter Registration:**  
  Only registered voters can participate, ensuring election integrity.

- **Voting:**  
  Registered voters can cast their votes securely.

- **Voting Period Control:**  
  Owner can start and end voting to control election phases.

- **Result Calculation:**  
  Contract calculates winners and provides detailed results.

- **Reset Election:**  
  Reset state to run new elections without redeploying.

---

## Tech Stack

- **Solidity ^0.8.19** — Smart contract language  
- **Foundry** — Development, testing, and scripting framework  
- **forge-std** — Foundry standard library (console logs, script utilities)  
- **VSCode** or any Solidity-compatible IDE for development  

---

## Setup & Installation

1. **Install Foundry**

   Follow instructions at [Foundry Installation](https://foundry.paradigm.xyz/) to install Foundry (`forge` and `cast`).

2. **Clone the repo**

   ```bash
   git clone https://github.com/yourusername/VotingSystem.git
   cd VotingSystem

3. **Install dependencies**

Foundry manages dependencies automatically; ensure forge commands work.

4. **Set environment variables**

Create a .env file (or export in your shell) with:
```env 
CANDIDATE1=Alice
CANDIDATE2=Bob
CANDIDATE3=Charlie
VOTING_DURATION=86400
VOTING_CONTRACT_ADDRESS=your_deployed_contract_address
```

## Deployment 

**Use the provided deployment script DeployVotingsystem.s.sol:**

```bash
forge script script/DeployVotingsystem.s.sol:DeployVotingsystem --broadcast --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY>
```

**This script:**

- Reads candidate names and voting duration from environment variables

- Deploys the VotingSystem contract with the provided data

- Logs the deployed contract address

## Running Tests

**Tests are written using Foundry’s Test library and cover:**

- Contract deployment

- Correct initialization of candidates and voting duration

- Basic interaction flows

**Run all tests with:**

```bash
forge test
```

## Interaction Scripts

**The Interactions.s.sol script allows you to interact with your deployed VotingSystem contract, including:**

- Registering voters

- Adding candidates

- Starting and ending voting

- Casting votes

- Retrieving candidates, results, and registered voters

**Before running, set VOTING_CONTRACT_ADDRESS in your environment to your deployed contract's address.**

**Example to run an interaction script (e.g., voting):**

```bash
forge script script/Interactions.s.sol:Interactions --broadcast --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> -vvvv
```

## Project Structure
```bash
VotingSystem/
├── src/
│   └── VotingSystem.sol         # Core smart contract
├── script/
│   ├── DeployVotingsystem.s.sol # Deployment script
│   └── Interactions.s.sol        # Interaction script
├── test/
│   └── DeployVotingsystem.t.sol  # Test script for deployment
├── .env                         # Environment variables (not committed)
├── foundry.toml                 # Foundry config
└── README.md                    # This file
```
## Contributing
Contributions are welcome! Feel free to open issues or pull requests for bug fixes, improvements, or feature suggestions.

**When contributing:**

- Follow Solidity best practices

- Write or update tests for any new features

- Keep code clean and well-documented

  ## License
**This project is licensed under the MIT License — see the LICENSE file for details.**

##Final Notes
**This project aims to provide a clear example of building a secure and functional voting dApp backend using Solidity and Foundry. It’s great for learning, demoing, or building upon for more complex election or governance systems.**






