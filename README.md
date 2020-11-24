# Unstoppable Wallet

We dream of a world… A world where private property is untouchable and market access is unconditional.

That obsession led us to engineer a crypto wallet that is equally open to all, lives online forever and unconditionally protects your assets.

It is fully peer-to-peer and works without any centrally managed servers. It can't be stopped, blocked or taken down.

Such approach enables the wallet to operate anywhere and remain censorship-resistant. Only the user is in control of the money.

More at [https://unstoppable.money](https://unstoppable.money)

## Download

[https://itunes.apple.com/us/app/bank-wallet/id1447619907?ls=1&mt=8](https://itunes.apple.com/us/app/bank-wallet/id1447619907?ls=1&mt=8)

## Installation

1. `git clone git@github.com:horizontalsystems/unstoppable-wallet-ios.git`

2. You need to have `Development.xcconfig` file for Debug configuration and `Production.xcconfig` file for Release in `UnstoppableWallet/UnstoppableWallet/Configuration`.
You can use sample configurations in `.template.xcconfig` files.

3. Install Zcash library dependencies

```
$ curl https://sh.rustup.rs -sSf | sh
```

* select `Default`

```
$ cargo install cargo-lipo
$ rustup target add aarch64-apple-ios x86_64-apple-ios
```

```
$ brew install sourcery
```

4. Open in Xcode and run.
 

## License

This wallet is open source and available under the terms of the MIT License.
