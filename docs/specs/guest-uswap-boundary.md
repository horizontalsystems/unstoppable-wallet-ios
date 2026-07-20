# Guest uSwap API Boundary

Status: Proposed for explicit approval

Branch: `core/guest-uswap-boundary`

Integration branch: canonical `version/0.50`

Base revision: `8a63bfda028dd8543115b26dd777235a53304311`

Android reference revision: `01b9bde` in `/Users/ant013/Android/swap-app-android`

Parent program: `multi-swap-ios` Android parity and WalletCore submodule migration

## 1. Decision summary

Add a second, account-independent SwiftPM library product named `GuestUSwap` to
the existing `packages/WalletCore` package. It will expose the complete raw
uSwap v2 HTTP contract used by Android through immutable Foundation-only DTOs,
an async client, an injected transport, and typed HTTP errors.

The existing `WalletCore` product will depend on `GuestUSwap` and adapt its raw
responses into the existing wallet-specific models. It will continue to own all
account, address derivation, signing, allowance, broadcasting, persistence,
debug enrichment, and provider presentation behavior. Existing Unstoppable
Wallet behavior must not change.

This boundary is chosen instead of making `USwapMultiSwapProvider`,
`IMultiSwapProvider`, or `USwapTracker` the guest API. Those types pull in
wallet state, MarketKit, chain kits, SwiftUI, app configuration, or
signing/broadcasting and therefore cannot provide an account-independent seam.

## 2. Goal and success criterion

The goal is to make the server contract needed by the Android-equivalent guest
swap flow reusable from the parent MultiSwap iOS app without importing the
Unstoppable Wallet account graph.

The change succeeds when:

1. a consumer can import `GuestUSwap` and call all five Android endpoints
   (`providers`, `tokens`, `rate`, `swap`, and `track`) without an account,
   adapter, signer, broadcaster, app singleton, or UI framework;
2. request and response behavior matches the audited Android wire contract;
3. the public DTO family is also a superset of the v2 fields already consumed
   by Unstoppable Wallet, so WalletCore does not maintain a second wire model;
4. WalletCore uses the shared client while preserving its existing request
   enrichment, error/cancellation behavior, provider resolution, allowance,
   nine chain-specific execution builders, and tracking projection;
5. direct package tests and wallet regression tests prove those invariants.

## 3. Assumptions

- The already deployed API behavior used by Android is authoritative for the
  guest flow. No new server behavior is required by this slice.
- The default Android development base URL is
  `https://swap-dev.unstoppable.money/api/v2/`. The library will not hard-code
  an environment decision; callers inject the base URL and API key.
- An API key is app-level configuration, not wallet authentication. Guest calls
  may send `x-api-key` while remaining account independent.
- Android passes a configured `x-api-key` header even when its value is empty.
  `GuestUSwapClient` will send the header whenever the injected key is non-`nil`
  and omit it only for `nil`. This represents both Android and current
  WalletCore configurations without inventing authentication behavior.
- The canonical upstream integration branch for this submodule is
  `version/0.50`, because this repository has no `develop` branch and the
  Stable app currently pins canonical revision `8a63bfda` from that branch.
- The package currently uses Swift tools 5.10 and iOS 17. This slice does not
  raise either baseline.
- Public API names below are final for this slice. A material contract change
  after approval requires an updated spec and renewed approval.

## 4. Scope

### 4.1 In scope

- Add the `GuestUSwap` library product/target and `GuestUSwapTests` test target
  to the existing WalletCore package.
- Model the audited Android v2 providers, tokens, rate, swap, and track wire
  contracts, plus the signed-transaction and THORChain execution fields already
  consumed by WalletCore.
- Add an injected async HTTP transport and a default URLSession implementation.
- Preserve arbitrary signable transaction JSON through a Foundation-only
  `GuestUSwapJSONValue` type.
- Add an internal WalletCore transport adapter backed by the current
  HsToolKit `NetworkManager`.
- Refactor the existing uSwap provider to use the shared client and map its DTOs
  back into the current wallet types.
- Add direct wire-contract tests and wallet compatibility regression tests.
- Make only the API surface needed by an external guest consumer public.

### 4.2 Out of scope

- MultiSwap iOS screens, navigation, history UI, app icons, and branding.
- Android-local provider aggregation, token cache, quote sorting, 30-second
  polling, resume/history, local expiry, payment deeplinks, and retry UI. Those
  belong to later parent-app slices built on this raw client.
- Wallet creation/import, active-account lookup, wallet balances, or address
  discovery in `GuestUSwap`.
- Transaction signing, allowance transactions, broadcasting, or chain adapter
  access in `GuestUSwap`.
