# Contributing to VoteChain

Thank you for your interest in contributing to VoteChain! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Ways to Contribute
1. **Code Contributions**: Fix bugs, add features, improve performance
2. **Documentation**: Improve docs, write tutorials, translate content
3. **Testing**: Write tests, report bugs, improve test coverage
4. **Design**: UI/UX improvements, graphics, accessibility
5. **Community**: Answer questions, help newcomers, organize events

### Getting Started

#### 1. Fork and Clone
```bash
# Fork the repository on GitHub
git clone https://github.com/YOUR_USERNAME/VoteChain.git
cd VoteChain
git remote add upstream https://github.com/olaleyeolajide81-sketch/VoteChain.git
```

#### 2. Setup Development Environment
```bash
# Install all dependencies
npm run install:all

# Copy environment files
cp contracts/.env.example contracts/.env
cp backend/.env.example backend/.env
cp frontend/.env.example frontend/.env

# Update environment files with your configuration
```

#### 3. Run Tests
```bash
# Run all tests
npm test

# Run specific test suites
npm run test:contracts
npm run test:backend
npm run test:frontend
```

#### 4. Start Development Server
```bash
# Start both backend and frontend
npm run dev

# Or start individually
npm run dev:backend
npm run dev:frontend
```

## 📋 Development Workflow

### 1. Create an Issue
- Search existing issues to avoid duplicates
- Use appropriate issue templates
- Provide detailed description and reproduction steps

### 2. Create a Branch
```bash
# Sync with upstream
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 3. Make Changes
- Follow coding standards
- Write tests for new functionality
- Update documentation
- Keep commits small and focused

### 4. Test Your Changes
```bash
# Run all tests
npm test

# Run linting
npm run lint

# Format code
npm run format
```

### 5. Submit Pull Request
- Push your branch to your fork
- Create pull request with descriptive title
- Fill out pull request template
- Wait for code review

## 📝 Coding Standards

### General Guidelines
- Use TypeScript for frontend and backend
- Follow ESLint and Prettier configurations
- Write meaningful commit messages
- Keep functions small and focused
- Add comments for complex logic

### Smart Contract Standards
- Follow Solidity style guide
- Use OpenZeppelin libraries when possible
- Add comprehensive tests
- Include NatSpec comments
- Consider gas optimization

### Frontend Standards
- Use functional components with React Hooks
- Follow React best practices
- Use Tailwind CSS for styling
- Ensure accessibility (WCAG 2.1)
- Add responsive design

### Backend Standards
- Use Express.js with async/await
- Implement proper error handling
- Add input validation
- Use environment variables for configuration
- Include API documentation

## 🧪 Testing Guidelines

### Test Coverage
- Aim for >80% code coverage
- Test all public functions
- Include edge cases and error conditions
- Use meaningful test descriptions

### Test Types
- **Unit Tests**: Test individual functions/components
- **Integration Tests**: Test component interactions
- **E2E Tests**: Test complete user flows
- **Smart Contract Tests**: Test contract logic and edge cases

### Running Tests
```bash
# All tests
npm test

# Specific test suites
npm run test:contracts
npm run test:backend
npm run test:frontend

# Test coverage
npm run test:coverage
```

## 📚 Documentation

### Types of Documentation
- **API Documentation**: REST API endpoints and smart contracts
- **User Guides**: How to use the platform
- **Developer Guides**: How to contribute and extend
- **Architecture Docs**: System design and decisions

### Documentation Standards
- Use clear, concise language
- Include code examples
- Add diagrams where helpful
- Keep documentation up-to-date
- Use consistent formatting

## 🐛 Bug Reports

### Reporting Bugs
1. Search existing issues
2. Use bug report template
3. Provide detailed information
4. Include reproduction steps
5. Add environment details

### Bug Report Template
```markdown
## Bug Description
Brief description of the bug

