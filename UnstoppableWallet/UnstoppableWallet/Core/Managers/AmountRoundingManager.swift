import Combine
import HsExtensions

class AmountRoundingManager {
    private let storage: LocalStorage

    private let amountRoundingSubject = PassthroughSubject<Bool, Never>()

    @PostPublished var useAmountRounding: Bool {
        didSet {
            storage.useAmountRounding = useAmountRounding
            amountRoundingSubject.send(useAmountRounding)
        }
    }

    init(storage: LocalStorage) {
        self.storage = storage
        useAmountRounding = storage.useAmountRounding
    }
}

extension AmountRoundingManager {
    var amountRoundingPublisher: AnyPublisher<Bool, Never> {
        amountRoundingSubject.eraseToAnyPublisher()
    }
}
