import Combine
import Foundation
import MarketKit
import SwiftUI

class Coordinator: ObservableObject {
    static let shared = Coordinator()

    private var routeStack: [Route] = []

    private var levelPublishers: [Int: PassthroughSubject<RouteType?, Never>] = [:]

    func publisher(for level: Int) -> AnyPublisher<RouteType?, Never> {
        if levelPublishers[level] == nil {
            levelPublishers[level] = PassthroughSubject<RouteType?, Never>()
        }
        return levelPublishers[level]!.eraseToAnyPublisher()
    }

    func present(type: RouteType = .sheet, @ViewBuilder content: @escaping (Binding<Bool>) -> some View, onDismiss: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            let route = Route(type: type, content: content, onDismiss: onDismiss)
            routeStack.append(route)
            let newLevel = routeStack.count - 1
            levelPublishers[newLevel]?.send(type)
        }
    }

    func route(at level: Int) -> Route? {
        guard level >= 0, level < routeStack.count else {
            return nil
        }
        return routeStack[level]
    }

    func onRouteDismissed(at level: Int) {
        guard level >= 0, level < routeStack.count else {
            return
        }

        let dismissedCount = routeStack.count - level

        for route in routeStack[level...].reversed() {
            DispatchQueue.main.async {
                route.onDismiss?()
            }
        }

        routeStack.removeSubrange(level...)

        for lvl in level ..< (level + dismissedCount) {
            let newType: RouteType? = lvl < routeStack.count ? routeStack[lvl].type : nil
            levelPublishers[lvl]?.send(newType)
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

    enum RouteType: Equatable {
        case sheet
        case bottomSheet
        case alert
    }
}

extension Coordinator {
    func presentPurchase(premiumFeature: PremiumFeature? = nil, page: StatPage, trigger: StatPremiumTrigger) {
        present(type: premiumFeature != nil ? .bottomSheet : .sheet) { isPresented in
            if let premiumFeature {
                PremiumFeaturesWrapper(isPresented: isPresented, feature: premiumFeature)
            } else {
                PurchasesView(isPresented: isPresented)
            }
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
            present(type: .bottomSheet) { isPresented in
                PremiumFeaturesWrapper(isPresented: isPresented, feature: premiumFeature)
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

        if Core.shared.termsManager.state.allAccepted {
            onAccept()
        } else {
            Coordinator.shared.present { isPresented in
                TermsView(isPresented: isPresented, onAccept: onAccept)
            }
        }
    }

    func presentBalanceError(wallet: Wallet, state: AdapterState, showNotReachable: Bool = true) {
        if !Core.shared.reachabilityManager.isReachable {
            if showNotReachable {
                HudHelper.instance.show(banner: .noInternet)
            }

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
                items: [
                    .title(icon: ThemeImage.book, title: info.title),
                    .text(text: info.description),
                    .buttonGroup(.init(buttons: [
                        .init(style: .gray, title: "button.understood".localized) {
                            isPresented.wrappedValue = false
                        },
                    ])),
                ],
            )
        }
    }
}
