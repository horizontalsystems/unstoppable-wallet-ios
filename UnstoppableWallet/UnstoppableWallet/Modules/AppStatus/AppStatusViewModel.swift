import Foundation

class AppStatusViewModel {
}

extension AppStatusViewModel {

    var version: String {
        "0.16 (404)"
    }

    var linkedWalletsCount: Int {
        2
    }

    var blockchainViewItems: [BlockchainViewItem] {
        [
            BlockchainViewItem(name: "Bitcoin", status: .syncing),
            BlockchainViewItem(name: "Ethereum", status: .synced),
        ]
    }

}

extension AppStatusViewModel {

    struct BlockchainViewItem {
        let name: String
        let status: BlockchainStatus
    }

    enum BlockchainStatus {
        case syncing
        case synced
        case notSynced
    }

}
