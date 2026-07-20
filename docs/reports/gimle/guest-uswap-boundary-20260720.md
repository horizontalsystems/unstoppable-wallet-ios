# Gimle reliability report: guest-uswap-boundary-20260720

- Task: R2-guest-uswap-boundary
- Workflow/phase: analog_change / awaiting_approval
- Trust: **RED**
- Repository: /Users/ant013/Data/AI/paperclip/workspace/multi-swap-ios/Unstoppable
- Base HEAD: 8a63bfda028dd8543115b26dd777235a53304311
- Final HEAD: n/a
- Gimle runtime: native-dev@0e9cf57c00ff970f584256126b500166580e7a72
- Indexed commit: 8a63bfda028dd8543115b26dd777235a53304311

## Metrics

- Calls: 13 (success 10, warning 1, error 1, false-success 1)
- Useful-call rate: 76.9%
- Response-byte coverage: 0/13; total n/a
- Duration coverage: 13/13; total 75701 ms
- Gimle agreement: 80.0%
- Gimle contradiction: 20.0%
- Location validity: 80.0%; coverage 5/5
- Freshness coverage: 80.0%
- Replacement/fallback claims: 1
- Bugs: 3
- Analog slices/candidates: 4/17

### Calls by tool

| Tool | Success | Warning | Error | False-success |
|---|---:|---:|---:|---:|
| palace.code.get_snippet_rich | 0 | 0 | 1 | 0 |
| palace.code.list_passthrough_projects | 1 | 0 | 0 | 0 |
| palace.code.search_graph | 1 | 0 | 0 | 1 |
| palace.code.semantic_search | 3 | 1 | 0 | 0 |
| palace.git.log | 1 | 0 | 0 | 0 |
| palace.health.status | 1 | 0 | 0 | 0 |
| palace.memory.get_project_overview | 1 | 0 | 0 | 0 |
| palace.memory.health | 1 | 0 | 0 | 0 |
| palace.memory.list_projects | 1 | 0 | 0 | 0 |

Bug classes: {'caller_error': 1, 'confirmed_mcp_bug': 1, 'stale_index': 1}
Bug severities: {'low': 1, 'medium': 1, 'high': 1}
Bug statuses: {'workaround': 3}

## Gimle calls

| Event | Phase | Tool | Protocol | Outcome | Total/returned | Bytes | Duration | Used | Args hash | Warnings |
|---|---|---|---|---|---|---:|---:|:---:|---|---|
| E-0001 | preflight | palace.health.status | ok | success | n/a/1 | n/a | 400 | yes | 44136fa355b3678a | n/a |
| E-0002 | preflight | palace.memory.health | ok | success | 19/19 | n/a | 9500 | yes | 44136fa355b3678a | n/a |
| E-0003 | preflight | palace.memory.list_projects | ok | success | 19/19 | n/a | 9700 | yes | 44136fa355b3678a | n/a |
| E-0004 | preflight | palace.memory.get_project_overview | ok | success | n/a/1 | n/a | 1600 | yes | e40d2aa6fdce6b6f | n/a |
| E-0005 | preflight | palace.git.log | ok | success | 1/1 | n/a | 100 | yes | bc07a8615e5efcad | n/a |
| E-0006 | preflight | palace.code.list_passthrough_projects | ok | success | 7/7 | n/a | 1 | yes | 44136fa355b3678a | n/a |
| E-0007 | evidence | palace.code.semantic_search | ok | warning | 0/0 | n/a | 10000 | no | ea99bb0aeca36dce | source_scope first_party excluded all candidates; deployment reports project and dependency scopes |
| E-0008 | evidence | palace.code.semantic_search | ok | success | 62/8 | n/a | 10000 | yes | 6f53c5d3c79632e6 | n/a |
| E-0009 | evidence | palace.code.search_graph | ok | success | 1/1 | n/a | 7100 | yes | cf113b08a364c71f | n/a |
| E-0010 | evidence | palace.code.get_snippet_rich | ok | error | n/a/0 | n/a | 700 | no | 122f52fb9e488e1d | ok=false ambiguous_qualified_name for an exact class qualified name due to nested prefix match |
| E-0011 | evidence | palace.code.semantic_search | ok | success | 54/8 | n/a | 10000 | yes | 9812c6e96e7da84e | n/a |
| E-0012 | evidence | palace.code.search_graph | ok | false_success | 6/6 | n/a | 6600 | no | 8b56dba5fb943187 | Successful payload mixed current package/test paths with two paths absent from HEAD despite current index metadata |
| E-0013 | evidence | palace.code.semantic_search | ok | success | 9/8 | n/a | 10000 | yes | 67706717e75e3dfd | n/a |

