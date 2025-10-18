# SimpleVoting — Solidity Voting Smart Contract

A compact Solidity voting contract suitable for EVM-compatible chains (including Flow EVM testnet). Owner can create/remove proposals, open/close voting, and any address may vote once per proposal while voting is open.

---

## Files

- `contracts/SimpleVoting.sol` — main contract (Solidity ^0.8.19)

---

## Features

- Owner-managed proposals
- Open/close voting phases
- One vote per address per proposal
- Events for off-chain indexing
- Simple on-chain tally (`winningProposal()`)

---

## Quick usage / testflow

You can deploy & interact using **Remix** (fastest) or **Hardhat** (recommended for scripting).

### Option A — Remix (fast)

1. Open https://remix.ethereum.org
2. Create a new file `SimpleVoting.sol` and paste the contract code.
3. Set compiler to `0.8.19` (or compatible ^0.8.x).
4. To test on Flow EVM testnet:
   - Add Flow EVM testnet to MetaMask as a custom RPC network (use Flow docs for the RPC URL).
   - In Remix, under "Deploy & Run Transactions":
     - Environment: `Injected Provider - MetaMask`
     - Ensure MetaMask is connected to the Flow EVM testnet account with test ETH.
   - Deploy the contract. The deploying address becomes `owner`.
5. Use contract UI in Remix:
   - `addProposal("Proposal 1")` — works only while voting closed (initially closed).
   - `openVoting()` — owner opens voting.
   - Any address can call `vote(proposalId)` while voting is open.
   - `closeVoting()` — owner closes voting.
   - `winningProposal()` to get current winner.

> NOTE: Flow EVM testnet RPC endpoint is specific to Flow; check Flow docs for the correct URL and chain ID. Replace any placeholder RPC with the one they publish.

---

### Option B — Hardhat (recommended for scripted deployment)

1. Create project:
```bash
mkdir simple-voting
cd simple-voting
npm init -y
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers dotenv
npx hardhat
# choose "Create a basic sample project"
