import Foundation
import Combine
import HsExtensions

class CexCoinSelectService {
    private let account: Account
    private let mode: CexCoinSelectModule.Mode
    private let cexAssetManager: CexAssetManager

    private let internalCexAssets: [CexAsset]
    private var filter: String = ""

    @PostPublished private(set) var cexAssets = [CexAsset]()

    init?(accountManager: AccountManager, mode: CexCoinSelectModule.Mode, cexAssetManager: CexAssetManager) {
        guard let account = accountManager.activeAccount else {
            return nil
        }

        self.account = account
        self.mode = mode
        self.cexAssetManager = cexAssetManager

        internalCexAssets = cexAssetManager.cexAssets(account: account)

        syncCexAssets()
    }

    private func syncCexAssets() {
        var cexAssets = internalCexAssets

        switch mode {
        case .withdraw:
            cexAssets = cexAssets.filter { cexAsset in
                cexAsset.freeBalance > 0
            }
        case .deposit: ()
        }

        if !filter.isEmpty {
            cexAssets = cexAssets.filter { cexAsset in
                cexAsset.id.localizedCaseInsensitiveContains(filter)
            }
        }

        self.cexAssets = cexAssets.sorted { lhsCexAsset, rhsCexAsset in
            lhsCexAsset.id.lowercased() < rhsCexAsset.id.lowercased()
        }
    }

}

extension CexCoinSelectService {

    func set(filter: String) {
        self.filter = filter
        syncCexAssets()
    }

}
