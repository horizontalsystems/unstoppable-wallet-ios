import Foundation

class DepositAddressViewHelperFactory {
    private let wallet: Wallet

    init(wallet: Wallet) {
        self.wallet = wallet
    }

    func viewHelper(depositAddress: DepositAddress, isMainNet: Bool) -> DepositAddressViewHelper {
        if let derivation = wallet.token.type.derivation {                               // has mnemonic typed wallet
            return DepositAddressViewHelper.Derivation(
                    testNet: !isMainNet,
                    mnemonicDerivation: derivation)
        } else if let depositAddress = depositAddress as? ActivatedDepositAddress {      // has activated address
            return DepositAddressViewHelper.Activated(
                    testNet: !isMainNet,
                    isActive: depositAddress.isActive)
        } else {
            return DepositAddressViewHelper(testNet: !isMainNet)
        }
    }

}
