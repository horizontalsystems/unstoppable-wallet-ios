import MarketKit
import RxCocoa
import RxRelay
import RxSwift
import UIKit

class BalanceErrorViewModel {
    private let service: BalanceErrorService

    private let openBtcBlockchainRelay = PublishRelay<Blockchain>()
    private let openEvmBlockchainRelay = PublishRelay<Blockchain>()
    private let finishRelay = PublishRelay<Void>()

    init(service: BalanceErrorService) {
        self.service = service
    }
}

extension BalanceErrorViewModel {
    var openBtcBlockchainSignal: Signal<Blockchain> {
        openBtcBlockchainRelay.asSignal()
    }

    var openEvmBlockchainSignal: Signal<Blockchain> {
        openEvmBlockchainRelay.asSignal()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    var coinTitle: String {
        service.coinName
    }

    var changeSourceVisible: Bool {
        service.isSourceChangeable
    }

    var errorString: String {
        service.errorString
    }

    func onTapRetry() {
        service.refreshWallet()
        finishRelay.accept(())
    }

    func onTapChangeSource() {
        guard let item = service.item else {
            finishRelay.accept(())
            return
        }

        switch item {
        case let .btc(blockchain):
            openBtcBlockchainRelay.accept(blockchain)
        case let .evm(blockchain):
            openEvmBlockchainRelay.accept(blockchain)
        }
    }
}
