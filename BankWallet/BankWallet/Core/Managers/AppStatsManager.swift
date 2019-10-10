import Foundation

class AppStatusManager {
}

extension AppStatusManager: IAppStatusManager {
    var status: [(String, Any)] {
        [
            ("App Info", [
                ("Current Time", Date()),
                ("App Version", "0.10.0"),
                ("Phone Model", "iPhone 6s"),
                ("OS Version", "iOS 12")
            ]),
            ("Version History", [
                ("0.7.0", Date()),
                ("0.8.0", Date()),
                ("0.9.0", Date())
            ]),
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
