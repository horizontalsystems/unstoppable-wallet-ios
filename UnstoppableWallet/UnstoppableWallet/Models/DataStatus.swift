import Foundation

enum DataStatus<T> {
    case loading
    case failed(Error?)
    case completed(T)

    init(data: T?) {
        if let data = data {
            self = .completed(data)
        } else {
            self = .loading
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

    func map<R>(_ transform: (T) -> R) -> DataStatus<R> {
        switch self {
        case .loading: return .loading
        case .failed(let error): return .failed(error)
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

}
