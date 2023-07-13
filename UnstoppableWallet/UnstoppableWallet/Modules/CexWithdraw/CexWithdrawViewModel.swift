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
    @PostPublished private(set) var fee: AmountData
    @PostPublished private(set) var amountCaution: Caution? = nil
    private let proceedSubject = PassthroughSubject<CexWithdrawModule.SendData, Never>()

    init(service: CexWithdrawService, coinService: CexCoinService) {
        self.service = service
        self.coinService = coinService
        self.selectedNetwork = service.selectedNetwork.networkName
        self.fee = coinService.amountData(value: service.fee, sign: .plus)

        subscribe(&cancellables, service.$amountError) { [weak self] in self?.sync(amountError: $0) }
        subscribe(&cancellables, service.$selectedNetwork) { [weak self] in self?.selectedNetwork = $0.networkName }
        subscribe(&cancellables, service.$fee) { [weak self] in self?.fee = coinService.amountData(value: $0, sign: .plus) }
        subscribe(&cancellables, service.$proceedSendData) { [weak self] in self?.proceed(sendData: $0) }
    }

    private func proceed(sendData: CexWithdrawModule.SendData?) {
        if let sendData = sendData {
            proceedSubject.send(sendData)
        }
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

    var placeholderImageName: String {
        service.cexAsset.placeholderImageName
    }

    var selectedNetworkIndex: Int? {
        service.networks.firstIndex(where: { $0.id == service.selectedNetwork.id })
    }

    var networkViewItems: [NetworkViewItem] {
        service.networks.enumerated().map { index, network in
            NetworkViewItem(index: index, title: network.networkName, imageUrl: network.blockchain?.type.imageUrl, enabled: network.enabled)
        }
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

    struct NetworkViewItem {
        let index: Int
        let title: String
        let imageUrl: String?
        let enabled: Bool
    }

}
