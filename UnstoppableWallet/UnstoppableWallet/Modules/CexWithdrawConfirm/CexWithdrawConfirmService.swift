import Foundation
import Combine
import HsExtensions

class CexWithdrawConfirmService {
    let cexAsset: CexAsset
    let cexNetwork: CexNetwork?
    let address: String
    let amount: Decimal
    private let provider: ICexProvider
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .idle
    private let confirmWithdrawSubject = PassthroughSubject<String, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    init(cexAsset: CexAsset, cexNetwork: CexNetwork?, address: String, amount: Decimal, provider: ICexProvider) {
        self.cexAsset = cexAsset
        self.cexNetwork = cexNetwork
        self.address = address
        self.amount = amount
        self.provider = provider
    }

}

extension CexWithdrawConfirmService {

    var confirmWithdrawPublisher: AnyPublisher<String, Never> {
        confirmWithdrawSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func withdraw() {
        tasks = Set()

        state = .loading

        Task { [weak self, provider, cexAsset, cexNetwork, address, amount] in
            do {
                let id = try await provider.withdraw(id: cexAsset.id, network: cexNetwork?.network, address: address, amount: amount)
                self?.confirmWithdrawSubject.send(id)
            } catch {
                self?.errorSubject.send(error)
            }

            self?.state = .idle
        }.store(in: &tasks)
    }

}

extension CexWithdrawConfirmService {

    enum State {
        case idle
        case loading
    }

}
