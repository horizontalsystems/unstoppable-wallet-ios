import UIKit
import ActionSheet

enum BottomAlertItemType {
    case title(title: String, subtitle: String, icon: UIImage?, iconTint: UIColor)
    case description(text: String)
    case checkbox(description: String)
    case button(title: String, button: UIButton, onTap: (Int?) -> ())
    case radio(title: String, subtitle: String, selected: Bool)
}

class BottomAlertViewController: WalletActionSheetController {
    private var checkboxItems = [ConfirmationCheckboxItem]()
    private let checkboxAttributes = [NSAttributedString.Key.foregroundColor: UIColor.themeOz, NSAttributedString.Key.font: UIFont.subhead2]

    private var radioItems = [RadioItem]()

    private var buttonItems = [AlertButtonItem]()

    init(items: [BottomAlertItemType]) {
        super.init(withModel: BaseAlertModel())

        items.enumerated().forEach { index, item in
            switch item {
            case let .title(title, subtitle, icon, iconTint):
                model.addItemView(AlertTitleItem(
                        title: title,
                        subtitle: subtitle,
                        icon: icon?.withRenderingMode(.alwaysTemplate),
                        iconTintColor: iconTint,
                        tag: index,
                        onClose: { [weak self] in
                            self?.dismiss(byFade: false)
                        }
                ))
            case let .description(text):
                model.addItemView(AlertTextItem(text: text, tag: index))
            case let .checkbox(description):
                let attributedDescription = NSAttributedString(string: description, attributes: checkboxAttributes)
                let checkboxIndex = checkboxItems.count
                let checkboxItem = ConfirmationCheckboxItem(descriptionText: attributedDescription, tag: index) { [weak self] view in
                    self?.handleToggleCheckbox(index: checkboxIndex)
                }
                checkboxItems.append(checkboxItem)
                model.addItemView(checkboxItem)
            case let .button(title, button, onTap):
                let buttonItem = AlertButtonItem(
                        tag: 2,
                        title: title,
                        createButton: { button },
                        insets: UIEdgeInsets(top: CGFloat.margin4x, left: CGFloat.margin4x, bottom: CGFloat.margin4x, right: CGFloat.margin4x)
                ) { [weak self] in
                    let selectedRadioIndex: Int? = self?.radioItems.enumerated().compactMap { index, item in
                        item.selected ? index : nil
                    }.first
                    onTap(selectedRadioIndex)
                    self?.dismiss(animated: true)
                }
                buttonItems.append(buttonItem)
                model.addItemView(buttonItem)
            case let .radio(title, subtitle, selected):
                let radioIndex = radioItems.count
                let radioItem = RadioItem(title: title, subtitle: subtitle, selected: selected, tag: index) { [weak self] view in
                    self?.handleToggleRadio(index: radioIndex)
                }
                radioItems.append(radioItem)
                model.addItemView(radioItem)
            }
        }
        syncButtonItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentBackgroundColor = .white
    }

    private func handleToggleCheckbox(index: Int) {
        checkboxItems[index].checked = !checkboxItems[index].checked
        syncButtonItems()
        model.reload?()
    }

    private func handleToggleRadio(index: Int) {
        for (itemIndex, item) in radioItems.enumerated() {
            item.selected = itemIndex == index
        }
        model.reload?()
    }

    private func syncButtonItems() {
        buttonItems.forEach {
            $0.isEnabled = checkboxItems.filter { $0.checked == false }.isEmpty
        }
    }

}