## Steps to Reproduce
1. Go to...
2. Click on...
3. See error

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g. Windows 10, macOS 12.0]
- Browser: [e.g. Chrome 96.0]
- Node.js version: [e.g. 16.14.0]
- VoteChain version: [e.g. 1.0.0]

## Additional Context
Any other relevant information
```

## ✨ Feature Requests

### Requesting Features
1. Search existing issues
2. Use feature request template
3. Describe the problem you're solving
4. Explain proposed solution
5. Consider implementation details

### Feature Request Template
```markdown
## Feature Description
Brief description of the feature

## Problem Statement
What problem does this solve?

## Proposed Solution
How should this work?

## Implementation Details
Technical considerations

## Alternatives Considered
Other approaches you thought of

## Additional Context
Any other relevant information
```

## 🔐 Security

### Security Issues
- Do not report security issues publicly
- Email security@votechain.dev
- Include detailed description
- Wait for response before disclosure

### Security Best Practices
- Never commit secrets or keys
- Use environment variables
- Validate all inputs
- Follow OWASP guidelines
- Keep dependencies updated

## 📊 Project Structure

### Directory Overview
```
VoteChain/
├── contracts/          # Smart contracts
├── backend/           # API server
├── frontend/          # Web application
├── mobile/            # Mobile apps
├── docs/              # Documentation
├── infrastructure/    # DevOps configs
└── scripts/           # Utility scripts
```

### Component Organization
- Group related components
- Use consistent naming
- Keep components focused
- Separate concerns
- Reuse when possible

## 🚀 Release Process

### Version Management
- Use semantic versioning
- Update CHANGELOG.md
- Tag releases properly
- Update documentation

### Release Checklist
- [ ] All tests pass
- [ ] Documentation updated
- [ ] Changelog updated
- [ ] Version bumped
- [ ] Tagged release
- [ ] Deployed successfully

## 🏆 Recognition

### Contributor Recognition
- Contributors section in README
- Hall of Fame in documentation
- Special roles for active contributors
- Merit-based rewards

### Contribution Types
- **Code**: Patches, features, fixes
- **Documentation**: Guides, tutorials, translations
- **Design**: UI/UX, graphics, accessibility
- **Community**: Support, moderation, events
- **Testing**: Bug reports, test cases, QA

## 📞 Getting Help

### Resources
- [Documentation](./docs/)
- [Discord Community](https://discord.gg/votechain)
- [GitHub Discussions](https://github.com/olaleyeolajide81-sketch/VoteChain/discussions)
- [Twitter](https://twitter.com/VoteChain_)

### Contact Options
- **Technical Questions**: GitHub Discussions
- **Bug Reports**: GitHub Issues
- **Security Issues**: security@votechain.dev
- **General Inquiries**: info@votechain.dev

## 📜 Code of Conduct

### Our Pledge
- Be inclusive and respectful
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior
- Harassment, discrimination, or hate speech
- Personal attacks or insults
- Spam or off-topic content
- Sharing private information
- Violating licenses or copyright

### Enforcement
- Report violations to maintainers
- Maintainers will investigate and respond
- Consequences may include warnings or bans

## 🎯 Good First Issues

### Getting Started
Look for issues labeled `good first issue`:
- Small, well-defined tasks
- Clear instructions
- Helpful for learning codebase
- Low risk of breaking changes

### Current Good First Issues
- [Add input validation to API endpoints](https://github.com/olaleyeolajide81-sketch/VoteChain/issues/1)
- [Improve error messages in frontend](https://github.com/olaleyeolajide81-sketch/VoteChain/issues/2)
- [Add unit tests for utility functions](https://github.com/olaleyeolajide81-sketch/VoteChain/issues/3)

## 📈 Impact Metrics

### Contribution Metrics
- Number of pull requests merged
- Code quality and test coverage
- Documentation improvements
- Community engagement
- Bug fixes and feature additions

### Recognition System
- Contributor badges
- Leaderboard rankings
- Annual awards
- Special roles and permissions

---

Thank you for contributing to VoteChain! Your help makes decentralized voting accessible to everyone. 🚀
