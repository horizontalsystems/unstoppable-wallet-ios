import RxSwift

class JsonApiProvider {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

}

extension JsonApiProvider: IJsonApiProvider {

    enum RequestObject {
        case get(url: String, params: [String: Any]?)
        case post(url: String, params: [String: Any]?)
    }

    func getJson(requestObject: RequestObject) -> Single<[String: Any]> {
        switch requestObject {
        case let .get(url, params):
            return networkManager.single(urlString: url, httpMethod: .get, parameters: params, timoutInterval: 10)
        case let .post(url, params):
            return networkManager.single(urlString: url, httpMethod: .post, parameters: params, timoutInterval: 10)
        }
    }

}
