import Foundation
import RxSwift
import HsToolKit
import Alamofire

protocol IMarkdownContentProvider {
    var contentSingle: Single<String> { get }
    var markdownUrl: URL? { get }
}

class MarkdownPlainContentProvider: IMarkdownContentProvider {
    private let url: URL
    private let networkManager: NetworkManager

    init(url: URL, networkManager: NetworkManager) {
        self.url = url
        self.networkManager = networkManager
    }

    var contentSingle: Single<String> {
        let request = networkManager.session.request(url)

        return Single.create { observer in
            let requestReference = request.responseString(queue: DispatchQueue.global(qos: .background)) { response in
                switch response.result {
                case .success(let result):
                    observer(.success(result))
                case .failure(let error):
                    observer(.error(NetworkManager.unwrap(error: error)))
                }
            }

            return Disposables.create {
                requestReference.cancel()
            }
        }
    }

    var markdownUrl: URL? {
        url
    }

}

class MarkdownGitReleaseContentProvider: IMarkdownContentProvider {
    private let url: URL
    private let networkManager: NetworkManager

    init(url: URL, networkManager: NetworkManager) {
        self.url = url
        self.networkManager = networkManager
    }

    var contentSingle: Single<String> {
        let request = networkManager.session.request(url)

        return networkManager.single(request: request, mapper: self)
    }

    var markdownUrl: URL? {
        nil
    }

}

extension MarkdownGitReleaseContentProvider: IApiMapper {

    public func map(statusCode: Int, data: Any?) throws -> String {
        guard let map = data as? [String: Any] else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        guard let result = map["body"] as? String else {
            throw NetworkManager.RequestError.invalidResponse(statusCode: statusCode, data: data)
        }

        return result
    }

}
