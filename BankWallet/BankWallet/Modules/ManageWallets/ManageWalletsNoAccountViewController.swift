import UIKit
import ActionSheet

class ManageWalletsNoAccountViewController: ActionSheetController {
    private let titleItem = ActionTitleItem(tag: 0)
    private let coin: Coin

    init(coin: Coin, onSelectManageKeys: @escaping () -> ()) {
        self.coin = coin

        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        model.addItemView(titleItem)

        let manageKeysItem = AlertButtonItem(
                tag: 1,
                title: "Go to Manage Keys",
                textStyle: ButtonTheme.textColorDictionary,
                backgroundStyle: ButtonTheme.yellowBackgroundDictionary,
                insets: UIEdgeInsets(top: ButtonTheme.verticalMargin, left: ButtonTheme.margin, bottom: ButtonTheme.verticalMargin, right: ButtonTheme.margin)
        ) { [weak self] in
            self?.dismiss(animated: true) {
                onSelectManageKeys()
            }
        }
        manageKeysItem.isActive = true

        model.addItemView(manageKeysItem)
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
