import Alamofire
import Combine
import Foundation
import HsExtensions
import HsToolKit
import ObjectMapper

class AppStateManager {
    private let syncInterval: TimeInterval = 60 * 60

    private let localStorage: LocalStorage
    private let networkManager: NetworkManager
    private let appManager: AppManager
    private var cancellables = Set<AnyCancellable>()

    private(set) var swapEnabled: Bool

    init(localStorage: LocalStorage, networkManager: NetworkManager, appManager: AppManager) {
        self.localStorage = localStorage
        self.networkManager = networkManager
        // networkManager = NetworkManager(logger: .init(minLogLevel: .debug))
        self.appManager = appManager

        swapEnabled = localStorage.swapEnabled

        appManager.willEnterForegroundPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.syncIfRequired()
            }
            .store(in: &cancellables)

        sync()
    }

    private func syncIfRequired() {
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