- Changing current Unstoppable Wallet provider allowlists, provider titles,
  icons, types, terms requirements, route selection, Zcash alternate routes,
  address derivation, or swap persistence.
- Server/API changes, an OpenAPI generator, a new networking dependency, or a
  change to HsToolKit.
- Changing production/development base URL ownership in the app.
- Migrating the wallet-only `/check-addresses`, `/track/evm`, or
  `/track/thorchain` endpoints into the guest client. They are not part of the
  audited Android five-endpoint contract and remain on the existing HsToolKit
  path.
- Making the parent `multi-swap-ios` app consume the new product in this
  submodule branch. The parent gitlink update and app composition are separate
  reviewed changes.

## 5. Verified analog family

Evidence was selected by behavioral slice, then independently checked against
the exact current worktree. Gimle supplied discovery candidates, but current
files and Git were treated as authoritative because the Gimle run is `RED` for
documented stale-path defects.

### R2-S001 — package and dependency boundary

- Primary spine: `packages/WalletCore/Package.swift` at the base revision.
- Supporting implementation: current Decodable extension in
  `Sources/WalletCore/Extensions/NetworkManager.swift`.
- Supporting test style:
  `Unstoppable/Tests/Modules/MultiSwap/SwapRequestRefundTests.swift`.
- Rejected counterexample: `USwapMultiSwapProvider`, whose imports and
  `Core.shared` dependencies make it wallet-bound.

### R2-S002 — guest uSwap v2 contract

- Primary external analog: Android `SwapApi.kt`, `SwapApiModels.kt`, and its
  repository/orchestration family at revision `01b9bde`.
- Supporting current implementation: the `/tokens`, `/rate`, `/swap`, and
  `/track` portions of `USwapMultiSwapProvider.swift`.
- Supporting dependency behavior: HsToolKit 2.0.5 `NetworkManager.fetchData`.
- Rejected counterexample: public `USwapTracker`, which reads `AppConfig`,
  `Core.shared.localStorage`, and app-registered tracking enrichment.

### R2-S003 — WalletCore compatibility

- Primary composition spine:
  `Core/Factories/SwapProviderFactory.swift`, `DefaultSwapProviderResolver`,
  and `UnstoppableApp.initCore` registration.
- Supporting implementation and tests: current uSwap provider and
  `SwapProviderFactoryTests.swift`.
- Rejected counterexample: `IMultiSwapProvider`; its public surface exposes
  MarketKit tokens, SwiftUI values, wallet quotes, and `Core.instance`.
- Rejected lifecycle counterexample: `MultiSwapProviderManager`; it owns
  storage/cache behavior and launches provider synchronization, none of which
  belongs in a stateless raw client.

### R2-S004 — verification shape

- Primary analog: direct Swift Testing tests using `@Test`, `#expect`, and
  `#require` in the current MultiSwap test family.
- Supporting contract: the audited Android fixture/status/error matrix.
- Rejected counterexample: global-registry tests using `.serialized` as a
  general synchronization mechanism. New package tests have no global mutable
  state and must be safe to run in parallel.

## 6. Public module design

### 6.1 Package graph

`packages/WalletCore/Package.swift` will contain:

```text
GuestUSwap product
  -> GuestUSwap target
       -> Foundation only

WalletCore product
  -> WalletCore target
       -> GuestUSwap target
       -> all existing dependencies unchanged

GuestUSwapTests target
  -> GuestUSwap target
  -> Swift Testing supplied by the toolchain
  -> Fixtures directory processed as test resources
```

The new target must not import or depend on `WalletCore`, `MarketKit`,
`SwiftUI`, `UIKit`, `Combine`, `RxSwift`, Alamofire, ObjectMapper, HsToolKit, or
any chain kit. Foundation is the only runtime dependency.
`GuestUSwapTests` declares `.process("Fixtures")`, so tests load audited JSON
through `Bundle.module` rather than relying on the current working directory.

### 6.2 Client contract

The public protocol is:

```swift
public protocol GuestUSwapClientProtocol: Sendable {
    func providers() async throws -> [GuestUSwapProvider]
    func tokens(providerID: String) async throws -> GuestUSwapProviderTokens
    func rate(_ request: GuestUSwapRateRequest) async throws -> GuestUSwapRateResponse
    func swap(_ request: GuestUSwapSwapRequest) async throws -> GuestUSwapRoute
    func track(_ request: GuestUSwapTrackRequest) async throws -> GuestUSwapTrackResponse
}
```

`GuestUSwapClient` will be a stateless immutable value conforming to that
protocol. Its initializer accepts:

- `baseURL: URL`;
- `apiKey: String?`;
- `transport: any GuestUSwapHTTPTransport`.

