# Abstraction Module

ERC-4337 Account Abstraction primitives and Barz-specific adapters for unstoppable-wallet-ios.

## Scope

- `Types/` — UserOperation (EntryPoint v0.6 format), PackedUserOperation (userOpHash calculation), supporting structs, WebAuthnSignature.
- `Errors/` — module-wide error types.
- `Contracts/` *(added in Part 2)* — ABI wrappers for EntryPoint v0.6, BarzFactory, AccountFacet, Secp256r1VerificationFacet. Static ABI may use `EvmKit.ContractMethod`; dynamic ABI uses a small local helper encoder inside the module.
- `Contracts/BarzAddressResolver` *(Part 6)* — local `CREATE2` resolver with optional network-backed verification via `BarzFactory.getAddress(...)`.
- `Adapters/` *(Phase 4)* — versioned `ISmartContractAdapter` protocol + `BarzV1Adapter`.
- `Bundler/` *(Phase 4)* — JSON-RPC client.
- `Paymaster/` *(Phase 4)* — ERC-7677 Pimlico service.
- `UserOperation/` *(Phase 5)* — Builder / Hasher / Signer / Sender / Poller.
- `Signers/` *(Phase 5)* — `IEvmSigner` + `PasskeySigner`.
- `Executors/` *(Phase 5)* — `IEvmExecutor` + `SmartAccountExecutor`.

## Design rules

- **No `Core.shared`** inside the module. All dependencies are injected via init.
- **No `web3swift` imports** — ABI encoding relies on `EvmKit` primitives plus a small local helper encoder for dynamic ABI cases.
- **Protocol-first** — cross-module boundaries go through protocols; concrete types live in single files.
- **Versioned adapters** — contract-specific code is isolated in `Adapters/`; the executor does not know about Barz directly.

## v1 targets

- Contract: Barz (Apache 2.0) on EntryPoint v0.6
- Networks: Ethereum mainnet + BSC
- Tokens: USDT, USDC (ETH), USDT (BSC) — via Pimlico ERC-20 paymaster
- Bundler: Pimlico only
