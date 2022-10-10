import Foundation
import Alamofire
import RxSwift
import RxRelay

class DownloadService {
    private let queue: DispatchQueue
    private var downloads = [String: Double]()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .idle {
        didSet {
            if state != oldValue {
                stateRelay.accept(state)
            }
        }
    }

    init(queueLabel: String = "io.SynchronizedDownloader") {
        queue = DispatchQueue(label: queueLabel, qos: .background)
    }

    private func request(source: URLConvertible, destination: @escaping DownloadRequest.Destination, progress: ((Double) -> ())? = nil, completion: ((Bool) -> ())? = nil) {
        guard let key = try? source.asURL().path else {
            return
        }

        let alreadyDownloading = queue.sync {
            downloads.contains(where: { (existKey, _) in key == existKey })
        }

        guard !alreadyDownloading else {
            return
        }

        handle(progress: 0, key: key)
        AF.download(source, to: destination)
                .downloadProgress(queue: DispatchQueue.global(qos: .background)) { [weak self] progressValue in
                    self?.handle(progress: progressValue.fractionCompleted, key: key)
                    progress?(progressValue.fractionCompleted)
                }
                .responseData(queue: DispatchQueue.global(qos: .background)) { [weak self] response in
                    self?.handle(response: response, key: key)
                    switch response.result {        // extend errors/data to completion if needed
                    case .success: completion?(true)
                    case .failure: completion?(false)
                    }
                }
    }

    private func handle(progress: Double, key: String) {
        queue.async {
            self.downloads[key] = progress
            self.syncState()
        }
    }

    private func handle(response: AFDownloadResponse<Data>, key: String) {
        queue.async {
            self.downloads[key] = nil
            self.syncState()
        }
    }

    private func syncState() {
        var lastProgress: Double = 0

        if case let .inProgress(value) = state {
            lastProgress = value
        }

        guard downloads.count != 0 else {
            state = .idle
            return
        }

        let minimalProgress = downloads.min(by: { a, b in a.value < b.value })?.value ?? lastProgress
        state = .inProgress(value: max(minimalProgress, lastProgress))
    }

}

extension DownloadService {

    public func download(source: URLConvertible, destination: URL, progress: ((Double) -> ())? = nil, completion: ((Bool) -> ())? = nil) {
        let destination: DownloadRequest.Destination = { _, _ in
            (destination, [.removePreviousFile, .createIntermediateDirectories])
        }

        request(source: source, destination: destination, progress: progress, completion: completion)
    }

    public var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension DownloadService {

    public static func existing(url: URL) -> Bool {
        (try? FileManager.default.attributesOfItem(atPath: url.path)) != nil
    }

    public enum State: Equatable {
        case idle
        case inProgress(value: Double)

        public static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case (.inProgress(let lhsValue), .inProgress(let rhsValue)): return lhsValue == rhsValue
            default: return false
            }
        }
    }

}
