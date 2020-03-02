import Foundation

enum ChartDataStatus<T> {
    case loading
    case failed
    case completed(T)

    init(data: T?) {
        if let data = data {
            self = .completed(data)
        } else {
            self = .loading
        }
    }

    func convert<R>(_ transform: (T) -> R) -> ChartDataStatus<R> {
        switch self {
        case .loading: return .loading
        case .failed: return .failed
        case .completed(let data): return .completed(transform(data))
        }
    }

    var data: T? {
        if case let .completed(data) = self {
            return data
        }
        return nil
    }

}
