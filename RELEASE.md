# Unstoppable Wallet Release

This document describes the release process for `Unstoppable` app.

### 1. Prepare dependent libraries

#### 1.1. Update Checkpoints

Update `Checkpoints` package in order to apply latest checkpoints for `Bitcoin`, `BitcoinCash`, `Litecoin` and `Dash` blockchains.

#### 1.2. Update Coins Dump

Update `MarketKit.Swift` package in order to sync the latest state of backend.

### 2. Transfer Code to Production Branch

Merge `version` branch into `master` branch. After this `Github Actions` will build release version and upload it to `TestFlight`.

### 3. Prepare New Development Branch

* Create new `version` branch
* Increase app version in project
* Update all packages to latest versions and apply any changes if required

### 5. Prepare Release in GitHub Repository

* Create tag for current version
* Create `Release` and add changelog
* Attach `ipa` file to release