Encoding policy is not another public dependency: the client creates fresh
standard `JSONEncoder`/`JSONDecoder` instances per call with the fixed key
spellings in this spec. This avoids mutable shared codecs and leaves one
deterministic public initializer.

The client owns URL construction, query encoding, JSON encoding/decoding, and
the endpoint paths. It does not own caching, provider filtering, orchestration,
polling, retries, logging, state, or environment selection.

### 6.3 Transport contract

```swift
public protocol GuestUSwapHTTPTransport: Sendable {
    func data(for request: GuestUSwapHTTPRequest) async throws -> Data
}
```

`GuestUSwapHTTPRequest` is a public immutable `Sendable` value containing:

- a fully resolved `URL`, including encoded query items;
- a `GuestUSwapHTTPMethod` (`get` or `post`);
- `[String: String]` headers;
- optional encoded body `Data`.

The default `GuestUSwapURLSessionTransport` builds a `URLRequest`, awaits
`URLSession.data(for:)`, accepts HTTP `200..<300`, and throws
`GuestUSwapHTTPError(statusCode:body:)` otherwise. It adds no retry, polling,
timeout override, cookie, account identifier, signature, or idempotency key.
Its default URLSession configuration has cookie storage and automatic cookie
handling disabled, no URL cache, and a reload-ignoring-local-cache request
policy, matching Android's OkHttp client with neither a cookie jar nor a
configured cache. An injected custom session remains an explicit caller choice.

Cancellation is not caught, translated, or retried. URLSession cancellation
and an injected transport's `CancellationError` must reach the caller unchanged.
No unstructured `Task` is created by the target.

### 6.4 Request headers and encoding

- POST calls set `Content-Type: application/json`.
- `x-api-key` is present exactly when `apiKey != nil`; an injected empty string
  produces an empty header value, matching Android.
- Optional `nil` properties are omitted from JSON.
- JSON key spelling follows the server examples exactly.
- Query values are encoded with `URLComponents`; the provider ID is never
  appended through string interpolation.
- Decimal amounts remain caller-supplied strings. The raw client does not
  round, localize, or normalize them.

### 6.5 Public DTO family

All public DTOs are immutable structs/enums with public initializers and
`Codable`, `Equatable`, and `Sendable` conformance where their stored values
permit it. Asset amounts are strings and server epoch values are `Int64?`;
the only numeric exceptions are `Decimal` slippage and the nullable `Double`
provider-error thresholds audited from Android.

#### Providers

`GuestUSwapProvider` includes nullable:

- `name`, `provider`, `executionType`, `suspended`;
- `supportedChainIds`;
- `amlPolicy`, `amlPolicyDescription`.

The client returns the server list unchanged. Active-transfer filtering is a
guest-app orchestration rule, not transport behavior.

#### Tokens

`GuestUSwapProviderTokens` includes `provider`, `executionType`, and `tokens`.
Each `GuestUSwapToken` includes:

- `identifier`, `address`, `chain`, `chainId`;
- `coingeckoId`, `decimals`, `logoURI`, `name`, `ticker`, `shortCode`.

All fields are nullable at the wire layer. Validation, default decimals,
deduplication, provider membership, and malformed-token skipping remain above
the client.

#### Rate

`GuestUSwapRateRequest` includes:

- `sellAsset`, `buyAsset`, `sellAmount`, `slippage`, `providers`;
- optional `chainId` for current WalletCore compatibility.

`slippage` is a JSON number backed by Swift `Decimal`. This accepts Android's
exact value `1` while retaining the current WalletCore ability to pass a
non-integer slippage without rounding it through `Double`.

`GuestUSwapRateResponse` contains `routes` and `providerErrors`.
`GuestUSwapProviderError` contains `provider`, `error`, `errorCode`,
`minimumAmount: Double?`, and `maximumAmount: Double?`, matching Android's
numeric wire fields rather than treating them as asset-amount strings.

The client does not map HTTP 404 to an empty route list. It exposes the typed
HTTP error so the Android-equivalent guest repository can implement that rule.

#### Swap

`GuestUSwapSwapRequest` includes:

- `sellAsset`, `buyAsset`, `sellAmount`, `provider`;
- `destinationAddress`, `slippage`, `refundAddress`;
- optional `chainId` from the Android DTO.

Its `slippage` uses the same `Decimal` representation as the rate request.
An additional optional `sourceAddress` stored property/initializer is
`package`-scoped for WalletCore's existing signed-transaction flow; it is
encoded by the same client but is not speculative public guest API.

The response is one `GuestUSwapRoute`, not a routes wrapper. The raw client does
not require transfer execution, deposit address, or UUID; those are guest-flow
projection rules and wallet commit validation rules.

