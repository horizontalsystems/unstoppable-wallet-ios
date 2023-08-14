import Combine
import Foundation
import MarketKit

class ReceiveViewModel {
    private let service: ReceiveService

    init(service: ReceiveService) {
        self.service = service
    }

}

extension ReceiveViewModel {

    func onSelect(fullCoin: FullCoin) {
        service.onSelect(fullCoin: fullCoin)
    }

    func onSelectExact(token: Token) {
        service.onSelectExact(token: token)
    }

    func onRestoreZcash(token: Token, height: Int?) {
        service.onRestoreZcash(token: token, height: height)
    }

}

extension ReceiveViewModel {

    var showTokenPublisher: AnyPublisher<Wallet, Never> {
        service.showTokenPublisher
    }

    var showDerivationSelectPublisher: AnyPublisher<[Wallet], Never> {
        service.showDerivationSelectPublisher
    }

    var showBitcoinCashCoinTypeSelectPublisher: AnyPublisher<[Wallet], Never> {
        service.showBitcoinCashCoinTypeSelectPublisher
    }

    var showZcashRestoreSelectPublisher: AnyPublisher<Token, Never> {
        service.showZcashRestoreSelectPublisher
    }

    var showBlockchainSelectPublisher: AnyPublisher<(FullCoin, AccountType), Never> {
        service.showBlockchainSelectPublisher
    }

}
