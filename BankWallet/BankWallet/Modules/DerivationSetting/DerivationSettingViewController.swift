import UIKit
import ActionSheet

class DerivationSettingViewController: WalletActionSheetController {
    private var items = [DerivationAlertItem]()
    private let coin: Coin
    private let coinType: CoinType
    private var currentDerivation: MnemonicDerivation

    var delegate: IDerivationSettingDelegate

    init(derivationSetting: DerivationSetting, coin: Coin, delegate: IDerivationSettingDelegate) {
        self.coin = coin
        coinType = derivationSetting.coinType
        currentDerivation = derivationSetting.derivation

        self.delegate = delegate

        super.init()

        let titleItem = AlertTitleItem(
                title: "blockchain_settings.title".localized,
                subtitle: coin.title,
                icon: UIImage(coin: coin),
                iconTintColor: .themeGray,
                tag: 0,
                onClose: { [weak self] in
                    self?.dismiss(byFade: false)
                }
        )
        model.addItemView(titleItem)

        let derivations = MnemonicDerivation.allCases

        for (index, derivation) in derivations.enumerated() {
            let derivationItem = DerivationAlertItem(
                    derivation: derivation,
                    selected: derivation == currentDerivation,
                    tag: index + 1
            ) { [weak self] in
                self?.handleSelect(derivation: derivation)
            }

            model.addItemView(derivationItem)
            items.append(derivationItem)
        }

        let buttonItem = AlertButtonItem(
                tag: derivations.count + 1,
                title: "Done".localized,
                createButton: { .appYellow },
                insets: UIEdgeInsets(top: CGFloat.margin4x, left: CGFloat.margin4x, bottom: CGFloat.margin4x, right: CGFloat.margin4x)
        ) { [weak self] in
            self?.dismiss(animated: true) {
                self?.notifyDerivation()
            }
        }

        buttonItem.isEnabled = true
        model.addItemView(buttonItem)

        onDismiss = { dismiss in
            delegate.onCancelSelectDerivation()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func handleSelect(derivation: MnemonicDerivation) {
        currentDerivation = derivation

        for item in items {
            item.selected = item.derivation == currentDerivation
        }

        model.reload?()
    }

    private func notifyDerivation() {
        delegate.onSelect(derivationSetting: DerivationSetting(coinType: coinType, derivation: currentDerivation), coin: coin)
    }

}

protocol IDerivationSettingDelegate: AnyObject {
    func onSelect(derivationSetting: DerivationSetting, coin: Coin)
    func onCancelSelectDerivation()
}
