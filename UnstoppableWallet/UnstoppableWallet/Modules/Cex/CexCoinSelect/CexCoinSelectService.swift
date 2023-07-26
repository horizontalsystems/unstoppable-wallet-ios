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

        internalItems = cexAssetManager.cexAssets(account: account).compactMap { cexAsset in
            switch mode {
            case .deposit:
                return Item(cexAsset: cexAsset, enabled: cexAsset.depositEnabled)
            case .withdraw:
                guard cexAsset.freeBalance > 0 else {
                    return nil
                }

                return Item(cexAsset: cexAsset, enabled: cexAsset.withdrawEnabled)
            }
        }

        syncItems()
    }

    private func syncItems() {
        var items = internalItems

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

    var isEmpty: Bool {
        internalItems.isEmpty
    }

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
