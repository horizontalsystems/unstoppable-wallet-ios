import RxSwift
import RxRelay
import RxCocoa

protocol IMemoAvailableService: AnyObject {
    var isAvailable: Bool { get }
    var isAvailableObservable: Observable<Bool> { get }
}

class SendMemoInputService {
    private let maxSymbols: Int
    private var availableDisposeBag = DisposeBag()

    private let isAvailableRelay = BehaviorRelay<Bool>(value: true)
    var isAvailable: Bool = true {
        didSet {
            isAvailableRelay.accept(isAvailable)
        }
    }

    weak var availableService: IMemoAvailableService? {
        didSet {
            setAvailableService()
        }
    }

    var memo: String?

    init(maxSymbols: Int) {
        self.maxSymbols = maxSymbols
    }

    private func setAvailableService() {
        availableDisposeBag = DisposeBag()

        if let availableService = availableService {
            subscribe(availableDisposeBag, availableService.isAvailableObservable) { [weak self] in self?.sync(available: $0) }
            sync(available: availableService.isAvailable)
        }
    }

    private func sync(available: Bool) {
        isAvailable = available
    }

}

extension SendMemoInputService {

    var isAvailableObservable: Observable<Bool> {
        isAvailableRelay.asObservable()
    }

    func set(text: String?) {
        if (text ?? "").isEmpty {
            memo = nil
        } else {
            memo = text
        }
    }

    func isValid(text: String) -> Bool {
        text.count <= maxSymbols
    }

}