#### Route economics and metadata

`GuestUSwapRoute` includes all audited fields:

- `providers`, `sellAsset`, `sellAmount`, `buyAsset`;
- `expectedBuyAmount`, `minBuyAmount`;
- `fees`, with `type`, `chain`, `asset`, `amount`, `protocol`;
- `estimatedTime`, with `inbound`, `swap`, `outbound`, `total`;
- `expiresAt`, `amlPolicy`, `execution`, `uuid`, `providerSwapId`;
- current WalletCore top-level `approvalSpender`.

No sorting, service-fee selection, expiry normalization, or provider selection
occurs in the raw client.

#### Execution union

`GuestUSwapExecution` is a custom Codable enum with four cases. Associated
wire fields are nullable so the raw response remains decodable even when a
provider returns an incomplete instruction:

1. `transfer`: chain, deposit address, amount, asset, typed attachment, typed QR,
   and optional unsigned transaction;
2. `signedTransaction`: chain, transactions, and optional approval;
3. `thorchainDeposit`: chain, inbound address, memo, and delivery;
4. `unknown`: nullable method plus the complete raw JSON value.

Method matching for the three known cases uses the exact server values
`transfer`, `signed_transaction`, and `thorchain_deposit`. Preserving unknown
payloads prevents a future execution method from making an otherwise valid rate
response undecodable; consumer layers decide whether to reject it.

Decoding first captures the raw JSON value, then projects known fields
tolerantly. Missing/null `method` becomes `.unknown(method: nil, payload:)`.
A known method with missing, null, or wrongly typed associated fields remains
the known case with those fields nil; it does not reject the containing route.
An explicit JSON null remains a nil `GuestUSwapRoute.execution`. Guest and
WalletCore projections then apply their own required-field validation.

Supporting values include:

- `GuestUSwapAttachment(type:value:)`;
- `GuestUSwapQR(str:dataURL:)`;
- `GuestUSwapApproval(spender:)`;
- `GuestUSwapDelivery(kind:router:approval:shieldedMemoAddress:unsignedTx:)`;
- `GuestUSwapSignableTransaction(kind:payload:tx:message:psbt:xdr:)`.

`GuestUSwapJSONValue` is a recursive Codable enum for string, number, boolean,
object, array, and null. Its number case stores `GuestUSwapJSONNumber`, whose
cases are signed `Int64`, unsigned `UInt64`, and base-10 `Decimal`. Decoding
tries those exact representations in that order and never routes an integer
through `Double`. Integral values outside the signed/unsigned 64-bit domain are
rejected after Decimal fallback instead of being silently rounded. Fractional
numbers use Foundation `Decimal`'s exact supported precision; the audited API
represents asset amounts and large chain quantities as strings. This preserves
integers above `2^53`, fractional provider payload values, all currently
consumed EVM `to`/`value`/`data`/`gas` fields, and dynamic
Tron/TON/Cosmos/Ripple/NEAR `tx` values without `[String: Any]`, ObjectMapper,
or unchecked Sendable conformance.

#### Tracking

The public `GuestUSwapTrackRequest` includes only `uuid` and optional
`inboundTxHash`, matching Android. WalletCore receives a `package`-scoped
initializer for optional
`additionalFields: [String: GuestUSwapJSONValue]`. Custom encoding merges those
fields but never permits them to replace `uuid` or a non-`nil` `inboundTxHash`.
This preserves current app-registered tracking enrichment without exposing an
arbitrary public escape hatch or making the guest target aware of `AppConfig`,
`Core`, or `Swap`.

`GuestUSwapTrackResponse` includes:

- raw nullable `status` string;
- `providers`, `fromAsset`, `fromAmount`, `fromAddress`;
- `toAsset`, `toAmount`, `toAddress`;
- ordered `legs` with `chainId`, `hash`, `type`, `status`, asset/amount/address
  fields;
- `meta.pauseReason` and `meta.sellAmountUsd`.

The raw client does not map 409, unknown statuses, terminal states, polling, or
local expiry. It exposes status and typed HTTP error exactly to its consumer.

## 7. WalletCore adapter and compatibility design

### 7.1 Internal transport adapter

WalletCore adds an internal actor `NetworkManagerGuestUSwapTransport` that
conforms to `GuestUSwapHTTPTransport` and owns the existing HsToolKit
`NetworkManager`. Actor isolation permits a Sendable transport boundary without
`@unchecked Sendable`.

