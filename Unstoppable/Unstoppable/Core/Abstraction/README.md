# Abstraction Module

ERC-4337 Account Abstraction primitives and Barz-specific adapters for unstoppable-wallet-ios.

## Layout

- `Config/` — static registries (e.g. stablecoin lists).
- `Contracts/` — ABI wrappers: `EntryPointV06`, `BarzFactory`, `AccountFacet`, `BarzAddressResolver` (CREATE2), `ChainAddresses`, `AbiEncoder`. Static ABI uses `EvmKit.ContractMethod`; dynamic cases use the local `AbiEncoder`.
- `Legacy/` — passkey/secp256r1 path frozen for v1 (deferred to v3): `PasskeyAttestationDecoder`, `PasskeyCborReader`, `PasskeyAuthorizationRequester`, `PasskeyUserOpSigner`, `Secp256r1VerificationFacet`, `SmartAccountPasskeyManager`. Live curve dispatch in `BarzAddressResolver` / `AaSender` still references this.
- `Managers/` — `SmartAccountManager` (profile + deployment + pending op CRUD against `aa.sqlite`).
- `Models/` — domain types: `SmartAccountProfile`, `SmartAccountDeployment`, `PendingUserOperationRecord`, `AaSendFeeBreakdown`.
- `Providers/` — `EvmCodeProvider` (eth_getCode wrapper).
- `Send/` — pipeline: `AaSender` (orchestration), `AaSendHandler`, `AaTransactionService`, `AaSendData`, `EcdsaUserOpSigner`, `PimlicoProvider` (bundler + paymaster RPC), `SendScenarioDetector`, `Erc20PaymasterAndData` (paymaster wire-format parser), `PreparedUserOp`.
- `Storage/` — GRDB record storages backed by `aa.sqlite`; `AaStorageMigrator` owns schema.
- `Types/` — `UserOperation`, `PackedUserOperation` (userOpHash), `EntryPointVersion`, `WebAuthnSignature`, `UserOperationCallData`, `UserOperationReceipt`.

## Design rules

- **No `web3swift` imports** — ABI encoding relies on `EvmKit` primitives plus the local `AbiEncoder` for dynamic ABI cases.
- **AA storages throw** — records under `aa.sqlite` propagate errors. Legacy `bank.sqlite` storages keep their `try!` pattern; do not mix the styles.

## v1 targets

- Contract: Barz (Apache 2.0) on EntryPoint v0.6
- Networks: Ethereum mainnet + BSC
- Tokens: USDT, USDC (ETH), USDT (BSC) — via Pimlico ERC-20 paymaster
- Bundler: Pimlico only
