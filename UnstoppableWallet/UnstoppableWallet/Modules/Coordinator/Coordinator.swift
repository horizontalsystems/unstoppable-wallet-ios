import Combine
import Foundation
import MarketKit
import SwiftUI

class Coordinator: ObservableObject {
    static let shared = Coordinator()

    @Published private var routeStack: [Route] = []

    func present(type: RouteType = .sheet, @ViewBuilder content: @escaping (Binding<Bool>) -> some View, onDismiss: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.routeStack.append(Route(type: type, content: content, onDismiss: onDismiss))
        }
    }

    func route(at level: Int) -> Route? {
        guard level >= 0, level < routeStack.count else { return nil }
        return routeStack[level]
    }

    func hasSheet(at level: Int) -> Bool {
        level < routeStack.count && routeStack[level].type == .sheet
    }

    func hasBottomSheet(at level: Int) -> Bool {
        level < routeStack.count && routeStack[level].type == .bottomSheet
    }

    func hasAlert(at level: Int) -> Bool {
        level < routeStack.count && routeStack[level].type == .alert
    }

    func onRouteDismissed(at level: Int) {
        if level < routeStack.count {
            for route in routeStack[level...].reversed() {
                DispatchQueue.main.async {
                    route.onDismiss?()
                }
            }

            routeStack.removeSubrange(level...)
        }
    }
}

extension Coordinator {
    struct Route {
        let type: RouteType
        let contentBuilder: (Binding<Bool>) -> AnyView
        let onDismiss: (() -> Void)?

        init(type: RouteType, @ViewBuilder content: @escaping (Binding<Bool>) -> some View, onDismiss: (() -> Void)? = nil) {
            self.type = type
            contentBuilder = { isPresented in AnyView(content(isPresented)) }
            self.onDismiss = onDismiss
        }

        func content(isPresented: Binding<Bool>) -> AnyView {
            contentBuilder(isPresented)
        }
    }

    enum RouteType {
        case sheet
        case bottomSheet
        case alert
    }
}

extension Coordinator {
    func presentPurchase(page: StatPage, trigger: StatPremiumTrigger) {
        present { isPresented in
            PurchasesView(isPresented: isPresented)
        }

        stat(page: page, event: .openPremium(from: trigger))
    }

    func presentAfterPurchase(premiumFeature: PremiumFeature, page: StatPage, trigger: StatPremiumTrigger, @ViewBuilder content: @escaping (Binding<Bool>) -> some View, onDismiss: (() -> Void)? = nil, onPresent: (() -> Void)? = nil) {
        performAfterPurchase(premiumFeature: premiumFeature, page: page, trigger: trigger) {
            Coordinator.shared.present(content: content, onDismiss: onDismiss)
            onPresent?()
        }
    }

    func performAfterPurchase(premiumFeature: PremiumFeature, page: StatPage, trigger: StatPremiumTrigger, onPurchase: @escaping () -> Void) {
        if !Core.shared.purchaseManager.activated(premiumFeature) {
            present { isPresented in
                PurchasesView(isPresented: isPresented)
            } onDismiss: {
                if Core.shared.purchaseManager.activated(premiumFeature) {
                    onPurchase()
                }
            }

            stat(page: page, event: .openPremium(from: trigger))
        } else {
            onPurchase()
        }
    }

    func presentCoinPage(coin: Coin, page: StatPage, section: StatSection? = nil) {
        present { _ in
            CoinPageView(coin: coin)
        }
        stat(page: page, section: section, event: .openCoin(coinUid: coin.uid))
    }

    func presentAfterAcceptTerms(@ViewBuilder content: @escaping (Binding<Bool>) -> some View, onDismiss: (() -> Void)? = nil, onPresent: (() -> Void)? = nil) {
        let onAccept = {
            Coordinator.shared.present(content: content, onDismiss: onDismiss)
            onPresent?()
        }

        if Core.shared.termsManager.termsAccepted {
            onAccept()
        } else {
            Coordinator.shared.present { isPresented in
                TermsView(isPresented: isPresented, onAccept: onAccept)
            }
        }
    }

    func presentBalanceError(wallet: Wallet, state: AdapterState) {
        if !Core.shared.reachabilityManager.isReachable {
            HudHelper.instance.show(banner: .noInternet)
            return
        }

        guard case let .notSynced(error) = state else {
            return
        }

        present(type: .bottomSheet) { isPresented in
            BalanceErrorBottomView(wallet: wallet, error: error, isPresented: isPresented)
        }
    }

    func presentAfterUnlock(@ViewBuilder content: @escaping (Binding<Bool>) -> some View, onDismiss: (() -> Void)? = nil, onPresent: (() -> Void)? = nil) {
        performAfterUnlock {
            Coordinator.shared.present(content: content, onDismiss: onDismiss)
            onPresent?()
        }
    }

    func performAfterUnlock(onUnlock: @escaping () -> Void) {
        if Core.shared.passcodeManager.isPasscodeSet {
            Coordinator.shared.present { _ in
                ThemeNavigationStack {
                    ModuleUnlockView {
                        DispatchQueue.main.async {
                            onUnlock()
                        }
                    }
                }
            }
        } else {
            onUnlock()
        }
    }

    func present(url: URL?) {
        guard let url else {
            return
        }

        present { _ in
            SFSafariView(url: url).ignoresSafeArea()
        }
    }

    func present(info: InfoDescription) {
        present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                icon: .info,
                title: info.title,
                items: [
                    .text(text: info.description),
                ],
                buttons: [
                    .init(style: .yellow, title: "button.close".localized) {
                        isPresented.wrappedValue = false
                    },
                ],
                isPresented: isPresented
            )
        }
    }
}
