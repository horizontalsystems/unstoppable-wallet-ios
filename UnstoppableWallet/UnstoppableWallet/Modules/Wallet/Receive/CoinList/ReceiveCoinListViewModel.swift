import Combine
import Foundation
import MarketKit

class ReceiveCoinListViewModel: ObservableObject {
    let account: Account
    private let service: ReceiveCoinListService
    private var cancellables = Set<AnyCancellable>()

    @Published var viewItems = [ViewItem]()
    @Published var enableTokenWithBirthday: Token?
    @Published var pushCoinUid: String?
    @Published var searchText: String = ""

    init(account: Account, service: ReceiveCoinListService) {
        self.account = account
        self.service = service

        service.$coins
            .receive(on: DispatchQueue.main)
            .sink { [weak self] coins in
                self?.sync(coins: coins)
            }
            .store(in: &cancellables)

        $searchText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.apply(filter: text)
            }
            .store(in: &cancellables)

        sync(coins: service.coins)
    }

    private func sync(coins: [FullCoin]) {
        viewItems = coins.map { fullCoin -> ViewItem in
            ViewItem(uid: fullCoin.coin.uid, coin: fullCoin.coin, title: fullCoin.coin.code, description: fullCoin.coin.name)
        }
    }
}

extension ReceiveCoinListViewModel {
    func apply(filter: String?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.service.set(filter: filter?.trimmingCharacters(in: .whitespaces) ?? "")
        }
    }

    func handleAfterEnable(uid: String, _ block: (FullCoin) -> Void) {
        guard let fullCoin = service.fullCoin(uid: uid) else {
            return
        }

        let eligibleTokens = fullCoin.tokens.filter { account.type.supports(token: $0) }

        // Check if need to enable token with Settings
        switch eligibleTokens.first?.blockchainType {
        case .zcash, .monero:
            if let token = eligibleTokens.first, !ReceiveModule.isEnabled(token: token) {
                enableTokenWithBirthday = eligibleTokens.first
                return
            }
        default: ()
        }

        block(fullCoin)
    }

    func createZcashWallet(token: Token, height: Int?) {
        service.onRestoreWithBirthdayHeight(account: account, token: token, height: height)
        pushCoinUid = token.coin.uid
    }

    func fullCoin(uid: String) -> FullCoin? {
        service.fullCoin(uid: uid)
    }
}

extension ReceiveCoinListViewModel {
    struct ViewItem: Hashable, Identifiable {
        let uid: String
        let coin: Coin?
        let title: String
        let description: String

        var id: String { uid }
    }
}
