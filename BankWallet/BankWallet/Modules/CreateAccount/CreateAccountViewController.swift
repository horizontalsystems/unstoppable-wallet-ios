import UIKit
import ActionSheet

class CreateAccountViewController: ActionSheetController {
    private let delegate: ICreateAccountViewDelegate
    private let titleItem = ActionTitleItem(tag: 0)

    init(delegate: ICreateAccountViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        initItems()
    }

    func initItems() {
        model.addItemView(titleItem)

        if delegate.showNew {
            let newItem = AlertButtonItem(
                    tag: 1,
                    title: "New",
                    textStyle: ButtonTheme.textColorDictionary,
                    backgroundStyle: ButtonTheme.yellowBackgroundDictionary,
                    insets: UIEdgeInsets(top: ButtonTheme.verticalMargin, left: ButtonTheme.margin, bottom: ButtonTheme.insideMargin, right: ButtonTheme.margin)
            ) { [weak self] in
                self?.delegate.didTapNew()
            }
            newItem.isActive = true

            model.addItemView(newItem)
        }

        let restoreItem = AlertButtonItem(
                tag: 2,
                title: "Restore",
                textStyle: ButtonTheme.textColorDictionary,
                backgroundStyle: ButtonTheme.grayBackgroundDictionary,
                insets: UIEdgeInsets(top: delegate.showNew ? ButtonTheme.insideMargin : ButtonTheme.verticalMargin, left: ButtonTheme.margin, bottom: ButtonTheme.verticalMargin, right: ButtonTheme.margin)
        ) { [weak self] in
            self?.delegate.didTapRestore()
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

        delegate.viewDidLoad()
    }

}

extension CreateAccountViewController: ICreateAccountView {

    func setTitle(for coin: Coin) {
        titleItem.bindTitle?("Add \(coin.title.localized) Coin", coin)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}
