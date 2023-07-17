import Foundation
import Combine
import HsExtensions

class CexWithdrawConfirmService<Handler: ICexWithdrawHandler> {
    let cexAsset: CexAsset
    let network: CexWithdrawNetwork?
    let address: String
    let amount: Decimal
    let feeFromAmount: Bool
    let fee: Decimal
    private let handler: Handler
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .idle
    private let confirmWithdrawSubject = PassthroughSubject<Handler.WithdrawResult, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    init(sendData: CexWithdrawModule.SendData, handler: Handler) {
        cexAsset = sendData.cexAsset
        network = sendData.network
        address = sendData.address
        amount = sendData.feeFromAmount ? sendData.amount - sendData.fee : sendData.amount
        feeFromAmount = sendData.feeFromAmount
        fee = sendData.fee
        self.handler = handler
    }

}

extension CexWithdrawConfirmService {

    var confirmWithdrawPublisher: AnyPublisher<Handler.WithdrawResult, Never> {
        confirmWithdrawSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func withdraw() {
        tasks = Set()

        state = .loading

        Task { [weak self, handler, cexAsset, network, address, amount, feeFromAmount] in
            do {
                let result = try await handler.withdraw(id: cexAsset.id, network: network?.id, address: address, amount: amount, feeFromAmount: feeFromAmount)

                self?.confirmWithdrawSubject.send(result)
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

    enum ConfirmError: Error {
        case invalidId
    }

}
