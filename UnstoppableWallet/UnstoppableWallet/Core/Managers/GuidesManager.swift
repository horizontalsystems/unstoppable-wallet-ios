import Foundation
import RxSwift
import HsToolKit
import Alamofire

class GuidesManager {
    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

}

extension GuidesManager: IGuidesManager {

    func guideCategoriesSingle(url: URL) -> Single<[GuideCategory]> {
        let request = networkManager.session.request(url)
        return networkManager.single(request: request)
    }

    func guideContentSingle(url: URL) -> Single<String> {
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

}
