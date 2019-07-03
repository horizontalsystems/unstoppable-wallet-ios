import UIKit
import ActionSheet

class CreateAccountViewController: ActionSheetController {
    private let delegate: ICreateAccountViewDelegate

    init(delegate: ICreateAccountViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = AppTheme.actionSheetBackgroundColor
        contentBackgroundColor = .white

        if delegate.showNew {
            let newItem = AlertButtonItem(
                    tag: 0,
                    title: "New",
                    textStyle: ButtonTheme.textColorOnWhiteBackgroundDictionary,
                    backgroundStyle: ButtonTheme.yellowBackgroundOnWhiteBackgroundDictionary
            ) { [weak self] in
                self?.delegate.didTapNew()
            }
            newItem.isActive = true

            model.addItemView(newItem)
        }

        let restoreItem = AlertButtonItem(
                tag: 0,
                title: "Restore",
                textStyle: ButtonTheme.textColorOnWhiteBackgroundDictionary,
                backgroundStyle: ButtonTheme.yellowBackgroundOnWhiteBackgroundDictionary
        ) { [weak self] in
            self?.delegate.didTapRestore()
        }
        restoreItem.isActive = true

        model.addItemView(restoreItem)
    }

}

extension CreateAccountViewController: ICreateAccountView {
}
