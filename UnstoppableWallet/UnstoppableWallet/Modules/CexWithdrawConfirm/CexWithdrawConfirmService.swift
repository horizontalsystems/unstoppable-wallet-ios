import Foundation
import Combine
import HsExtensions

class CexWithdrawConfirmService {
    private let sendData: CexWithdrawModule.SendData
    private let handler: ICexWithdrawHandler
    private var tasks = Set<AnyTask>()

    @PostPublished private(set) var state: State = .idle
    private let confirmWithdrawSubject = PassthroughSubject<Any, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    init(sendData: CexWithdrawModule.SendData, handler: ICexWithdrawHandler) {
        self.sendData = sendData
        self.handler = handler
    }

    var cexAsset: CexAsset {
        sendData.cexAsset
    }

    var network: CexWithdrawNetwork? {
        sendData.network
    }

    var address: String {
        sendData.address
    }

    var amount: Decimal {
        sendData.feeFromAmount ? sendData.amount - sendData.fee : sendData.amount
    }

    var fee: Decimal {
        sendData.fee
    }

}

extension CexWithdrawConfirmService {

    var confirmWithdrawPublisher: AnyPublisher<Any, Never> {
        confirmWithdrawSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func withdraw() {
        tasks = Set()

        state = .loading

        Task { [weak self, handler, sendData] in
            do {
                let result = try await handler.withdraw(
                    id: sendData.cexAsset.id,
                    network: sendData.network?.id,
                    address: sendData.address,
                    amount: sendData.amount,
                    feeFromAmount: sendData.feeFromAmount
                )

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
