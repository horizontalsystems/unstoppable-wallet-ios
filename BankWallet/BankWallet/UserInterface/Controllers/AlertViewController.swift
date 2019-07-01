import UIKit
import ActionSheet

protocol IAlertView: class {
    func addHeader(title: String)
    func addRow(title: String)
    func setSelected(index: Int)
}

protocol IAlertViewDelegate {
    func onDidLoad(_ delegate: IAlertView)
    func onWillAppear()
    func onSelect(index: Int)
}

class AlertViewController: ActionSheetController {
    private let delegate: IAlertViewDelegate

    private var items = [TextSelectItem]()

    init(delegate: IAlertViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.alertConfig)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = AppTheme.alertBackgroundColor
        contentBackgroundColor = .white

        delegate.onDidLoad(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        delegate.onWillAppear()
    }

    private func handleToggle(index: Int) {
        delegate.onSelect(index: index)
    }

}

extension AlertViewController: IAlertView {

    func addHeader(title: String) {
        let item = TextSelectItem(
                text: title.localized,
                font: AppTheme.alertHeaderFont,
                color: AppTheme.alertHeaderColor,
                height: AppTheme.alertHeaderHeight,
                tag: -1)
        model.addItemView(item)
    }

    func addRow(title: String) {
        let index = items.count
        let item = TextSelectItem(text: title.localized, font: AppTheme.alertCellFont, color: AppTheme.alertCellDefaultColor, height: AppTheme.alertCellHeight, tag: index) { [weak self] view in
            self?.handleToggle(index: index)
        }

        model.addItemView(item)
        items.append(item)
    }

    func setSelected(index: Int) {
        items.forEach { $0.selected = false }
        items[index].selected = true
        model.reload?()
    }

}
