# Unstoppable Wallet Release

This document describes the release process for `Unstoppable` app.

### 1. Prepare dependent libraries

#### 1.1. Update Checkpoints

* `BitcoinKit.swift`
* `BitcoinCashKit.swift`
* `LitecoinKit.swift`
* `DashKit.swift`

#### 1.2. Update coins dump in `MarketKit`

Initial coins dump `json` file should be updated to latest state of backend.

### 2. Release All Dependencies

The following dependency pods should be released if there were any changes in them:

* https://github.com/horizontalsystems/bitcoin-kit-ios
* https://github.com/horizontalsystems/ethereum-kit-ios
* https://github.com/horizontalsystems/binance-chain-kit-ios
* https://github.com/horizontalsystems/market-kit-ios
* https://github.com/horizontalsystems/blockchain-fee-rate-kit-ios

#### 2.1. Release pod if required

* Change version in `Podspec` according to `Latest Version` section in `CHANGELOG.md`.
* Create new version section in `CHANGELOG.md` and transfer all changelogs from `Latest Version` there.
* Clear `Latest Version` section in `CHANGELOG.md`.
* Commit and merge changes to `master` branch
* Create tag for new version
* Push pod to `Cocoapods`

#### 2.2. Update released pods in `Podfile` in application

```
$ pod update PodNameHere
```

### 3. Transfer Code to Production Branch

Merge `version` branch into `master` branch. After this `Github Actions` will build release version and upload it to `TestFlight`.

### 4. Prepare New Development Branch

* create new `version` branch

```
$ git branch version/0.1
```

* Increase app version in project

### 5. Prepare Release in GitHub Repository

* Create tag for current version
* Create `Release` and add changelog
* Attach `ipa` file to release