## Component analog family

| Slice | Risk | Required dimensions | Required roles | Waived roles | Primary | Supporting | Counterexamples |
|---|---|---|---|---|---|---|---|
| R2-S001 | high | boundary, dependencies, responsibility, tests, trust | composition, consumer, contract, counterexample, implementation, test | n/a | A-R2-S001-PACKAGE | A-R2-S001-NETWORK, A-R2-S001-TESTS | X-R2-S001-MONOLITH |
  - Conflict: A public seam inside WalletCore is smaller in file count, but it leaves the guest consumer linked to the full wallet/account/UI dependency graph.; resolution: Add a dedicated GuestUSwap product/target with Foundation-only public contracts and injected transport; WalletCore depends on it. Do not make USwapMultiSwapProvider the guest API.
| R2-S002 | high | boundary, dependencies, lifecycle, responsibility, state_errors, tests, trust | composition, consumer, contract, counterexample, implementation, lifecycle_error, test | n/a | A-R2-S002-ANDROID | A-R2-S002-USWAP, A-R2-S002-NETWORK, A-R2-S002-TESTS | X-R2-S002-TRACKER |
  - Conflict: Android needs dynamic transfer providers and tolerant complete wire DTOs, while the wallet uses a hardcoded provider enum, strict partial DTOs, wallet-derived addresses and all execution mechanisms.; resolution: GuestUSwap owns one superset Codable wire model/client for all five endpoints. Guest orchestration applies transfer-only filtering; the WalletCore adapter maps the shared DTOs back to existing wallet models and preserves its hardcoded/provider-builder behavior.
| R2-S003 | critical | boundary, dependencies, lifecycle, responsibility, state_errors, tests, trust | composition, consumer, contract, counterexample, implementation, lifecycle_error, test | n/a | A-R2-S003-FACTORY | A-R2-S003-PROVIDER, A-R2-S003-TESTS | X-R2-S003-PUBLIC |
  - Conflict: Sharing raw client/models changes the internal decoding boundary of a churn-heavy wallet provider.; resolution: Keep DefaultSwapProviderResolver, USwapMultiSwapProvider public behavior, Core/AppConfig enrichment, wallet address derivation, allowance and builders unchanged; inject the shared client internally and add parity fixtures before deleting nested duplicate DTOs.
| R2-S004 | normal | boundary, dependencies, responsibility, state_errors, tests | composition, consumer, contract, counterexample, implementation, test | n/a | A-R2-S004-TESTS | A-R2-S004-ANDROID, A-R2-S004-PACKAGE | X-R2-S004-SERIALIZED |
  - Conflict: Existing factory tests serialize because they mutate global state, while guest wire tests need to prove no globals are touched.; resolution: GuestUSwapTests uses a per-test mock transport and synthetic fixtures without serialized suites; wallet registry/track projection regressions remain in the existing app test target.

### Analog candidates