For POST requests it converts the encoded JSON object into Alamofire
`Parameters`, then calls the existing `NetworkManager.fetchData` with
`JSONEncoding.default`, the supplied headers, and the exact current accepted
content types `application/json` and `text/plain`. For GET requests it uses the
already resolved URL. The adapter retains HsToolKit's current `200..<400`
validation range, while the default guest URLSession transport independently
uses Android's `200..<300` success range. This preserves existing NetworkManager
logging, HTTP `ResponseError(statusCode:json:rawData:)`, and cancellation behavior while
allowing the same higher-level client to serve both WalletCore and URLSession
consumers.

The adapter must not wrap or translate `CancellationError`. Semantic JSON is
preserved; tests compare decoded JSON objects, not dictionary byte order.
The adapter has a narrow internal `NetworkManager`-compatible fetching seam so
tests can assert method, encoding, headers, content types, returned `text/plain`
data, sentinel errors, and cancellation without a live server. Production
composition supplies the unchanged HsToolKit manager; the seam is not public.

### 7.2 Staged migration

Implementation proceeds in four reviewable stages within this branch:

1. add the package product, DTOs, client, default transport, fixtures, and
   package tests without changing WalletCore runtime calls;
2. add the internal NetworkManager adapter and wallet mapping helpers with
   compatibility tests;
3. switch existing `/tokens`, `/rate`, `/swap`, and `/track` calls to the shared
   client while keeping all current wallet orchestration around them;
4. remove the nested duplicate wire DTOs only after old/new fixture projection
   tests pass.

Only the recorded-swap `/track` shape with a valid UUID uses the five-endpoint
client. Existing wallet-only `/check-addresses`, `/track/evm`, and
`/track/thorchain` calls, plus any legacy tracker call that cannot form the
typed UUID request, continue through the current NetworkManager path. They may
decode shared response DTOs where compatible, but their endpoint and failure
behavior do not change.

Each stage must compile before the next. No temporary public API inside the
WalletCore target is introduced.

### 7.3 Wallet behavior that must remain unchanged

- `DefaultSwapProviderResolver` and `SwapProviderFactory` continue to construct
  the same providers in the same order.
- `USwapProvider` remains the wallet's hard-coded provider presentation enum.
- Existing asset-map persistence and expiry remain wallet-owned.
- Wallet token projection retains its existing strict requirements: missing
  `tokens`, `identifier`, `chain`, or `chainId` still fails the wallet sync
  path instead of silently adopting Android's malformed-token skipping policy.
- Destination, source, refund, transparent/unified Zcash address derivation and
  alternate route selection remain unchanged.
- Dry `/rate` and committed `/swap` retain current WalletCore `chainId`,
  `sourceAddress`, slippage, provider selection, and destination behavior.
- `approvalSpender` remains available on dry quotes; allowance UI/build logic
  must not regress.
- All current signed-transaction, transfer, and THORChain delivery builders keep
  the exact raw fields they consume.
- A committed wallet swap still rejects a missing UUID before funds can be sent.
- Wallet quote projection still requires a parseable `expectedBuyAmount`, maps
  an absent/unparseable `minBuyAmount` to nil, treats an unknown execution as no
  usable execution, and reports no routes through the existing `SwapError`.
- Wallet tracking projection still requires the fields required by the current
  `TrackResponse`/`Leg` models; a missing hash alone continues to become an empty
  string. The raw guest DTO remains nullable, but the adapter must not silently
  relax these wallet invariants.
- `USwapTracker` remains source compatible. AppConfig debug flags,
  `SwapTrackParametersFactory` enrichment, endpoint selection, and projection
  into `Swap` remain in WalletCore.
- Current HsToolKit `NetworkManager.ResponseError` remains observable to
  WalletCore callers; the typed `GuestUSwapHTTPError` applies to the default
  URLSession transport used by direct guest consumers.
- No existing public method or class is removed in this slice.

## 8. Android-equivalent behavior enabled, but not implemented here

The parent guest app will build these rules above `GuestUSwap`:

- keep providers whose execution type equals `transfer` case-insensitively,
  whose `suspended` is not `true`, and whose provider ID is non-null;
- fetch provider token lists in parallel, skip individual provider failures,
  deduplicate by identifier, and retain all provider memberships;
- intersect input/output providers for rates, map HTTP 404 to no route, ignore
  response `providerErrors`, drop malformed routes, and sort expected amount
  descending;
- accept swap results only for transfer execution with nonblank deposit address
  and UUID; use exact execution amount with requested-amount fallback;
- preserve attachment, QR string, provider swap ID, and seconds/milliseconds
  expiry normalization;
- map track HTTP 409 to not-started, other non-cancellation failures to unknown,
  poll every 30 seconds, and stop only for completed/refunded/failed;
- keep local expiry, history, resume, one-shot terminal detail refresh, and the
  Android manual retry semantics outside the API client.

