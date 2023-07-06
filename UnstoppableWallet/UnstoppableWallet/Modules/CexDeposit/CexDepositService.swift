import Combine
import HsExtensions

class CexDepositService {
    let cexAsset: CexAsset
    let network: CexDepositNetwork?
    private let provider: ICexProvider
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .loading

    init(cexAsset: CexAsset, network: CexDepositNetwork?, provider: ICexProvider) {
        self.cexAsset = cexAsset
        self.network = network
        self.provider = provider

        load()
    }

    private func load() {
        state = .loading

        Task { [weak self, provider, cexAsset, network] in
            do {
                let (address, memo) = try await provider.deposit(id: cexAsset.id, network: network?.id)
                self?.state = .loaded(address: address, memo: memo)
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
        case loaded(address: String, memo: String?)
        case failed
    }

}
