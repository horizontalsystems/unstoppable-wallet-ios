import MarketKit
import StellarKit
import SwiftUI

// The trustline pre-swap step (the EIP-20 approve analogue), keyed on the buy token being a Stellar
// classic asset, never on a provider: every route delivering such an asset to the user's own account
// gets it. The recipient is ignored; the server still pre-flights the trustline at commit.
enum StellarActivationHelper {
    // Non-nil when tokenOut is a Stellar classic asset the active account holds no trustline for.
    // An unsynced/unknown account does NOT block (nil): the server pre-flight at commit remains the
    // authority; this only drives the inline button UX.
    static func activationRequiredAsset(tokenOut: Token) -> StellarKit.Asset? {
        guard case let .stellar(code, issuer) = tokenOut.type else {
            return nil // native XLM needs no trustline
        }
        guard let account = Core.shared.stellarKitManager.stellarKit?.account else {
            return nil
        }
        let asset = StellarKit.Asset.asset(code: code, issuer: issuer)
        return account.assetBalanceMap[asset] == nil ? asset : nil
    }

    static func buttonState(asset: StellarKit.Asset) -> MultiSwapButtonState {
        .init(
            title: "swap.activate_asset".localized(asset.code),
            preSwapStep: ActivationStep(asset: asset)
        )
    }

    // Trustline activation as an inline pre-swap step: tapping the button presents the standard send
    // confirmation for a `changeTrust` op (fee + slide to confirm), and on success the quotes re-sync
    // so the button flips to "Next". Reuses the exact SendData the Receive screen's activation uses.
    // Returns nil when `step` is not an ActivationStep.
    static func preSwapView(step: MultiSwapPreSwapStep, tokenOut: Token, isPresented: Binding<Bool>, onSuccess: @escaping () -> Void) -> AnyView? {
        guard let step = step as? ActivationStep else {
            return nil
        }

        let sendData = SendData.stellar(
            data: .changeTrust(asset: step.asset, limit: StellarAdapter.maxValue),
            token: tokenOut,
            memo: nil
        )

        let view = RegularSendView(sendData: sendData) {
            // Horizon's submit is synchronous (returns after ledger inclusion), so the trustline
            // exists on-chain here — but StellarKit's cached account doesn't refresh on send.
            // ORDER MATTERS: keep the sheet up (the slide button sits in its success state) and
            // sync-poll the kit until the trustline shows (≤5s) BEFORE dismissing + re-quoting.
            // Dismissing first paraded every intermediate state — the stale "Activate" button,
            // the HUD, then a full-screen requote — as rapid UI flashes. This way the page
            // revealed on dismissal is already re-quoting and resolves straight to "Next".
            Task {
                let kit = Core.shared.stellarKitManager.stellarKit
                for _ in 0 ..< 10 {
                    kit?.sync()
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if kit?.account?.assetBalanceMap[step.asset] != nil {
                        break
                    }
                }
                await MainActor.run {
                    HudHelper.instance.show(banner: .sent)
                    onSuccess()
                    isPresented.wrappedValue = false
                }
            }
        }

        return AnyView(ThemeNavigationStack { view })
    }

    // Mirrors MultiSwapAllowanceHelper.UnlockStep: identifies the trustline-activation pre-swap
    // step and carries the asset to activate into preSwapView.
    final class ActivationStep: MultiSwapPreSwapStep {
        let asset: StellarKit.Asset

        init(asset: StellarKit.Asset) {
            self.asset = asset
        }

        override var id: String {
            "stellar_trustline_activation"
        }
    }
}
