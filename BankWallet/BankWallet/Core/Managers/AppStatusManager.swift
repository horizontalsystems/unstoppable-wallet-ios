import Foundation

class AppStatusManager {
    private let systemInfoManager: ISystemInfoManager
    private let localStorage: ILocalStorage

    init(systemInfoManager: ISystemInfoManager, localStorage: ILocalStorage) {
        self.systemInfoManager = systemInfoManager
        self.localStorage = localStorage
    }

}

extension AppStatusManager: IAppStatusManager {

    var status: [(String, Any)] {
        [
            ("App Info", [
                ("Current Time", Date()),
                ("App Version", systemInfoManager.appVersion),
                ("Phone Model", systemInfoManager.deviceModel),
                ("OS Version", systemInfoManager.osVersion)
            ]),
            ("Version History", localStorage.appVersions.map { ($0.version, $0.date) }),
            ("Blockchains Status", [
                ("Bitcoin", [
                    ("Synced Until", Date()),
                    ("Peer 1", [
                        ("Status", "active"),
                        ("IP Address", "192.168.0.1")
                    ]),
                    ("Peer 2", [
                        ("Status", "active"),
                        ("IP Address", "192.168.0.1")
                    ])
                ]),
                ("Bitcoin Cash", [
                    ("Synced Until", Date()),
                    ("Peer 1", [
                        ("Status", "active"),
                        ("IP Address", "192.168.0.1")
                    ]),
                    ("Peer 2", [
                        ("Status", "active"),
                        ("IP Address", "192.168.0.1")
                    ])
                ]),
            ])
        ]
    }

}