| Candidate | Slice | Disposition | Fact | Roles | Dimensions | Freshness | Path |
|---|---|---|---|---|---|---|---|
| A-R2-S001-PACKAGE | R2-S001 | kept | F-R2-006 | composition, contract, implementation | boundary, dependencies, responsibility, tests | known_current | packages/WalletCore/Package.swift |
| A-R2-S001-NETWORK | R2-S001 | supporting | F-R2-003 | consumer, implementation, lifecycle_error | dependencies, lifecycle, state_errors, trust | known_current | packages/WalletCore/Sources/WalletCore/Extensions/NetworkManager.swift |
| A-R2-S001-TESTS | R2-S001 | supporting | F-R2-005 | consumer, test | responsibility, tests | known_current | Unstoppable/Tests/Modules/MultiSwap/SwapRequestRefundTests.swift |
| X-R2-S001-MONOLITH | R2-S001 | rejected | F-R2-002 | counterexample | boundary, dependencies, trust | known_current | packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/Providers/USwap/USwapMultiSwapProvider.swift |
| A-R2-S002-ANDROID | R2-S002 | kept | F-R2-011 | consumer, contract, implementation, lifecycle_error | boundary, lifecycle, responsibility, state_errors, trust | known_current | app/src/main/java/io/horizontalsystems/swapapp/swap/api/SwapApi.kt |
| A-R2-S002-USWAP | R2-S002 | supporting | F-R2-002 | composition, consumer, implementation | dependencies, lifecycle, responsibility, state_errors, trust | known_current | packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/Providers/USwap/USwapMultiSwapProvider.swift |
| A-R2-S002-NETWORK | R2-S002 | supporting | F-R2-010 | implementation, lifecycle_error | dependencies, lifecycle, state_errors, trust | known_current | Sources/HsToolKit/NetworkManager.swift |
| A-R2-S002-TESTS | R2-S002 | supporting | F-R2-005 | test | state_errors, tests | known_current | Unstoppable/Tests/Modules/MultiSwap/SwapRequestRefundTests.swift |
| X-R2-S002-TRACKER | R2-S002 | rejected | F-R2-007 | counterexample | boundary, dependencies, trust | known_current | packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/Providers/USwap/USwapMultiSwapProvider.swift |
| A-R2-S003-FACTORY | R2-S003 | kept | F-R2-004 | composition, consumer, contract, implementation | boundary, dependencies, lifecycle, responsibility, trust | known_current | packages/WalletCore/Sources/WalletCore/Core/Factories/SwapProviderFactory.swift |
| A-R2-S003-PROVIDER | R2-S003 | supporting | F-R2-002 | consumer, implementation, lifecycle_error | dependencies, lifecycle, state_errors, trust | known_current | packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/Providers/USwap/USwapMultiSwapProvider.swift |
| A-R2-S003-TESTS | R2-S003 | supporting | F-R2-005 | test | responsibility, state_errors, tests | known_current | Unstoppable/Tests/Modules/MultiSwap |
| X-R2-S003-PUBLIC | R2-S003 | rejected | F-R2-012 | counterexample | boundary, dependencies, trust | known_current | packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/IMultiSwapProvider.swift |
| A-R2-S004-TESTS | R2-S004 | kept | F-R2-005 | consumer, implementation, test | responsibility, state_errors, tests | known_current | Unstoppable/Tests/Modules/MultiSwap/SwapRequestRefundTests.swift |
| A-R2-S004-ANDROID | R2-S004 | supporting | F-R2-011 | consumer, contract, lifecycle_error | boundary, responsibility, state_errors, tests | known_current | app/src/main/java/io/horizontalsystems/swapapp/swap/api/SwapApiModels.kt |
| A-R2-S004-PACKAGE | R2-S004 | supporting | F-R2-006 | composition | boundary, dependencies, tests | known_current | packages/WalletCore/Package.swift |
| X-R2-S004-SERIALIZED | R2-S004 | rejected | F-R2-014 | counterexample | dependencies, tests | known_current | Unstoppable/Tests/Modules/MultiSwap/SwapProviderFactoryTests.swift |

## Evidence claims

