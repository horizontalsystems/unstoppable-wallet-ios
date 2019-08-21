import UIKit
import ActionSheet

class ManageWalletsNoAccountViewController: ActionSheetController {
    private let titleItem = ActionTitleItem(tag: 0)
    private let textItem: AlertTextItem
    private let coin: Coin

    init(coin: Coin, predefinedAccountType: IPredefinedAccountType, onSelectNew: @escaping () -> (), onSelectRestore: @escaping () -> ()) {
        self.coin = coin

        textItem = AlertTextItem(text: "manage_coins.add_coin.text".localized(coin.title, predefinedAccountType.title.localized, predefinedAccountType.title.localized, coin.title), tag: 1)

        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        model.addItemView(titleItem)
        model.addItemView(textItem)

        let newItem = AlertButtonItem(
                tag: 2,
                title: "manage_coins.add_coin.create".localized,
                textStyle: ButtonTheme.textColorDictionary,
                backgroundStyle: ButtonTheme.yellowBackgroundDictionary,
                insets: UIEdgeInsets(top: ButtonTheme.verticalMargin, left: ButtonTheme.margin, bottom: ButtonTheme.insideMargin, right: ButtonTheme.margin)
        ) { [weak self] in
            self?.dismiss(animated: true) {
                onSelectNew()
            }
        }
        newItem.isActive = true

        model.addItemView(newItem)

        let restoreItem = AlertButtonItem(
                tag: 3,
                title: "manage_coins.add_coin.restore".localized,
                textStyle: ButtonTheme.textColorDictionary,
                backgroundStyle: ButtonTheme.grayBackgroundDictionary,
                insets: UIEdgeInsets(top: ButtonTheme.insideMargin, left: ButtonTheme.margin, bottom: ButtonTheme.verticalMargin, right: ButtonTheme.margin)
        ) { [weak self] in
            self?.dismiss(animated: true) {
                onSelectRestore()
            }
        }
        restoreItem.isActive = true

        model.addItemView(restoreItem)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = AppTheme.actionSheetBackgroundColor
        contentBackgroundColor = .white

        titleItem.bindTitle?("manage_coins.add_coin.title".localized(coin.title), coin)
    }

}
