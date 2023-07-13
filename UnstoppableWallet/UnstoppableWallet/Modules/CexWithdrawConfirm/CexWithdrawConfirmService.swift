import Foundation
import Combine
import HsExtensions

class CexWithdrawConfirmService {
    let cexAsset: CexAsset
    let network: CexWithdrawNetwork?
    let address: String
    let amount: Decimal
    let feeFromAmount: Bool
    let fee: Decimal
    private let provider: ICexProvider
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .idle
    private let confirmWithdrawSubject = PassthroughSubject<String, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    init(sendData: CexWithdrawModule.SendData, provider: ICexProvider) {
        cexAsset = sendData.cexAsset
        network = sendData.network
        address = sendData.address
        amount = sendData.feeFromAmount ? sendData.amount - sendData.fee : sendData.amount
        feeFromAmount = sendData.feeFromAmount
        fee = sendData.fee
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

        Task { [weak self, provider, cexAsset, network, address, amount, feeFromAmount] in
            do {
                let id = try await provider.withdraw(id: cexAsset.id, network: network?.id, address: address, amount: amount, feeFromAmount: feeFromAmount)
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
