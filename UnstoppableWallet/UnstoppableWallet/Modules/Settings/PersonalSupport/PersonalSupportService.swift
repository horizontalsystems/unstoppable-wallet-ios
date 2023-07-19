import Combine
import MarketKit
import HsExtensions

class PersonalSupportService {
    private let marketKit: MarketKit.Kit
    private var tasks = Set<AnyTask>()

    private let successSubject = PassthroughSubject<Void, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    private var username: String?

    init(marketKit: MarketKit.Kit) {
        self.marketKit = marketKit
    }

}

extension PersonalSupportService {

    var successPublisher: AnyPublisher<Void, Never> {
        successSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func set(username: String?) {
        self.username = username
    }

    func request() {    
        guard let username else {
            return
        }

        Task { [weak self, marketKit] in
            do {
                try await marketKit.requestPersonalSupport(telegramUsername: username)
                self?.successSubject.send()
            } catch {
                self?.errorSubject.send(error)
            }
        }.store(in: &tasks)
    }

}