This separation prevents Android ViewModel/repository policy from becoming an
irreversible networking API contract.

## 9. Affected files and areas

Expected new files:

- `packages/WalletCore/Sources/GuestUSwap/GuestUSwapClient.swift`
- `packages/WalletCore/Sources/GuestUSwap/GuestUSwapHTTPTransport.swift`
- `packages/WalletCore/Sources/GuestUSwap/GuestUSwapModels.swift`
- `packages/WalletCore/Sources/GuestUSwap/GuestUSwapJSONValue.swift`
- `packages/WalletCore/Tests/GuestUSwapTests/GuestUSwapClientTests.swift`
- `packages/WalletCore/Tests/GuestUSwapTests/GuestUSwapModelTests.swift`
- `packages/WalletCore/Tests/GuestUSwapTests/Fixtures/*`
- `packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/Providers/USwap/NetworkManagerGuestUSwapTransport.swift`
- `Unstoppable/Tests/Modules/MultiSwap/USwapGuestAdapterTests.swift`

Expected modified files:

- `packages/WalletCore/Package.swift`
- `packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/Providers/USwap/USwapMultiSwapProvider.swift`

An existing test file may receive a narrowly scoped fixture assertion if that
is smaller than a new wallet regression file. No other area is approved by this
spec. If implementation requires a file outside this list, its relationship to
an acceptance criterion must be recorded before editing; a new architectural
boundary requires renewed approval.

## 10. Delta matrix

| Slice | Verified baseline | Approved delta | Invariant retained | Proof |
|---|---|---|---|---|
| R2-S001 | One monolithic WalletCore product/target | Add Foundation-only `GuestUSwap` product/target and direct test target | Existing WalletCore product and dependencies remain available | Package graph inspection, dependency grep, package build/tests |
| R2-S002 | Android has accountless v2 Retrofit client; WalletCore has nested partial ObjectMapper DTOs | Implement five-endpoint async Swift client and one superset Codable DTO family | Exact endpoint names, request keys, nullable response fields, no auth/sign/retry | Mock-transport request tests and audited fixtures |
| R2-S002 | Android transport exposes HTTP outcomes to repositories | Add typed URLSession HTTP error with body/status; keep cancellation unchanged | 404/409 mapping stays outside raw client | HTTP and deterministic cancellation tests |
| R2-S002 | Current signable payload uses dynamic `[String: Any]` | Preserve it in recursive Codable `GuestUSwapJSONValue` with signed/unsigned/decimal number cases and no Double integer path | Current EVM, Tron/TON, Solana, UTXO, Stellar data remain lossless; out-of-domain integral numbers fail instead of round | Round-trip fixtures, `>2^53` and out-of-range integral fixtures, and wallet builder projection assertions |
| R2-S003 | Current provider calls HsToolKit directly and owns wallet mapping | Add internal actor transport adapter and migrate transport/DTO decoding | HsToolKit `200..<400`, JSON/text content types, errors, logging, cancellation, and all wallet behavior remain unchanged | Adapter seam assertions, old/new fixture mapping, and app regression tests |
| R2-S003 | Tracker accepts app-enriched dynamic parameters | Provide reserved-key-safe package-only `additionalFields` on the shared track request | AppConfig/Core enrichment stays only in WalletCore; public guest request stays Android-shaped | Encoded body and tracker regression tests |
| R2-S004 | App tests cover a small track subset | Add parallel-safe package contract matrix and focused wallet tests | Existing tests continue to pass | Narrow package tests, AppTests, both app builds |

## 11. Test plan before code

### 11.1 GuestUSwap package tests

Use Swift Testing async tests directly. Do not wrap calls in unstructured tasks
except the deterministic cancellation test, which owns and awaits its task
handle. Do not use fixed sleeps, shared mutable state, or `.serialized` as a
general test lock.

#### Wire request conformance

- Verify exact method, path, query, headers, and decoded JSON body for all five
  endpoints.
- Verify percent encoding for provider IDs in `tokens`.
- Verify `x-api-key` behavior for nonempty, empty, and nil keys.
- Verify POST content type and GET body absence.
- Verify there is no explicit `Accept` header and the default transport does not
  attach request cookies or serve/store URL-cache responses.
- Verify nullable `chainId`, `refundAddress`, and `inboundTxHash` omission.
- Through package-level tests, verify WalletCore-only `sourceAddress` omission
  and that `additionalFields` cannot replace reserved tracking keys.
- Verify caller-provided slippage and amount strings are transmitted unchanged;
  Android projection tests later supply slippage `1`.

#### Providers and tokens fixtures

- Decode active, suspended, mixed-case transfer, signed, THORChain, and null
  provider entries.
