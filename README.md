# Simple Raffle - Sui Move Smart Contract

A decentralized raffle/lottery smart contract built on the Sui blockchain using Move programming language.

## 🎯 Features

- **Fair & Transparent**: Uses Sui's secure randomness for winner selection
- **Duplicate Prevention**: Users can only join each raffle once
- **Event Emissions**: Real-time updates for frontend integration
- **Upgradable**: Contract can be upgraded by the deployer
- **Minimum Participants**: Ensures fairness with at least 2 participants
- **Automatic Payouts**: Winner receives the full prize pool instantly

## 📋 Contract Overview

### Core Functions

- `create_raffle()` - Create a new raffle (anyone can create)
- `join()` - Join a raffle by paying 1 SUI entry fee
- `pick_winner()` - Randomly select winner and transfer prize (owner only)

### View Functions

- `get_entrants()` - Get list of all participants
- `get_entrant_count()` - Get number of participants
- `get_pool_value()` - Get current prize pool amount
- `is_open()` - Check if raffle is still accepting entries
- `get_owner()` - Get raffle creator's address

### Events

- `RaffleCreated` - Emitted when a new raffle is created
- `PlayerJoined` - Emitted when someone joins a raffle
- `WinnerPicked` - Emitted when winner is selected

## 🛠️ Installation & Setup

### Prerequisites

- [Sui CLI](https://docs.sui.io/guides/developer/getting-started/sui-install) installed
- Sui wallet with SUI tokens for gas fees

### Clone & Build

```bash
git clone https://github.com/willwees/simple-raffle-sui.git
cd simple-raffle-sui

# Build the contract
sui move build

# Run tests
sui move test
```

## 🚀 Deployment

### Deploy to Testnet

```bash
# Deploy the contract
sui client publish --gas-budget 50000000

# Save your Package ID from the output for later use
```

### Deploy to Mainnet

```bash
# Switch to mainnet (be careful!)
sui client switch --env mainnet

# Deploy with higher gas budget
sui client publish --gas-budget 100000000
```

## 📖 Usage

### 1. Create a Raffle

```bash
sui client call \
    --package <YOUR_PACKAGE_ID> \
    --module simple_raffle \
    --function create_raffle \
    --gas-budget 10000000
```

### 2. Join a Raffle

```bash
sui client call \
  --package <YOUR_PACKAGE_ID> \
  --module simple_raffle \
  --function join \
  --args <RAFFLE_OBJECT_ID> <YOUR_SUI_COIN_ID> \
  --gas-budget 10000000
```

**Requirements:**
- Your SUI coin must have at least 1 SUI (1,000,000,000 MIST)
- Raffle must be open
- You can only join each raffle once

### 3. Pick Winner (Raffle Owner Only)

```bash
sui client call \
  --package <YOUR_PACKAGE_ID> \
  --module simple_raffle \
  --function pick_winner \
  --args <RAFFLE_OBJECT_ID> 0x8 \
  --gas-budget 15000000
```

**Note:** `0x8` is the global Random object ID on Sui.

### 4. Check Raffle State

```bash
# View raffle details
sui client object <RAFFLE_OBJECT_ID>
```

## 🔍 Example Workflow

1. **Alice creates a raffle** - Gets raffle object ID
2. **Bob joins** - Pays 1 SUI, becomes participant #1
3. **Charlie joins** - Pays 1 SUI, becomes participant #2
4. **Alice picks winner** - Random selection between Bob and Charlie
5. **Winner gets 2 SUI** - Full prize pool transferred instantly

## 🧪 Testing

The contract includes comprehensive tests covering:

- ✅ Raffle creation
- ✅ Joining raffles (success cases)
- ✅ Error conditions (insufficient payment, duplicates, etc.)
- ✅ Winner selection with proper randomness
- ✅ Event emissions
- ✅ Edge cases and security scenarios

Run tests:
```bash
sui move test
```

## 🔒 Security Features

- **Secure Randomness**: Uses Sui's `sui::random` module
- **Access Control**: Only raffle owner can pick winner
- **Duplicate Prevention**: Users can't join the same raffle twice
- **Minimum Participants**: Prevents unfair single-player raffles
- **Automatic Transfers**: No manual intervention needed for payouts

## 📊 Contract Constants

```move
const ENTRY_FEE: u64 = 1_000_000_000; // 1 SUI entry fee
const MIN_PARTICIPANTS: u64 = 2;       // Minimum players to pick winner
```

## 🎨 Frontend Integration

### Event Listening

Your frontend can listen for these events:

```typescript
// Example event structure
interface PlayerJoined {
  raffle_id: string;
  player: string;
  total_entrants: number;
}

interface WinnerPicked {
  raffle_id: string;
  winner: string;
  prize_amount: number;
}
```

### Reading Contract State

Use the view functions to display raffle information:
- Current participants count
- Prize pool amount  
- Raffle status (open/closed)
- List of participants

## 🔄 Upgradability

The contract is upgradable using Sui's upgrade system:

```bash
# Upgrade the contract (requires UpgradeCap)
sui client upgrade \
  --package-id <PACKAGE_ID> \
  --upgrade-capability <UPGRADE_CAP_ID> \
  --gas-budget 50000000
```

## ⚠️ Important Notes

- **Entry Fee**: Fixed at 1 SUI per entry
- **Gas Costs**: Raffle owner pays gas when picking winner
- **Randomness**: Uses Sui's random module (secure for most use cases)
- **Winner Selection**: Completely random and unpredictable
- **Prize Distribution**: Winner gets 100% of the prize pool

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Sui Documentation](https://docs.sui.io/)
- [Move Language Book](https://move-language.github.io/move/)
- [Sui Explorer](https://suiscan.xyz/)
- [Sui Discord](https://discord.gg/sui)

## 📞 Support

If you have questions or need help:
- Open an issue on GitHub
- Join the Sui Discord community
- Check the Sui documentation

---

**Happy Raffling! 🎲**
