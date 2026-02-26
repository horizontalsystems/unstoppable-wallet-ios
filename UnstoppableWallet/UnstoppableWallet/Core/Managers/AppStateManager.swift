import Alamofire
import Foundation
import HsToolKit
import ObjectMapper

class AppStateManager {
    static let instance = AppStateManager()

    private let syncInterval: TimeInterval = 60 * 60

    private let localStorage = LocalStorage(userDefaultsStorage: UserDefaultsStorage())
    private let networkManager = NetworkManager()

    private(set) var swapEnabled: Bool

    init() {
        swapEnabled = localStorage.swapEnabled

        sync()
    }

    func syncIfRequired() {
        let lastSyncTimetamp = localStorage.appStateLastSyncTimestamp

        if let lastSyncTimetamp, Date().timeIntervalSince1970 - lastSyncTimetamp < syncInterval {
            return
        }

        sync()
    }

    func sync() {
        if localStorage.forceEnableSwap {
            swapEnabled = true
            return
        }

        Task { [weak self, networkManager] in
            let parameters: Parameters = ["version": AppConfig.appVersion]
            let response: Response = try await networkManager.fetch(url: "\(AppConfig.marketApiUrl)/v1/status/app-state", parameters: parameters)

            self?.swapEnabled = response.swapEnabled
            self?.localStorage.swapEnabled = response.swapEnabled
            self?.localStorage.appStateLastSyncTimestamp = Date().timeIntervalSince1970
        }
    }
}

extension AppStateManager {
    struct Response: ImmutableMappable {
        let swapEnabled: Bool

        init(map: Map) throws {
            swapEnabled = try map.value("swap_enabled")
        }
    }
}
