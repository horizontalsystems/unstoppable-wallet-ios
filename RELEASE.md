# Unstoppable Wallet Release

This document describes the release process for `Unstoppable` app.

### 1. Update Checkpoints

* `BitcoinKit.swift`
* `BitcoinCashKit.swift`
* `LitecoinKit.swift`
* `DashKit.swift`

### 2. Release All Dependencies

The following dependency pods should be released if there were any changes in them:

* https://github.com/horizontalsystems/bitcoin-kit-ios
* https://github.com/horizontalsystems/ethereum-kit-ios
* https://github.com/horizontalsystems/binance-chain-kit-ios
* https://github.com/horizontalsystems/xrates-kit-ios
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

Merge `version` branch into `master` branch

### 4. Prepare New Development Branch

* create new `version` branch

```
$ git branch version/0.1
```

* Increase app version in project

### 5. Upload Build to App Store

* Apply release credentials to `Production.xcconfig`
* Check validity of URLs set for `guides_index_url` and `faq_index_url` parameters in `Production.xcconfig`
* Build and upload to `ITunesConnect`

### 6. Prepare Release in GitHub Repository

* Create tag for current version
* Create `Release` and add changelog
* Attach `ipa` file to release