- Decode complete token metadata, native/contract tokens, nulls, and malformed
  optional values without adding guest orchestration policy to the client.

#### Rate and route fixtures

- Decode multiple routes, fees, service fee metadata, estimated times, AML,
  provider errors, min buy amount, expiry, UUID, and provider swap ID.
- Decode fractional numeric `minimumAmount`/`maximumAmount` provider thresholds.
- Decode top-level approval spender.
- Prove a 404 remains a typed HTTP error rather than becoming an empty response.

#### Execution fixtures

- Decode transfer amount, asset, deposit address, attachment, QR string/data URL,
  and unsigned transaction.
- Decode signed transactions, approval, arbitrary EVM fields, dynamic `tx`,
  Solana message, PSBT, and XDR.
- Decode THORChain inbound address, memo, delivery router, approval, shielded memo
  address, and unsigned transaction.
- Decode missing/null method as unknown without rejecting the route; decode a
  known transfer with missing deposit address and other incomplete fields, then
  prove projection—not raw decoding—rejects it.
- Preserve and round-trip an unknown execution method and payload.
- Round-trip all `GuestUSwapJSONValue` cases, including nested objects/arrays,
  booleans, and null. Numeric cases include a signed value, `UInt64` above
  `2^53`, a fractional `Decimal`, and an integral value above `UInt64.max` that
  must throw instead of round.

#### Track fixtures

- Decode every Android status string, a future unknown status, and null.
- Decode action-required pause reason, sell amount USD, and ordered legs with
  all nullable fields.
- Prove 409 and 500 surface as typed HTTP errors with unchanged bodies.
- Prove an unredirected `3xx` response is not accepted as a decoded success.

#### Error and concurrency behavior

- Verify invalid JSON surfaces a decoding error.
- Verify the client performs exactly one transport call and adds no retry.
- Use a deterministic blocking mock transport, cancel the owned task while it is
  suspended, release/await it, and assert `CancellationError` reaches the caller
  unchanged. No time-based sleep is permitted.
- Keep mock state actor-isolated or immutable; do not add
  `@unchecked Sendable`.

### 11.2 WalletCore compatibility tests

- Feed shared DTO fixtures through the WalletCore mapper and compare the same
  wallet-visible values previously decoded by nested ObjectMapper models.
- Verify missing required wallet token/quote/track fields retain the current
  failure or nil behavior even though the public raw DTOs are nullable.
- Preserve expected/minimum buy amounts, estimated time, UUID, destination and
  refund stamping, and top-level/execution approval spender fallback.
- Preserve signed transaction `to`, `value`, `data`, `gas`, inner `tx`, message,
  PSBT, and XDR values used by all current builders.
- Preserve transfer text memo and THORChain delivery memo/router behavior.
- Preserve committed-swap missing-UUID rejection.
- Preserve Zcash transparent/shielded alternate route selection.
- Preserve `action_required`, unknown status, pause reason, ordered legs,
  completed amount, and provider projection.
- Preserve factory/resolver registration and public `USwapTracker` behavior.
- Through the internal fetching seam, verify the adapter passes exactly
  `application/json` and `text/plain`, decodes returned text/plain JSON, and
  preserves HsToolKit's current `200..<400` contract.
- Verify sentinel errors, HsToolKit `NetworkManager.ResponseError` in an
  integration-capable path, and cancellation are not translated by the adapter.

### 11.3 Static boundary checks

Targeted searches must prove that `Sources/GuestUSwap` contains no import or
symbol reference to forbidden wallet/UI/chain dependencies, account state,
signers, broadcasters, `Core`, or app configuration.

## 12. Verification plan

Run checks in this order:

1. `git diff --check`
2. targeted forbidden-dependency `rg` checks in `Sources/GuestUSwap`
3. `swift test --package-path packages/WalletCore --filter GuestUSwapTests`
4. targeted Development scheme AppTests for uSwap request/refund, adapter, and
   provider-factory tests
5. Development workspace build for a generic iOS Simulator with code signing
   disabled
6. Production workspace build for a generic iOS Simulator with code signing
   disabled
7. full diff audit against the delta matrix
8. refresh every affected load-bearing Gimle/current-tree claim and render the
   final Gimle reliability report

If `swift test` cannot evaluate the iOS-only WalletCore package graph on the
host, run the `GuestUSwapTests` target through Xcode and report the exact host
limitation. If the existing Xcode 26.3/iOS 26.2 platform-registration mismatch
persists, report it verbatim and still run every host/static check that remains
possible. A blocked broad build is not represented as a passing result.

## 13. Acceptance criteria

- [ ] `GuestUSwap` is a public SwiftPM product with Foundation as its only
      runtime dependency.
