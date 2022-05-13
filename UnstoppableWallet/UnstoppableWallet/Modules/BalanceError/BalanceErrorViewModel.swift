import UIKit
import RxSwift
import RxRelay
import RxCocoa

class BalanceErrorViewModel {
    private let service: BalanceErrorService

    private let openBtcBlockchainRelay = PublishRelay<BtcBlockchain>()
    private let openEvmBlockchainRelay = PublishRelay<EvmBlockchain>()
    private let finishRelay = PublishRelay<()>()

    init(service: BalanceErrorService) {
        self.service = service
    }

}

extension BalanceErrorViewModel {

    var openBtcBlockchainSignal: Signal<BtcBlockchain> {
        openBtcBlockchainRelay.asSignal()
    }

    var openEvmBlockchainSignal: Signal<EvmBlockchain> {
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
        guard let blockchain = service.blockchain else {
            finishRelay.accept(())
            return
        }

        switch blockchain {
        case .btc(let blockchain):
            openBtcBlockchainRelay.accept(blockchain)
        case .evm(let blockchain):
            openEvmBlockchainRelay.accept(blockchain)
        }
    }

}
