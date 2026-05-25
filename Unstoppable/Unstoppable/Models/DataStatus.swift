import Foundation
import RxCocoa
import WalletCore

extension DataStatus {
    func handle<S>(loadingRelay: BehaviorRelay<Bool>?, completedRelay: PublishRelay<S?>?, failedRelay: PublishRelay<Error?>?, mapper: (T) -> S?) {
        if case .loading = self {
            loadingRelay?.accept(true)
        } else {
            loadingRelay?.accept(false)
        }

        if case let .completed(result) = self {
            completedRelay?.accept(mapper(result))
        } else {
            completedRelay?.accept(nil)
        }

        if case let .failed(error) = self {
            failedRelay?.accept(error)
        } else {
            failedRelay?.accept(nil)
        }
    }
}

struct FallibleData<T> {
    let data: T
    let errors: [Error]
    let warnings: [Warning]

    var cautionType: CautionType? {
        guard errors.isEmpty else {
            return .error
        }

        guard warnings.isEmpty else {
            return .warning
        }

        return nil
    }
}
