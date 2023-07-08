import Foundation
import Combine
import HsExtensions

class CoinzixVerifyWithdrawService {
    private let orderId: Int
    private let provider: CoinzixCexProvider
    private var tasks = Set<AnyTask>()

    private var emailPin = ""
    private var googlePin = ""

    @DistinctPublished private(set) var state: State = .notReady
    private let successSubject = PassthroughSubject<Void, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    init(orderId: Int, provider: CoinzixCexProvider) {
        self.orderId = orderId
        self.provider = provider

        syncState()
    }

    private func syncState() {
        if emailPin.isEmpty || googlePin.isEmpty {
            state = .notReady
        } else {
            state = .ready
        }
    }

}

extension CoinzixVerifyWithdrawService {

    var successPublisher: AnyPublisher<Void, Never> {
        successSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func set(emailPin: String) {
        self.emailPin = emailPin
        syncState()
    }

    func set(googlePin: String) {
        self.googlePin = googlePin
        syncState()
    }

    func resendEmailPin() {
        tasks = Set()

        Task { [weak self, orderId] in
//            try? await provider.sendWithdrawPin(id: orderId)
        }.store(in: &tasks)
    }

    func submit() {
        tasks = Set()

        state = .submitting

        Task { [weak self, provider, orderId, emailPin, googlePin] in
            do {
//                try await provider.confirmWithdraw(id: orderId, emailPin: emailPin, googlePin: googlePin)
                try await Task.sleep(nanoseconds: 2_000_000_000)
                self?.successSubject.send()
            } catch {
                self?.errorSubject.send(error)
            }

            self?.syncState()
        }.store(in: &tasks)
    }

}

extension CoinzixVerifyWithdrawService {

    enum State {
        case notReady
        case ready
        case submitting
    }

}
