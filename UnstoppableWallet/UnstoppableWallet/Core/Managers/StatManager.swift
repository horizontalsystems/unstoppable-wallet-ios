import Alamofire
import Foundation
import HsToolKit

func stat(page: StatPage, section: StatSection? = nil, event: StatEvent) {
    StatManager.instance.sendStat(eventPage: page, eventSection: section, event: event)
//    print("PAGE: \(page)\(section.map { ", SECTION: \($0)" } ?? ""), event: \(event.name)\(event.params.map { ", PARAMS: \($0)" } ?? "")")
}

class StatManager {
    static let instance = StatManager(networkManager: App.shared.networkManager)

    private let networkManager: NetworkManager

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func sendStat(eventPage: StatPage, eventSection: StatSection? = nil, event: StatEvent) {
        Task {
            var parameters: Parameters = [
                "event_page": eventPage.rawValue,
                "event": event.name,
            ]

            if let eventSection {
                parameters["event_section"] = eventSection.rawValue
            }

            if let params = event.params {
                for (key, value) in params {
                    parameters[key.rawValue] = value
                }
            }

            _ = try await networkManager.fetchJson(url: "\(AppConfig.marketApiUrl)/v1/stats", method: .head, parameters: parameters)
        }
    }
}
