import Foundation
import RxCocoa

enum DataStatus<T> {
    case loading
    case failed(Error)
    case completed(T)

    init(data: T?) {
        if let data {
            self = .completed(data)
        } else {
            self = .loading
        }
    }

    var isLoading: Bool { self == .loading }

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

    static func zip<A, B>(_ first: DataStatus<A>, _ second: DataStatus<B>) -> DataStatus<(A, B)> {
        if let firstData = first.data, let secondData = second.data {
            return DataStatus<(A, B)>(data: (firstData, secondData))
        }

        switch first {
        case let .failed(error): return .failed(error)
        default: ()
        }

        switch second {
        case let .failed(error): return .failed(error)
        default: ()
        }

        return .loading
    }

    func map<R>(_ transform: (T) -> R, transformError: ((Error) -> Error)? = nil) -> DataStatus<R> {
        switch self {
        case .loading: return .loading
        case let .failed(error): return .failed(transformError?(error) ?? error)
        case let .completed(data): return .completed(transform(data))
        }
    }

    func flatMap<R>(_ transform: (T) -> R?) -> DataStatus<R>? {
        switch self {
        case .loading: return .loading
        case let .failed(error): return .failed(error)
        case let .completed(data):
            if let result = transform(data) {
                return .completed(result)
            }
            return nil
        }
    }

    var data: T? {
        if case let .completed(data) = self {
            return data
        }
        return nil
    }

    var error: Error? {
        if case let .failed(error) = self {
            return error
        }
        return nil
    }
}

extension DataStatus: Equatable {
    public static func == (lhs: DataStatus<T>, rhs: DataStatus<T>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.completed, .completed), (.failed, .failed): return true
        default: return false
        }
    }
}

extension DataStatus where T: Equatable {
    func equalTo(_ rhs: DataStatus<T>) -> Bool {
        switch (self, rhs) {
        case (.loading, .loading): return true
        case let (.failed(lhsValue), .failed(rhsValue)):
            return lhsValue.smartDescription == rhsValue.smartDescription
        case let (.completed(lhsValue), .completed(rhsValue)):
            return lhsValue == rhsValue
        default: return false
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
