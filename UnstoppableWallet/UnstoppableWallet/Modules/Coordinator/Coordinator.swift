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

    func hasRoute(at level: Int) -> Bool {
        level < routeStack.count
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
    }
}

extension Coordinator {
    func presentPurchases() {
        present { _ in
            PurchasesView()
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
}
