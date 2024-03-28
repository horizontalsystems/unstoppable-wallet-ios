import Alamofire
import Foundation
import HsToolKit

func stat(page: StatPage, section: StatSection? = nil, event: StatEvent) {
//    print("PAGE: \(page)\(section.map { ", SECTION: \($0)" } ?? ""), event: \(event.name)\(event.params.map { ", PARAMS: \($0)" } ?? "")")
    App.shared.statManager.logStat(eventPage: page, eventSection: section, event: event)
}

class StatManager {
    private static let keyLastSent = "stat_last_sent"
    private static let sendThreshold: TimeInterval = 1 * 60 * 60 // 1 hour

    private let networkManager: NetworkManager
    private let storage: StatStorage
    private let userDefaultsStorage: UserDefaultsStorage

    init(networkManager: NetworkManager, storage: StatStorage, userDefaultsStorage: UserDefaultsStorage) {
        self.networkManager = networkManager
        self.storage = storage
        self.userDefaultsStorage = userDefaultsStorage

        let lastSent: Double? = userDefaultsStorage.value(for: Self.keyLastSent)

        if lastSent == nil {
            userDefaultsStorage.set(value: Date().timeIntervalSince1970, for: Self.keyLastSent)
        }
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

        guard let lastSent, Date().timeIntervalSince1970 - lastSent > Self.sendThreshold else {
            return
        }

        Task { [storage] in
            let records = try storage.all()

            let jsonObject = records.map { record in
                var object: [String: Any] = [
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

            let data = try JSONSerialization.data(withJSONObject: jsonObject)

            let string = String(data: data, encoding: .utf8)
            print(string ?? "N/A")

            // send to backend

            try storage.clear()
        }
    }
}
