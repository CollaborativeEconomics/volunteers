# Volunteer Token Distribution System

A smart contract system for distributing tokens to whitelisted addresses holding specific NFTs.

## Features
- Whitelist management for eligible recipients
- ERC20 token distribution based on NFT holdings
- Configurable base fee per NFT unit
- Owner-only administration functions
- Clear error messages for failed distributions

## Requirements
- Foundry (https://getfoundry.sh)

## Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/volunteer-token-distribution.git
   cd volunteer-token-distribution
   ```

2. Install dependencies:
   ```bash
     forge install
   ```

## Testing
Run all tests:

```shell
$ forge test
```

### Build

```shell
$ forge build
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Deploy

There are two ways to deploy the volunteer contract:

1. Deploy the factory contract and then deploy the volunteer contract using the factory contract.

```shell
$ forge script script/FactoryDeployer.s.sol:FactoryDeployer --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

2. Deploy the volunteer contract directly.

```shell
$ forge script script/VolunteerDeployer.s.sol:VolunteerDeployer --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

To deploy the volunteer contract through any of the above methods, you need to set the following environment variables:

- `PRIVATE_KEY`: The private key of the deployer.
- `TOKEN_ADDRESS`: The address of the ERC20 token to be distributed.
- `OWNER_ADDRESS`: The address of the owner of the volunteer contract.
- `NFT_CONTRACT_ADDRESS`: The address of the ERC721 contract used for NFT ownership checks.
- `BASE_FEE`: The base fee per NFT unit.

You also need to deploy the ERC721 contract found in `src/VolunteerNFT.sol` before deploying the volunteer contract.