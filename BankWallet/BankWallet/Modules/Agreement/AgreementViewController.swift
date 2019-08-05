import UIKit
import ActionSheet

class AgreementViewController: ActionSheetController {
    private let delegate: IAgreementViewDelegate

    private var items = [ConfirmationCheckboxItem]()
    private var buttonItem: AlertButtonItem?

    init(delegate: IAgreementViewDelegate) {
        self.delegate = delegate

        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)
        initItems()
    }

    func initItems() {
        var texts = [NSAttributedString]()

        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2.2
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: ConfirmationTheme.textColor,
            NSAttributedString.Key.font: ConfirmationTheme.regularFont,
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.kern: -0.2
        ]
        texts.append(NSMutableAttributedString(string: "backup.confirmation.secret_key".localized, attributes: attributes))
        texts.append(NSAttributedString(string: "backup.confirmation.delete_app_warn".localized, attributes: attributes))
        texts.append(NSAttributedString(string: "backup.confirmation.disclaimer".localized, attributes: attributes))

        for (index, text) in texts.enumerated() {
            let item = ConfirmationCheckboxItem(descriptionText: text, tag: index) { [weak self] view in
                self?.handleToggle(index: index)
            }

            model.addItemView(item)
            items.append(item)
        }

        let buttonItem = AlertButtonItem(
                tag: texts.count,
                title: "button.confirm".localized,
                textStyle: ButtonTheme.textColorDictionary,
                backgroundStyle: ButtonTheme.yellowBackgroundDictionary
        ) { [weak self] in
            self?.delegate.didTapConfirm()
        }

        model.addItemView(buttonItem)
        self.buttonItem = buttonItem
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = AppTheme.actionSheetBackgroundColor
        contentBackgroundColor = .white
    }

    private func handleToggle(index: Int) {
        items[index].checked = !items[index].checked
        buttonItem?.isActive = items.filter { $0.checked == false }.isEmpty
        model.reload?()
    }

}

extension AgreementViewController: IAgreementView {
}
