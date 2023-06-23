import Foundation
import Combine
import HsExtensions

class CexCoinSelectService {
    private let account: Account
    private let mode: CexCoinSelectModule.Mode
    private let cexAssetManager: CexAssetManager

    private let internalItems: [Item]
    private var filter: String = ""

    @PostPublished private(set) var items = [Item]()

    init?(accountManager: AccountManager, mode: CexCoinSelectModule.Mode, cexAssetManager: CexAssetManager) {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        self.account = account
        self.mode = mode
        self.cexAssetManager = cexAssetManager

        internalItems = cexAssetManager.cexAssets(account: account).map { cexAsset in
            let enabled: Bool

            switch mode {
            case .deposit: enabled = cexAsset.depositEnabled
            case .withdraw: enabled = cexAsset.withdrawEnabled
            }

            return Item(cexAsset: cexAsset, enabled: enabled)
        }

        syncItems()
    }

    private func syncItems() {
        var items = internalItems

        switch mode {
        case .withdraw:
            items = items.filter { item in
                item.cexAsset.freeBalance > 0
            }
        case .deposit: ()
        }

        if !filter.isEmpty {
            items = items.filter { item in
                item.cexAsset.coinCode.localizedCaseInsensitiveContains(filter) || item.cexAsset.coinName.localizedCaseInsensitiveContains(filter)
            }
        }

        self.items = items.sorted { lhsItem, rhsItem in
            lhsItem.cexAsset.coinCode.lowercased() < rhsItem.cexAsset.coinCode.lowercased()
        }
    }

}

extension CexCoinSelectService {

    func set(filter: String) {
        self.filter = filter
        syncItems()
    }

}

extension CexCoinSelectService {

    struct Item {
        let cexAsset: CexAsset
        let enabled: Bool
    }

}
