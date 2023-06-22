import Combine
import HsExtensions

class CexDepositService {
    let cexAsset: CexAsset
    let cexNetwork: CexNetwork
    private let provider: ICexProvider
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .loading

    init(cexAsset: CexAsset, cexNetwork: CexNetwork, provider: ICexProvider) {
        self.cexAsset = cexAsset
        self.cexNetwork = cexNetwork
        self.provider = provider

        load()
    }

    private func load() {
        state = .loading

        Task { [weak self, provider, cexAsset, cexNetwork] in
            do {
                let address = try await provider.deposit(id: cexAsset.id, network: cexNetwork.network)
                self?.state = .loaded(address: address)
            } catch {
                self?.state = .failed
            }
        }.store(in: &tasks)
    }

}

extension CexDepositService {

    func reload() {
        load()
    }

}

extension CexDepositService {

    enum State {
        case loading
        case loaded(address: String)
        case failed
    }

}
