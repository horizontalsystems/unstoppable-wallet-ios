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

extension GuidesManager {

    func guideCategoriesSingle(url: URL) -> Single<[GuideCategory]> {
        let request = networkManager.session.request(url)
        return networkManager.single(request: request)
    }

}
