import Foundation

public enum DataStatus<T> {
    case loading
    case failed(Error)
    case completed(T)

    public init(data: T?) {
        if let data {
            self = .completed(data)
        } else {
            self = .loading
        }
    }

    public var isLoading: Bool { self == .loading }

    public static func zip<A, B>(_ first: DataStatus<A>, _ second: DataStatus<B>) -> DataStatus<(A, B)> {
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

    public func map<R>(_ transform: (T) -> R, transformError: ((Error) -> Error)? = nil) -> DataStatus<R> {
        switch self {
        case .loading: return .loading
        case let .failed(error): return .failed(transformError?(error) ?? error)
        case let .completed(data): return .completed(transform(data))
        }
    }

    public func flatMap<R>(_ transform: (T) -> R?) -> DataStatus<R>? {
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

    public var data: T? {
        if case let .completed(data) = self {
            return data
        }
        return nil
    }

    public var error: Error? {
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

public extension DataStatus where T: Equatable {
    func equalTo(_ rhs: DataStatus<T>) -> Bool {
        switch (self, rhs) {
        case (.loading, .loading): return true
        case let (.failed(lhsValue), .failed(rhsValue)):
            let lhsDescription = lhsValue is LocalizedError ? lhsValue.localizedDescription : "\(lhsValue)"
            let rhsDescription = rhsValue is LocalizedError ? rhsValue.localizedDescription : "\(rhsValue)"
            return lhsDescription == rhsDescription
        case let (.completed(lhsValue), .completed(rhsValue)):
            return lhsValue == rhsValue
        default: return false
        }
    }
}
