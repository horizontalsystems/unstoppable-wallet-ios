import Combine
import HsExtensions

class RecentlySentManager {
    private let storage: LocalStorage

    private let recentlySentSubject = PassthroughSubject<Bool, Never>()

    @PostPublished var recentlySent: Bool {
        didSet {
            storage.recentlySent = recentlySent
            recentlySentSubject.send(recentlySent)
        }
    }

    init(storage: LocalStorage) {
        self.storage = storage
        recentlySent = storage.recentlySent
    }
}

extension RecentlySentManager {
    var recentlySentPublisher: AnyPublisher<Bool, Never> {
        recentlySentSubject.eraseToAnyPublisher()
    }
}
