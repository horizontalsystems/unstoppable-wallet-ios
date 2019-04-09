import RxSwift

class JsonApiProvider {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

}

extension JsonApiProvider: IJsonApiProvider {

    func getJson(urlString: String, parameters: [String: Any]?) -> Single<[String: Any]> {
        return networkManager.single(urlString: urlString, httpMethod: .get, parameters: parameters, timoutInterval: 10)
    }

}
