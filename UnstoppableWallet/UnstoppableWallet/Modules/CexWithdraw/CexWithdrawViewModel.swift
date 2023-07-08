import RxSwift
import RxCocoa
import HsExtensions
import Combine

class CexWithdrawViewModel {
    private var cancellables = Set<AnyCancellable>()
    private let service: CexWithdrawService

    @PostPublished private(set) var selectedNetwork: String? = nil
    @PostPublished private(set) var proceedEnable: Bool = false
    @PostPublished private(set) var amountCaution: Caution? = nil
    private let proceedSubject = PassthroughSubject<CexWithdrawModule.SendData, Never>()

    init(service: CexWithdrawService) {
        self.service = service

        subscribe(&cancellables, service.$state) { [weak self] in self?.sync(state: $0) }
        subscribe(&cancellables, service.$amountError) { [weak self] in self?.sync(amountError: $0) }
        subscribe(&cancellables, service.$selectedNetwork) { [weak self] in self?.selectedNetwork = $0?.networkName }

        self.selectedNetwork = service.selectedNetwork?.networkName
    }

    private func sync(state: CexWithdrawService.State) {
        if case .ready = state {
            proceedEnable = true
        } else {
            proceedEnable = false
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
        service.networks.firstIndex(where: { $0.id == service.selectedNetwork?.id })
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

    func didTapProceed() {
        guard case let .ready(sendData) = service.state else {
            return
        }

        proceedSubject.send(sendData)
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
