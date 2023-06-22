import Combine

class CexDepositViewModel {
    private let service: CexDepositService
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var spinnerVisible: Bool = false
    @Published private(set) var errorVisible: Bool = false
    @Published private(set) var address: String?

    init(service: CexDepositService) {
        self.service = service

        service.$state
                .sink { [weak self] in self?.sync(state: $0) }
                .store(in: &cancellables)

        sync(state: service.state)
    }

    private func sync(state: CexDepositService.State) {
        switch state {
        case .loading:
            spinnerVisible = true
            errorVisible = false
            address = nil
        case .loaded(let address):
            spinnerVisible = false
            errorVisible = false
            self.address = address
        case .failed:
            spinnerVisible = false
            errorVisible = true
            address = nil
        }
    }

}

extension CexDepositViewModel {

    var coinCode: String {
        service.cexAsset.coinCode
    }

    var networkName: String {
        service.cexNetwork.networkName
    }

    func onTapRetry() {
        service.reload()
    }

}
