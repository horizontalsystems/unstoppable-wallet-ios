# E2E build

> This page states what the E2E build of the iOS app is and what its flag changes. It is the build the Maestro flows run on, and the counterpart of Android's `e2e` build type.

## The build

The E2E build is the Development app with an E2E flag. It has its own configuration, `Debug-E2E`, beside `Debug-Dev` and `Debug-Prod`, and a scheme of its own, `E2E`. The configuration has no Release twin: no lane builds for a simulator, and the flows run on one. It shares Development's bundle id and display name, extensions included, so on a device or a simulator it replaces the Development app.

The build sets the flag, and a run never does. No launch argument or environment value turns another build into E2E behaviour, so the broadcast stays a gate whatever share of the work is automated.

## What the flag changes

Apart from what the flag changes, the E2E build behaves like the real app, because support videos are recorded on it, and a change that would make it differ is weighed against that.

- Sending stops at the confirmation. The confirmation shows as usual, and confirming it is refused before anything is signed. The user sees the error "Broadcasting is disabled in E2E builds": on a send screen as the "Unexpected Error" bottom sheet with its Copy Error button, on the WalletConnect request sheet as an error banner.
- The automatic rate-app prompt is off. The "Rate us" row in the settings works as in the real app.
- The restore-phrase field, the backup and restore passphrase fields and the watch field are not prefilled, whatever `DEFAULT_WORDS`, `DEFAULT_PASSPHRASE` and `DEFAULT_WATCH_ADDRESS` hold in `Config.xcconfig`. Development keeps its prefills.

The flag leaves the device-passcode gate alone, and a simulator with Face ID enrolled satisfies it. It leaves [test identifiers](test-identifiers.md) alone too, which are on in every build.

The flag's effects grow with the stations that need them, deterministic screens for screenshot comparison among them, and no second flag is made.

## Building it

The build for one simulator, by its id, is one command, run from the repository root and the counterpart of Android's gradle task `assembleCiE2e`:

```
xcodebuild -workspace Wallet.xcworkspace -scheme E2E -configuration Debug-E2E -destination 'platform=iOS Simulator,id=<udid>' build
```

The build is for the architecture of the simulator the destination names. `MoneroZano.xcframework`, the Monero kit's binary, has only an arm64 simulator slice, so the E2E build needs an Apple silicon Mac. The generic simulator destination also builds x86_64, and that link fails.

The build goes to Xcode's default derived data, and the app is `Unstoppable.app` in the folder that `BUILT_PRODUCTS_DIR` names. That value comes from the same command with `-showBuildSettings` in place of `build`:

```
xcodebuild -workspace Wallet.xcworkspace -scheme E2E -configuration Debug-E2E -destination 'platform=iOS Simulator,id=<udid>' -showBuildSettings | grep -m1 ' BUILT_PRODUCTS_DIR'
```

## Running it

A funded test account is restored by the flow from an environment variable; Android's is `MAESTRO_E2E_DUST_MNEMONIC`. Its mnemonic stays out of every repository, spec, doc, plan, report and flow, and out of a command's arguments, and it is never printed to the console. Every secret reaches a run through an environment variable. The phrase variable is set only for a run of the flows that restore the funded account, and it is not kept in the shell's environment for other runs. Maestro writes every `MAESTRO_*` environment variable into each flow's `commands.json`, so a run with the phrase set holds it in plain text in its output. That run's `commands.json` and `maestro.log` are deleted after it. The simulator's logs and the restored wallet on the test simulator are a local by-product and need no sweep, filter or wipe, like the debug words in `Config.xcconfig`. The on-chain tests, which need that account and the network, are a class of their own beside the journey and the feature tests.

A history flow reads a third-party provider, Etherscan, through the key the build carries in `Config.xcconfig`, so a run needs a key whose daily quota no one else exhausts. Today the key is shared, and its quota ran out during a run: the history then showed as empty.
