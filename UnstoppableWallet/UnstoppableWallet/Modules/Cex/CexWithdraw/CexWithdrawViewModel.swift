import Foundation
import RxSwift
import RxCocoa
import HsExtensions
import Combine
import CurrencyKit
import BigInt

class CexWithdrawViewModel {
    private var cancellables = Set<AnyCancellable>()
    private let service: CexWithdrawService
    private let coinService: CexCoinService

    @PostPublished private(set) var selectedNetwork: String
    @PostPublished private(set) var fee: FeeAmount?
    @PostPublished private(set) var amountCaution: Caution? = nil
    private let proceedSubject = PassthroughSubject<CexWithdrawModule.SendData, Never>()

    let networkViewItems: [NetworkViewItem]

    init(service: CexWithdrawService, coinService: CexCoinService) {
        self.service = service
        self.coinService = coinService
        self.selectedNetwork = service.selectedNetwork.networkName

        networkViewItems = service.networks.enumerated().map { index, network in
            NetworkViewItem(index: index, title: network.networkName, imageUrl: network.blockchain?.type.imageUrl, enabled: network.enabled)
        }

        subscribe(&cancellables, service.$amountError) { [weak self] in self?.sync(amountError: $0) }
        subscribe(&cancellables, service.$selectedNetwork) { [weak self] in self?.selectedNetwork = $0.networkName }
        subscribe(&cancellables, service.$fee) { [weak self] in self?.sync(fee: $0) }
        subscribe(&cancellables, service.$proceedSendData) { [weak self] in self?.proceed(sendData: $0) }

        sync(fee: service.fee)
    }

    private func proceed(sendData: CexWithdrawModule.SendData?) {
        if let sendData = sendData {
            proceedSubject.send(sendData)
        }
    }

    private func sync(fee: Decimal) {
        let feeAmountData = coinService.amountData(value: fee, sign: .plus)

        self.fee = FeeAmount(
            coinAmount: ValueFormatter.instance.formatFull(coinValue: feeAmountData.coinValue) ?? "n/a".localized,
            currencyAmount: feeAmountData.currencyValue.flatMap { ValueFormatter.instance.formatFull(currencyValue: $0) }
        )
    }

    private func sync(amountError: Error?) {
        var caution: Caution? = nil

        if let error = amountError {
            caution = Caution(text: error.smartDescription, type: .error)
        }

        amountCaution = caution
    }

}

extension CexWithdrawViewModel {

    var coinCode: String {
        service.cexAsset.coinCode
    }

    var coinImageUrl: String {
        service.cexAsset.coin?.imageUrl ?? ""
    }

    var selectedNetworkIndex: Int? {
        service.networks.firstIndex(where: { $0.id == service.selectedNetwork.id })
    }

    var proceedPublisher: AnyPublisher<CexWithdrawModule.SendData, Never> {
        proceedSubject.eraseToAnyPublisher()
    }

    func onSelectNetwork(index: Int) {
        service.setSelectNetwork(index: index)
    }

    func onChange(feeFromAmount: Bool) {
        service.set(feeFromAmount: feeFromAmount)
    }

    func didTapProceed() {
        service.proceed()
    }

}

extension CexWithdrawViewModel {

    struct FeeAmount {
        let coinAmount: String
        let currencyAmount: String?
    }

    struct NetworkViewItem {
        let index: Int
        let title: String
        let imageUrl: String?
        let enabled: Bool
    }

}
