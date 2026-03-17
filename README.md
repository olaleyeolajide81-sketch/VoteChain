# VoteChain: Decentralized Voting & Governance Platform

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stellar](https://img.shields.io/badge/Stellar-Blockchain-blue)](https://stellar.org/)
[![Solidity](https://img.shields.io/badge/Solidity-Smart_Contracts-black)](https://soliditylang.org/)

VoteChain is a Web3 decentralized voting and governance platform built on the Stellar blockchain, enabling secure, transparent, and tamper-proof voting mechanisms for organizations, DAOs, and communities.

## 🚀 Features

### Core Voting System
- **Secure Voting**: Cryptographically secure voting using Stellar signatures
- **Multiple Voting Types**: Single choice, multiple choice, weighted voting
- **Vote Privacy**: Optional anonymous voting with zero-knowledge proofs
- **Real-time Results**: Live vote counting and result visualization
- **On-chain Verification**: All votes recorded on Stellar blockchain

### Governance Mechanisms
- **Token-based Governance**: Native VCT token for voting power
- **Delegation System**: Vote delegation to trusted representatives
- **Staking Rewards**: Earn rewards for participating in governance
- **Proposal Management**: Complete proposal lifecycle management
- **Quorum Requirements**: Configurable participation thresholds

### Security & Transparency
- **Auditable Trail**: Complete audit trail of all voting activities
- **Smart Contract Audits**: Professional security audits
- **Emergency Controls**: Circuit breakers for emergency situations
- **Anti-Sybil Measures**: Identity verification and attack prevention

### User Experience
- **Multi-wallet Support**: Integration with popular Stellar wallets
- **Mobile Applications**: Native iOS and Android apps
- **Multi-language Support**: Internationalization for global adoption
- **Accessibility Features**: WCAG compliant interface design

## 🏗️ Architecture

### Smart Contracts Layer
- **VotingContract**: Main voting logic and vote counting
- **GovernanceContract**: Delegation, staking, and governance parameters
- **TokenContract**: ERC20 governance token with voting power
- **ProposalContract**: Proposal creation and lifecycle management
- **VoteStorageContract**: Secure vote storage with privacy features

### Backend Services
- **Node.js/Express**: RESTful API services
- **PostgreSQL**: Primary database for application data
- **Redis**: Caching and session management
- **IPFS**: Decentralized storage for proposal metadata

### Frontend Application
- **React.js**: Modern JavaScript framework for UI
- **TypeScript**: Type-safe development
- **Tailwind CSS**: Utility-first CSS framework
- **Stellar SDK**: Blockchain interaction

## 📦 Installation

### Prerequisites
- Node.js >= 16.0.0
- npm >= 8.0.0
- Git
- Stellar CLI (for contract deployment)

### Clone Repository
```bash
git clone https://github.com/olaleyeolajide81-sketch/VoteChain.git
cd VoteChain
```

### Install Dependencies

#### Smart Contracts
```bash
cd contracts
npm install
```

#### Backend
```bash
cd backend
npm install
```

#### Frontend
```bash
cd frontend
npm install
```

### Environment Setup

Create `.env` files in each directory:

#### contracts/.env
```
STELLAR_NETWORK=testnet
PRIVATE_KEY=your_private_key
NETWORK_PASSPHRASE=Test SDF Network ; September 2015
```

#### backend/.env
```
NODE_ENV=development
PORT=3001
DATABASE_URL=postgresql://username:password@localhost:5432/votechain
REDIS_URL=redis://localhost:6379
STELLAR_NETWORK=testnet
JWT_SECRET=your_jwt_secret
IPFS_GATEWAY=https://ipfs.io/ipfs/
```

#### frontend/.env
```
REACT_APP_API_URL=http://localhost:3001
REACT_APP_STELLAR_NETWORK=testnet
REACT_APP_CONTRACT_ADDRESS=your_contract_address
```

## 🚀 Quick Start

### 1. Deploy Smart Contracts
```bash
cd contracts
npm run deploy:testnet
```

### 2. Setup Database
```bash
cd backend
npm run migrate
npm run seed
```

### 3. Start Backend Services
```bash
cd backend
npm run dev
```

### 4. Start Frontend Application
```bash
cd frontend
npm start
```

### 5. Access Application
Open http://localhost:3000 in your browser

## 📖 Documentation

### [API Documentation](./docs/api/REST_API.md)
### [Smart Contract Documentation](./docs/contracts/README.md)
### [User Guide](./docs/guides/User_Guide.md)
### [Developer Guide](./docs/guides/Developer_Guide.md)
### [Deployment Guide](./docs/guides/Deployment_Guide.md)

## 🧪 Testing

### Smart Contract Tests
```bash
cd contracts
npm run test
npm run test:coverage
```

### Backend Tests
```bash
cd backend
npm run test
npm run test:integration
npm run test:e2e
```

### Frontend Tests
```bash
cd frontend
npm run test
npm run test:coverage
```

## 📊 Smart Contract Addresses

### Testnet
- **Token Contract**: `0x...`
- **Voting Contract**: `0x...`
- **Governance Contract**: `0x...`
- **Proposal Contract**: `0x...`
- **VoteStorage Contract**: `0x...`

### Mainnet
- **Token Contract**: `0x...`
- **Voting Contract**: `0x...`
- **Governance Contract**: `0x...`
- **Proposal Contract**: `0x...`
- **VoteStorage Contract**: `0x...`

## 🔧 Configuration

### Stellar Network Configuration
The platform supports both Stellar Testnet and Mainnet. Configure the network in your environment files:

```env
STELLAR_NETWORK=testnet  # or mainnet
NETWORK_PASSPHRASE=Test SDF Network ; September 2015  # or Public Global Stellar Network ; September 2015
```

### Governance Parameters
Key governance parameters can be configured through the GovernanceContract:

- **MIN_PROPOSAL_THRESHOLD**: Minimum tokens required to create a proposal
- **VOTING_PERIOD**: Default voting period duration
- **QUORUM_REQUIRED**: Default quorum percentage
- **EXECUTION_DELAY**: Delay before proposal execution

## 🤝 Contributing

We welcome contributions from the community! Please read our [Contributing Guidelines](./CONTRIBUTING.md) before submitting pull requests.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

### Code Style
- Use ESLint and Prettier for code formatting
- Follow Solidity style guide for smart contracts
- Write comprehensive tests for all new features
- Update documentation for any API changes

## 🐛 Bug Reports

If you find a bug, please create an issue on GitHub with:
- Detailed description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Environment details

## 🔒 Security

For security concerns, please email security@votechain.dev or create a private issue.

### Security Features
- Smart contract audits by reputable firms
- Bug bounty program
- Regular security updates
- Multi-signature controls for critical operations

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

## 🙏 Acknowledgments

- [Stellar Development Foundation](https://stellar.org/) for the blockchain infrastructure
- [OpenZeppelin](https://openzeppelin.com/) for secure smart contract libraries
- The Web3 community for inspiration and feedback

## 📞 Contact

- **Website**: https://votechain.dev
- **Twitter**: [@VoteChain_](https://twitter.com/VoteChain_)
- **Discord**: [Join our Discord](https://discord.gg/votechain)
- **Email**: info@votechain.dev

## 🗺️ Roadmap

### Phase 1: Foundation (Q1 2026)
- [x] Smart contract development
- [x] Basic voting functionality
- [x] Web application MVP
- [ ] Security audits

### Phase 2: Expansion (Q2 2026)
- [ ] Mobile application release
- [ ] Advanced governance features
- [ ] Multi-organization support
- [ ] API documentation

### Phase 3: Ecosystem (Q3 2026)
- [ ] Third-party integrations
- [ ] DAO tooling
- [ ] Advanced analytics
- [ ] Governance marketplace

### Phase 4: Scale (Q4 2026)
- [ ] Cross-chain compatibility
- [ ] Enterprise solutions
- [ ] Regulatory compliance
- [ ] Global expansion

---

**Built with ❤️ for the Web3 community**
