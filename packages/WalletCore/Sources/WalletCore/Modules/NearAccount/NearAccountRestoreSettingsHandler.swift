import MarketKit
import NearKit

/// The NEAR account a restored phrase opens, among those its key controls. A mainnet setting:
/// testnet and watch accounts always open the implicit account or the watched address.
class NearAccountRestoreSettingsHandler: RestoreSettingsHandler {
    private let publicKey: NearKit.PublicKey
    private var entered = false

    init(publicKey: NearKit.PublicKey) {
        self.publicKey = publicKey
        super.init()
    }

    override class func instance(blockchainType: BlockchainType, accountType: AccountType?) -> IRestoreSettingsHandler? {
        guard blockchainType == .near, Core.shared.nearKitManager.network == .mainNet, case .mnemonic = accountType,
              let seed = accountType?.mnemonicSeed, let publicKey = try? NearKit.Signer.publicKey(seed: seed)
        else {
            return nil
        }

        return NearAccountRestoreSettingsHandler(publicKey: publicKey)
    }
}

extension NearAccountRestoreSettingsHandler: IRestoreSettingsHandler {
    func request(token _: Token, statPage _: StatPage?, onEnter: @escaping (RestoreSettings) -> Void, onCancel: @escaping () -> Void) {
        entered = false

        Coordinator.shared.present { [self] isPresented in
            NearAccountPickerView(publicKey: publicKey, isPresented: isPresented, onSelect: { accountId in
                entered = true
                onEnter([.nearAccountId: accountId])
            }, onUseDefault: {
                entered = true
                onEnter([:])
            })
        } onDismiss: { [self] in
            if !entered {
                onCancel()
            }
        }
    }
}
