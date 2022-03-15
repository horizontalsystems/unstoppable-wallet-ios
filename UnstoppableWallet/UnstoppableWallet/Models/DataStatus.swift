import Foundation
import RxCocoa

enum DataStatus<T> {
    case loading
    case failed(Error)
    case completed(T)

    init(data: T?) {
        if let data = data {
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

        if case .completed(let result) = self {
            completedRelay?.accept(mapper(result))
        } else {
            completedRelay?.accept(nil)
        }

        if case .failed(let error) = self {
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
        case .failed(let error): return .failed(error)
        default: ()
        }

        switch second {
        case .failed(let error): return .failed(error)
        default: ()
        }

        return .loading
    }

    func map<R>(_ transform: (T) -> R, transformError: ((Error) -> Error)? = nil) -> DataStatus<R> {
        switch self {
        case .loading: return .loading
        case .failed(let error): return .failed(transformError?(error) ?? error)
        case .completed(let data): return .completed(transform(data))
        }
    }

    func flatMap<R>(_ transform: (T) -> R?) -> DataStatus<R>? {
        switch self {
        case .loading: return .loading
        case .failed(let error): return .failed(error)
        case .completed(let data):
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

    public static func ==(lhs: DataStatus<T>, rhs: DataStatus<T>) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.completed, .completed), (.failed, .failed): return true
        default: return false
        }
    }

}

extension DataStatus where T: Equatable {

    func equalTo(_ rhs: DataStatus<T>) -> Bool  {
        switch (self, rhs) {
        case (.loading, .loading): return true
        case (.failed(let lhsValue), .failed(let rhsValue)):
            return lhsValue.smartDescription == rhsValue.smartDescription
        case (.completed(let lhsValue), .completed(let rhsValue)):
            return lhsValue == rhsValue
        default: return false
        }
    }

}

struct FallibleData<T> {
    let data: T
    let errors: [Error]
    let warnings: [Warning]
}