| Fact | Rev | Load-bearing | Verdict | Accepted | Basis | Events | Location | Freshness | Claim |
|---|---:|:---:|---|:---:|---|---|---|---|---|
| F-R2-001 | 1 | yes | MATCH | yes | combined | E-0004, E-0005 | valid | known_current | The active UW iOS worktree, Gimle uw-ios-app index, and Palace git mount all represent commit 8a63bfda with zero reported lag. |
  - Serena: Serena activated the exact filesystem root /Users/ant013/Data/AI/paperclip/workspace/multi-swap-ios/Unstoppable.
  - rg: git rev-parse and canonical version/0.50 FETCH_HEAD both equal 8a63bfda.
  - Anchors: repository root; HEAD 8a63bfda; project uw-ios-app
| F-R2-002 | 1 | yes | MATCH | yes | serena+rg | E-0008, E-0011 | valid | known_current | USwapMultiSwapProvider is a wallet-coupled monolith and cannot itself be the guest boundary. |
  - Serena: Class spans lines 16-1286; init fields include Core.shared managers/storage, and rate/swap methods depend on wallet Token, destinations, account and nine builders.
  - rg: Exact current lines show NetworkManager plus Core.shared evmBlockchainManager, adapterManager and swapAssetStorage; /tokens, /rate, /swap and global-aware track are embedded in one file.
  - Anchors: packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/Providers/USwap/USwapMultiSwapProvider.swift:17
| F-R2-003 | 1 | yes | MATCH | yes | serena+rg | E-0013 | valid | known_current | The current NetworkManager Decodable extension is the repository analog for transport-then-typed-decoding behavior. |
  - Serena: The method calls fetchData with JSON content types then decoder.decode(T.self, from: data), preserving transport errors/cancellation.
  - rg: The exact method and multiple current call sites were found under WalletCore.
  - Anchors: packages/WalletCore/Sources/WalletCore/Extensions/NetworkManager.swift:6
| F-R2-004 | 1 | yes | MATCH | yes | serena+rg | n/a | valid | known_current | Unstoppable Wallet composes MultiSwap through the registered DefaultSwapProviderResolver, which constructs USwapMultiSwapProvider for known USwapProvider IDs. |
  - Serena: UnstoppableApp.initCore registers DefaultSwapProviderResolver before Core.initApp; the resolver constructs USwapMultiSwapProvider at its final branch.
  - rg: Current paths and exact registrations are present in app init and packages/WalletCore/Core/Factories/SwapProviderFactory.swift.
  - Anchors: Unstoppable/Unstoppable/App/UnstoppableApp.swift:38; packages/WalletCore/Sources/WalletCore/Core/Factories/SwapProviderFactory.swift:75
| F-R2-005 | 1 | yes | MATCH | yes | serena+rg | n/a | valid | known_current | Current regression-test style uses Swift Testing and directly observes provider registry and USwap track decoding behavior. |
  - Serena: SwapProviderFactoryTests uses @Test/#expect/#require; SwapRequestRefundTests decodes action-required and unknown USwap track fixtures.
  - rg: Both test files exist at HEAD and contain the named tests.
  - Anchors: Unstoppable/Tests/Modules/MultiSwap/SwapProviderFactoryTests.swift:9; Unstoppable/Tests/Modules/MultiSwap/SwapRequestRefundTests.swift:5
| F-R2-006 | 1 | yes | MATCH | yes | rg | n/a | valid | known_current | WalletCore currently exposes one monolithic library target and has no SwiftPM test target, so a dedicated guest target/test target is a real new package boundary. |
  - Serena: n/a
  - rg: Package.swift has one WalletCore library and one .target; targeted search finds no .testTarget.
  - Anchors: packages/WalletCore/Package.swift:6
| F-R2-007 | 1 | yes | MATCH | yes | serena+rg | E-0008 | valid | known_current | USwapTracker is a rejected guest-boundary counterexample because its delegated track path reads AppConfig, Core.shared debug state, and app-registered enrichment. |
  - Serena: USwapTracker only delegates to static provider track; that implementation reads AppConfig.showDevTools, Core.shared.localStorage and SwapTrackParametersFactory.
  - rg: Exact current lines 1332-1379 confirm the hidden global/app dependencies.
  - Anchors: packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/Providers/USwap/USwapMultiSwapProvider.swift:1332
