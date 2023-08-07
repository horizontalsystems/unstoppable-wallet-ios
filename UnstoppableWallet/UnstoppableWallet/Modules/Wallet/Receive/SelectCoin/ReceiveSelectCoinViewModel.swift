import Combine
import Foundation
import MarketKit

class ReceiveSelectCoinViewModel {
    private let service: ReceiveSelectCoinService
    private var cancellables = Set<AnyCancellable>()

    @Published var viewItems = [ViewItem]()

    init(service: ReceiveSelectCoinService) {
        self.service = service

        service.$coins
                .sink { [weak self] coins in
                    self?.sync(coins: coins)
                }
                .store(in: &cancellables)

        sync(coins: service.coins)
    }

    private func sync(coins: [FullCoin]) {
        viewItems = coins.map { fullCoin -> ViewItem in
            ViewItem(uid: fullCoin.coin.uid, imageUrl: fullCoin.coin.imageUrl, title: fullCoin.coin.code, description: fullCoin.coin.name)
        }
    }

}

extension ReceiveSelectCoinViewModel {

    func apply(filter: String?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.service.set(filter: filter?.trimmingCharacters(in: .whitespaces) ?? "")
        }
    }

    func fullCoin(uid: String) -> FullCoin? {
        service.fullCoin(uid: uid)
    }

}

extension ReceiveSelectCoinViewModel {

    struct ViewItem {
        let uid: String
        let imageUrl: String?
        let title: String
        let description: String
    }

}
