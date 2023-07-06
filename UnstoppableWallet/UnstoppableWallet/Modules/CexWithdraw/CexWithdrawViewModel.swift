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

    private let networks: [CexWithdrawNetwork]
    private var selectedNetworkIndex: Int = 0

    init(service: CexWithdrawService) {
        self.service = service
        networks = service.cexAsset.withdrawNetworks

        subscribe(&cancellables, service.$state) { [weak self] in self?.sync(state: $0) }
        subscribe(&cancellables, service.$amountError) { [weak self] in self?.sync(amountError: $0) }
        subscribe(&cancellables, networkService.$selectedNetwork) { [weak self] in self?.selectedNetwork = $0?.networkName }
        selectedNetwork = networkService.selectedNetwork?.networkName
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

    var networksList: [SelectorModule.ViewItem] {
        networks.enumerated().map { index, network in
            SelectorModule.ViewItem(title: network.networkName, selected: index == selectedNetworkIndex)
        }
    }

    var networkService: CexWithdrawNetworkSelectService {
        service.networkService
    }

    var proceedPublisher: AnyPublisher<CexWithdrawModule.SendData, Never> {
        proceedSubject.eraseToAnyPublisher()
    }

    func onSelectNetwork(_ index: Int) {
        selectedNetworkIndex = index
    }

    func didTapProceed() {
        guard case let .ready(sendData) = service.state else {
            return
        }

        proceedSubject.send(sendData)
    }

}