| F-R2-008 | 1 | yes | MATCH | yes | serena+rg | n/a | valid | known_current | The only current factory/test family is the WalletCore package factory plus Unstoppable/Tests; historical app-level factory paths are absent. |
  - Serena: Serena resolves the package SwapProviderFactory and current app tests.
  - rg: git ls-tree at HEAD lists only packages/WalletCore/.../SwapProviderFactory.swift and Unstoppable/Tests/.../SwapProviderFactoryTests.swift.
  - Anchors: packages/WalletCore/Sources/WalletCore/Core/Factories/SwapProviderFactory.swift; Unstoppable/Tests/Modules/MultiSwap/SwapProviderFactoryTests.swift
| F-R2-009 | 1 | yes | CONTRADICTED | no | serena+rg | E-0012 | invalid | contradictory | Gimle search_graph's app-level SwapProviderFactory paths are current at indexed commit 8a63bfda. |
  - Serena: Serena resolves only the package factory and current test path.
  - rg: Both app-level paths are missing and absent from git ls-tree HEAD.
  - Anchors: missing Unstoppable/Unstoppable/Core/Factories/SwapProviderFactory.swift and UnstoppableWallet/UnstoppableWallet/Core/Factories/SwapProviderFactory.swift
| F-R2-010 | 1 | yes | MATCH | yes | rg | n/a | valid | known_current | HsToolKit 2.0.5 exposes public NetworkManager.fetchData with automatic Alamofire cancellation and typed ResponseError status/raw-data transport semantics. |
  - Serena: n/a
  - rg: Resolved checkout HEAD equals the 2.0.5 tag commit 8d56708a; source shows public fetchData, automaticallyCancelling serialization, ResponseError(statusCode,json,rawData), and explicit cancellation classification.
  - Anchors: HsToolKit.Swift@2.0.5 Sources/HsToolKit/NetworkManager.swift
| F-R2-011 | 1 | yes | MATCH | yes | rg | n/a | valid | known_current | Android's accountless source of truth uses five explicit USwap v2 endpoints, dynamic active-transfer providers, nullable wire DTOs, no signing/broadcast state, and preserves can... |
  - Serena: n/a
  - rg: Current Android HEAD defines GET providers/tokens and POST rate/swap/track; filter is case-insensitive transfer and suspended != true; quote 404 returns no routes; track cancellation rethrows and 409 maps NotStarted.
  - Anchors: Android swap/api/SwapApi.kt; SwapApiModels.kt; SwapTokenRepository.kt; SwapQuoteRepository.kt; SwapDepositRepository.kt
| F-R2-012 | 1 | yes | MATCH | yes | serena+rg | n/a | valid | known_current | IMultiSwapProvider is a rejected public guest seam because its contract imports MarketKit and SwiftUI, exposes wallet quote/view types, and its default validation reads Core.ins... |
  - Serena: Serena resolves the protocol and extension at current lines 5-45 with the same wallet/UI dependencies.
  - rg: Current source imports Combine, MarketKit and SwiftUI; methods require Token, MultiSwapQuote, SwapFinalQuote, Binding and AnyView; default implementation reads Core.instance localStorage.
  - Anchors: packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/IMultiSwapProvider.swift:6
| F-R2-013 | 1 | yes | MATCH | yes | serena+rg | n/a | valid | known_current | MultiSwapProviderManager is a lifecycle counterexample rather than the guest client skeleton because it is v1, cache/storage-owning, and starts an unstructured sync Task during ... |
  - Serena: Serena resolves injected NetworkManager but also LocalStorage, @PostPublished state and init-triggered sync.
  - rg: Current source has LocalStorage, one-hour cache timestamp, /v1/providers and Task launched from init.
  - Anchors: packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/MultiSwapProviderManager.swift:7
