import UIKit
import ActionSheet

class ManageWalletsNoAccountViewController: WalletActionSheetController {

    init(coin: Coin, predefinedAccountType: PredefinedAccountType, onSelectNew: @escaping () -> (), onSelectRestore: @escaping () -> ()) {
        super.init()

        let titleItem = AlertTitleItem(
                title: "manage_coins.add_coin.title".localized(coin.title),
                subtitle: "manage_coins.add_coin.subtitle".localized(predefinedAccountType.title),
                icon: UIImage(coin: coin),
                iconTintColor: .themeGray,
                tag: 0,
                onClose: { [weak self] in
                    self?.dismiss(byFade: false)
                }
        )

        let textItem = AlertTextItem(text: "manage_coins.add_coin.text".localized(predefinedAccountType.title, coin.title, predefinedAccountType.title, predefinedAccountType.coinCodes), tag: 1)

        model.addItemView(titleItem)
        model.addItemView(textItem)

        let newItem = AlertButtonItem(
                tag: 2,
                title: "manage_coins.add_coin.create".localized,
                createButton: { .appYellow },
                insets: UIEdgeInsets(top: CGFloat.margin4x, left: CGFloat.margin4x, bottom: 6, right: CGFloat.margin4x)
        ) { [weak self] in
            self?.dismiss(animated: true) {
                onSelectNew()
            }
        }
        newItem.isEnabled = predefinedAccountType.createSupported

        model.addItemView(newItem)

        let restoreItem = AlertButtonItem(
                tag: 3,
                title: "manage_coins.add_coin.restore".localized,
                createButton: { .appGray },
                insets: UIEdgeInsets(top: 6, left: CGFloat.margin4x, bottom: CGFloat.margin4x, right: CGFloat.margin4x)
        ) { [weak self] in
            self?.dismiss(animated: true) {
                onSelectRestore()
            }
        }
        restoreItem.isEnabled = true

        model.addItemView(restoreItem)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentBackgroundColor = .white
    }

}
