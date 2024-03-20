import Alamofire
import Foundation
import HsToolKit

func stat(page: StatPage, section: StatSection? = nil, event: StatEvent, params: [StatParam: Any]? = nil) {
    StatManager.instance.sendStat(page: page, section: section, event: event, params: params)
//    print("PAGE: \(page)\(section.map { ", SECTION: \($0)" } ?? ""), event: \(event.raw)\(params.map { ", PARAMS: \($0)" } ?? "")")
}

class StatManager {
    static let instance = StatManager(networkManager: App.shared.networkManager)

    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func sendStat(page: StatPage, section: StatSection? = nil, event: StatEvent, params: [StatParam: Any]? = nil) {
        Task {
            var parameters: Parameters = [
                "page": page.rawValue,
                "event": event.raw,
            ]

            if let section {
                parameters["section"] = section.rawValue
            }

            if let params {
                for (key, value) in params {
                    parameters[key.rawValue] = value
                }
            }

            _ = try await networkManager.fetchJson(url: "\(AppConfig.marketApiUrl)/v1/stats", method: .head, parameters: parameters)
        }
    }
}