| F-R2-014 | 1 | yes | MATCH | yes | serena+rg | n/a | valid | known_current | Serialized registry suites are a rejected test pattern for stateless GuestUSwap contract tests; direct Swift Testing assertions and mock transport fixtures are the relevant patt... |
  - Serena: Serena resolves both current suites and confirms the global reset versus stateless fixture distinction.
  - rg: SwapProviderFactoryTests uses @Suite(.serialized) because it mutates a global resolver registry; SwapRequestRefundTests is non-serialized and directly asserts decoded response behavior.
  - Anchors: Unstoppable/Tests/Modules/MultiSwap/SwapProviderFactoryTests.swift:8; Unstoppable/Tests/Modules/MultiSwap/SwapRequestRefundTests.swift:5

## Adversarial decisions

- D-R2-001@3 ACCEPT: Transport and strict WalletCore projection resolutions are unchanged in final spec 7a191abc
- D-R2-002@3 ACCEPT: Fixture and cache resolutions are unchanged in final spec 7a191abc
- D-R2-003@3 ACCEPT: Independent adversarial resolutions are unchanged in final spec 7a191abc
- D-R2-004@2 ACCEPT: Final boundary analog family delta matrix and test plan remain coherent at spec 7a191abc
- D-R2-005@1 ACCEPT: Trailing-whitespace correction changes rendering only and introduces no design delta

## Verification and acceptance


## Bugs and limitations

### B-R2-001: Unsupported semantic source scope caused an empty first query

- Class/severity/confidence/status: caller_error / low / confirmed / workaround
- Tool/events/claims: palace.code.semantic_search / E-0007 / n/a
- Reproduction: semantic_search project=uw-ios-app source_scopes=[first_party] limit=8
- Expected: First-party UW symbols are searched
- Actual: Server reported project/dependency scope vocabulary and excluded all candidates
- Impact: No design evidence was obtained from E-0007
- Workaround: Repeat once with the server-reported project scope and retain this failed call in the report
- Anchors: palace.code.semantic_search payload source_scope_counts

### B-R2-002: Exact qualified name is treated as an ambiguous prefix

- Class/severity/confidence/status: confirmed_mcp_bug / medium / confirmed / workaround
- Tool/events/claims: palace.code.get_snippet_rich / E-0010 / n/a
- Reproduction: get_snippet_rich project=uw-ios-app qualified_name=WalletCore%20USwapMultiSwapProviderC
- Expected: Resolve the exact class symbol only
- Actual: ok=false; exact class and nested Provider enum are both returned as ambiguous matches
- Impact: Rich Gimle hydration cannot establish the class body or callers
- Workaround: Use Serena declarations/references plus targeted rg and keep Gimle only for current candidate discovery
- Anchors: packages/WalletCore/Sources/WalletCore/Modules/MultiSwap/Providers/USwap/USwapMultiSwapProvider.swift

### B-R2-003: Current uw-ios-app graph mixes removed factory paths with HEAD symbols

- Class/severity/confidence/status: stale_index / high / confirmed / workaround
- Tool/events/claims: palace.code.search_graph / E-0012 / n/a
- Reproduction: search_graph project=uw-ios-app name_pattern=SwapProviderFactory.* limit=20
- Expected: Only paths present at indexed_commit 8a63bfda are returned
- Actual: Payload included missing Unstoppable/Unstoppable/Core/Factories/SwapProviderFactory.swift and UnstoppableWallet/UnstoppableWallet/Core/Factories/SwapProviderFactory.swift
- Impact: Unverified composition analogs could point to removed app layers
- Workaround: Reject missing nodes and use Serena plus git ls-tree for packages/WalletCore and current test paths
- Anchors: git ls-tree -r HEAD; packages/WalletCore/Sources/WalletCore/Core/Factories/SwapProviderFactory.swift

## Interpretation

Contradicted or unverifiable Gimle evidence was not accepted as repository truth. A verified fallback does not erase the defect.
