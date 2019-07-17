import UIKit
import ActionSheet

class ManageWalletsNoAccountViewController: ActionSheetController {
    private let titleItem = ActionTitleItem(tag: 0)
    private let coin: Coin

    init(coin: Coin, onSelectNew: @escaping () -> (), onSelectRestore: @escaping () -> ()) {
        self.coin = coin

        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        model.addItemView(titleItem)

        let newItem = AlertButtonItem(
                tag: 1,
                title: "New",
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
                tag: 2,
                title: "Restore",
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

        titleItem.bindTitle?("Add \(coin.title.localized) Coin", coin)
    }

}
