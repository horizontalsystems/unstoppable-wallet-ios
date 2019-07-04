import UIKit
import ActionSheet

enum AlertItem { case header(String), row(String) }

protocol IAlertView: class {
    func setSelected(index: Int)
}

protocol IAlertViewDelegate {
    var items: [AlertItem] { get }

    func onDidLoad()
    func onSelect(index: Int)
}

class AlertViewController: ActionSheetController {
    private let delegate: IAlertViewDelegate

    private var items = [TextSelectItem]()

    init(delegate: IAlertViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.alertConfig)

        initItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initItems() {
        delegate.items.forEach {
            switch $0 {
            case .header(let title): addHeader(title: title)
            case .row(let title): addRow(title: title)
            }
        }
    }

    private func addHeader(title: String) {
        let item = TextSelectItem(
                text: title.localized,
                font: AppTheme.alertHeaderFont,
                color: AppTheme.alertHeaderColor,
                height: AppTheme.alertHeaderHeight,
                tag: -1)
        model.addItemView(item)
    }

    private func addRow(title: String) {
        let index = items.count
        let item = TextSelectItem(text: title.localized, font: AppTheme.alertCellFont, color: AppTheme.alertCellDefaultColor, height: AppTheme.alertCellHeight, tag: index) { [weak self] view in
            self?.handleToggle(index: index)
        }

        model.addItemView(item)
        items.append(item)
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = AppTheme.alertBackgroundColor
        contentBackgroundColor = .white

        delegate.onDidLoad()
    }

    private func handleToggle(index: Int) {
        delegate.onSelect(index: index)
    }

}

extension AlertViewController: IAlertView {

    func setSelected(index: Int) {
        items.forEach { $0.selected = false }
        items[index].selected = true
        model.reload?()
    }

}
