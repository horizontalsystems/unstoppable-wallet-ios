import UIKit
import ActionSheet

class CreateWalletNotSupportedViewController: WalletActionSheetController {

    init(coin: Coin, predefinedAccountType: PredefinedAccountType) {
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

        let textItem = AlertTextItem(text: "error.cant_create_wallet".localized(predefinedAccountType.title), tag: 1)

        model.addItemView(titleItem)
        model.addItemView(textItem)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentBackgroundColor = .white
    }

}
