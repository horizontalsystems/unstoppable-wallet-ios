import Alamofire
import Foundation
import HsToolKit
import MarketKit

func stat(page: StatPage, section: StatSection? = nil, event: StatEvent) {
    // print("PAGE: \(page)\(section.map { ", SECTION: \($0)" } ?? ""), event: \(event.name)\(event.params.map { ", PARAMS: \($0)" } ?? "")")
    App.shared.statManager.logStat(eventPage: page, eventSection: section, event: event)
}

class StatManager {
    private static let keyLastSent = "stat_last_sent"
    private static let sendThreshold: TimeInterval = 1 * 60 * 60 // 1 hour

    private let marketKit: MarketKit.Kit
    private let storage: StatStorage
    private let userDefaultsStorage: UserDefaultsStorage
    private let appVersion: String
    private let appId: String?

    init(marketKit: MarketKit.Kit, storage: StatStorage, userDefaultsStorage: UserDefaultsStorage) {
        self.marketKit = marketKit
        self.storage = storage
        self.userDefaultsStorage = userDefaultsStorage

        appVersion = AppConfig.appVersion
        appId = AppConfig.appId
    }

    func logStat(eventPage: StatPage, eventSection: StatSection? = nil, event: StatEvent) {
        var parameters: [String: Any]?

        if let params = event.params {
            parameters = [String: Any]()

            for (key, value) in params {
                parameters?[key.rawValue] = value
            }
        }

        let record = StatRecord(
            timestamp: Int(Date().timeIntervalSince1970),
            eventPage: eventPage.rawValue,
            eventSection: eventSection?.rawValue,
            event: event.name,
            params: parameters
        )

        do {
            try storage.save(record: record)
        } catch {
            print("Cannot save StatRecord: \(error)")
        }
    }

    func sendStats() {
        let lastSent: Double? = userDefaultsStorage.value(for: Self.keyLastSent)

        if let lastSent, Date().timeIntervalSince1970 - lastSent < Self.sendThreshold {
            return
        }

        Task { [storage] in
            let records = try storage.all()

            guard !records.isEmpty else {
                return
            }

            let stats = records.map { record in
                var object: [String: Any] = [
                    "time": record.timestamp,
                    "event_page": record.eventPage,
                    "event": record.event,
                ]

                if let eventSection = record.eventSection {
                    object["event_section"] = eventSection
                }

                if let params = record.params {
                    for (key, value) in params {
                        object[key] = value
                    }
                }

                return object
            }

//            let data = try JSONSerialization.data(withJSONObject: stats)
//            let string = String(data: data, encoding: .utf8)
//            print(string ?? "N/A")

            try await marketKit.send(stats: stats, appVersion: appVersion, appId: appId)

            userDefaultsStorage.set(value: Date().timeIntervalSince1970, for: Self.keyLastSent)
            try storage.clear()
        }
    }
}
