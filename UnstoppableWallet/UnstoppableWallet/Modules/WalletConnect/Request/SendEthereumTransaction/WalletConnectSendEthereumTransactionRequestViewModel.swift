import RxSwift
import RxRelay
import RxCocoa
import WalletConnect
import CurrencyKit
import BigInt

class WalletConnectSendEthereumTransactionRequestViewModel {
    private let service: WalletConnectSendEthereumTransactionRequestService
    private let coinService: EthereumCoinService

    private let disposeBag = DisposeBag()

    let amountData: AmountData
    let viewItems: [WalletConnectRequestViewItem]

    private let approveRelay = PublishRelay<Data>()

    init(service: WalletConnectSendEthereumTransactionRequestService, coinService: EthereumCoinService) {
        self.service = service
        self.coinService = coinService

        amountData = coinService.amountData(value: service.transactionData.value ?? 0)

        var viewItems = [WalletConnectRequestViewItem]()

        if let to = service.transactionData.to {
            viewItems.append(.to(value: to.eip55))
        }

        viewItems.append(.input(value: service.transactionData.input.toHexString()))

        self.viewItems = viewItems

        service.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] state in
                    self?.sync(state: state)
                })
                .disposed(by: disposeBag)

        sync(state: service.state)
    }

    private func sync(state: WalletConnectSendEthereumTransactionRequestService.State) {
        switch state {
        case .ready:
            () // todo: enable buttons
        case .notReady:
            () // todo: handle errors
        }
    }

}

extension WalletConnectSendEthereumTransactionRequestViewModel: IWalletConnectRequestViewModel {

    var approveSignal: Signal<Data> {
        approveRelay.asSignal()
    }

    func approve() {
        approveRelay.accept(Data(repeating: 1, count: 4))
    }

}