- [ ] A guest consumer can construct the client without account or wallet state.
- [ ] All five Android endpoints have exact request/response DTO coverage.
- [ ] API key, nullable-field, JSON, query, HTTP-error, and cancellation behavior
      matches this spec.
- [ ] The default transport accepts only `2xx`, sends no explicit `Accept`
      header, and does not use cookies or URL caching.
- [ ] Raw transfer data needed by Android and all signed/THORChain data needed by
      WalletCore survive decoding without duplicate wire models.
- [ ] Missing/null/incomplete execution payloads do not invalidate their route;
      consumer projection performs the required-field rejection.
- [ ] Dynamic JSON integers never pass through `Double`; values above `2^53`
      and through `UInt64.max` round-trip exactly, while larger integral values
      fail instead of rounding.
- [ ] `GuestUSwap` starts no tasks, retries, polling loops, caches, or global
      mutable state.
- [ ] WalletCore uses the shared client through its internal NetworkManager
      adapter.
- [ ] Existing Unstoppable Wallet provider composition and all listed wallet
      behaviors remain logically unchanged.
- [ ] The WalletCore adapter retains HsToolKit's `200..<400` status range and
      `application/json` plus `text/plain` content-type acceptance.
- [ ] Wallet-only `/check-addresses`, `/track/evm`, `/track/thorchain`, and
      legacy malformed tracker paths retain their existing transport behavior.
- [ ] New direct package tests and focused wallet regression tests pass.
- [ ] Both application schemes build, or an external toolchain/platform blocker
      is captured with all narrower checks passing.
- [ ] No unrelated source, formatting, generated, or dependency churn is present.
- [ ] Gimle/current-tree evidence and final reliability report are updated.

## 14. Risks and mitigations

- **ObjectMapper-to-Codable tolerance:** optional/null/type behavior may differ.
  Mitigation: decode audited Android fixtures plus current wallet fixtures before
  switching runtime calls; preserve unknown execution payloads.
- **Dynamic signable transaction loss:** replacing `[String: Any]` can drop
  chain-specific fields or round large numbers. Mitigation: recursive JSON value
  round trips, signed/unsigned/decimal numeric cases with no Double integer path,
  explicit rejection above the supported integral domain, and direct
  builder-field regression assertions.
- **Concurrency/sendability:** injecting the current non-Sendable NetworkManager
  could invite unsafe annotations. Mitigation: an actor adapter, immutable public
  values, structured caller-owned tasks, and no `@unchecked Sendable`.
- **Error semantic drift:** URLSession and HsToolKit expose different error
  types. Mitigation: transport-specific errors remain intact; the raw client does
  not perform status mapping, and wallet callers continue through HsToolKit with
  its current status and JSON/text content-type validation.
- **Tracking enrichment regression:** a rigid request DTO could drop debug or
  registered fields. Mitigation: reserved-key-safe, package-only
  `additionalFields` encoded by the shared client and populated only by
  WalletCore.
- **Over-broad extraction:** moving wallet builders into the public module would
  couple the guest app to accounts and chains. Mitigation: forbidden dependency
  checks and the explicit boundary acceptance criterion.
- **Gimle stale paths:** one search returned deleted factory paths even though
  the indexed commit matched the worktree. Mitigation: all load-bearing paths
  were independently verified with Serena, targeted `rg`, and Git; trust remains
  RED and is not upgraded cosmetically.

## 15. Open questions

There are no blocking product questions for implementation. The following
choices are deliberately resolved by this spec:

- **Does the raw client implement Android filtering/sorting/polling?** No; it
  exposes the wire contract, and the parent guest repository implements those
  policies exactly as Android does.
- **Does a guest API key violate account independence?** No; the key configures
  the application, not a wallet/account, and Android already uses it.
- **Do we publish the current WalletCore provider?** No; publish a separate
  package product and retain the wallet provider as an adapter/consumer.
- **How are dynamic transactions represented?** Recursive Codable JSON values
  with signed, unsigned, and Decimal number cases, not `[String: Any]`, Double
  integer coercion, or an additional dependency.
- **How is cancellation handled?** It propagates unchanged; there is no catch,
  retry, or translation in the raw client.
- **Can implementation make WalletCore methods/classes public?** Only when
  required for the approved shared boundary. This design requires public
  `GuestUSwap` types, not broader exposure of wallet/account classes.

## 16. Approval gate

This document, the delta matrix, and the test plan are the complete written
design for R2. The branch must contain a spec-only commit and be pushed for
review. No repository source or test implementation may begin until the user
explicitly approves the pushed spec revision. Any material design change after
approval invalidates that approval and returns this slice to design review.
