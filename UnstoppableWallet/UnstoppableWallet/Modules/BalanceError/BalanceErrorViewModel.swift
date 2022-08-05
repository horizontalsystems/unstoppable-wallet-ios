import UIKit
import RxSwift
import RxRelay
import RxCocoa
import MarketKit

class BalanceErrorViewModel {
    private let service: BalanceErrorService

    private let openBtcBlockchainRelay = PublishRelay<Blockchain>()
    private let openEvmBlockchainRelay = PublishRelay<Blockchain>()
    private let finishRelay = PublishRelay<()>()

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

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var coinTitle: String {
        service.coinName
    }

    var changeSourceVisible: Bool {
        service.isSourceChangeable
    }

    var email: String {
        service.contactEmail
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
        case .btc(let blockchain):
            openBtcBlockchainRelay.accept(blockchain)
        case .evm(let blockchain):
            openEvmBlockchainRelay.accept(blockchain)
        }
    }

}
