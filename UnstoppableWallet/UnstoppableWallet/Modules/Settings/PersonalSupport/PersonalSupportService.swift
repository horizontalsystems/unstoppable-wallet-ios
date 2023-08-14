import Combine
import MarketKit
import HsExtensions

class PersonalSupportService {
    private let marketKit: MarketKit.Kit
    private let localStorage: LocalStorage
    private var tasks = Set<AnyTask>()

    private let successSubject = PassthroughSubject<Void, Never>()
    private let errorSubject = PassthroughSubject<Error, Never>()

    @Published private(set) var requestButtonState: AsyncActionButtonState = .disabled
    private var username: String? {
        didSet {
            sync()
        }
    }

    @PostPublished private(set) var requested: Bool

    init(marketKit: MarketKit.Kit, localStorage: LocalStorage) {
        self.marketKit = marketKit
        self.localStorage = localStorage
        requested = localStorage.telegramSupportRequested

        sync()
    }

    private func sync() {
        if username?.isEmpty ?? true {
            requestButtonState = .disabled
            return
        }

        requestButtonState = .enabled
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

        requestButtonState = .spinner

        Task { [weak self, marketKit] in
            do {
                try await marketKit.requestPersonalSupport(telegramUsername: username)
                self?.localStorage.telegramSupportRequested = true
                self?.requestButtonState = .disabled
                self?.successSubject.send()
                self?.requested = true
            } catch {
                self?.requestButtonState = .enabled
                self?.errorSubject.send(error)
            }
        }.store(in: &tasks)
    }

    func newRequest() {
        requested = false
    }

}
