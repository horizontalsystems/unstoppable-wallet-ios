import Foundation
import Combine
import HsExtensions
import HsToolKit

protocol ICoinzixVerifyService {
    func verify(emailCode: String?, googleCode: String?) async throws
    func resendPin() async throws
}

class CoinzixVerifyService {
    let twoFactorTypes: [CoinzixVerifyModule.TwoFactorType]
    private let verifyService: ICoinzixVerifyService
    private var tasks = Set<AnyTask>()

    private var emailPin = ""
    private var googlePin = ""

    @DistinctPublished private(set) var state: State = .notReady
    private let successSubject = PassthroughSubject<Void, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    init(twoFactorTypes: [CoinzixVerifyModule.TwoFactorType], verifyService: ICoinzixVerifyService) {
        self.twoFactorTypes = twoFactorTypes
        self.verifyService = verifyService

        syncState()
    }

    private func syncState() {
        var ready = true

        for type in twoFactorTypes {
            switch type {
            case .email:
                if emailPin.isEmpty {
                    ready = false
                }
            case .authenticator:
                if googlePin.isEmpty {
                    ready = false
                }
            }
        }

        state = ready ? .ready : .notReady
    }

}

extension CoinzixVerifyService {

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

        Task { [verifyService] in
            try? await verifyService.resendPin()
        }.store(in: &tasks)
    }

    func submit() {
        tasks = Set()

        state = .submitting

        Task { [weak self, verifyService, emailPin, googlePin] in
            do {
                try await verifyService.verify(emailCode: emailPin.isEmpty ? nil : emailPin, googleCode: googlePin.isEmpty ? nil : googlePin)
                self?.successSubject.send()
            } catch {
                self?.errorSubject.send(error)
            }

            self?.syncState()
        }.store(in: &tasks)
    }

}

extension CoinzixVerifyService {

    enum State {
        case notReady
        case ready
        case submitting
    }

}
