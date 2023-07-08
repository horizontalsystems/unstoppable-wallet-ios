import Foundation
import Combine
import HsExtensions

class CexWithdrawConfirmService {
    let cexAsset: CexAsset
    let network: CexWithdrawNetwork?
    let address: String
    let amount: Decimal
    private let provider: ICexProvider
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .idle
    private let confirmWithdrawSubject = PassthroughSubject<String, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    init(cexAsset: CexAsset, network: CexWithdrawNetwork?, address: String, amount: Decimal, provider: ICexProvider) {
        self.cexAsset = cexAsset
        self.network = network
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

        Task { [weak self, provider, cexAsset, network, address, amount] in
            do {
//                let id = try await provider.withdraw(id: cexAsset.id, network: network?.id, address: address, amount: amount)
                self?.confirmWithdrawSubject.send("1000") // TODO: Send "id"
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
