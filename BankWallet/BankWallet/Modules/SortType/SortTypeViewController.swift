import UIKit
import ActionSheet

class SortTypeViewController: ActionSheetController {
    private let delegate: ISortTypeViewDelegate

    private var items = [TextSelectItem]()

    init(delegate: ISortTypeViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: BalanceTheme.sortTypeSheetConfig)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = AppTheme.actionSheetBackgroundColor
        contentBackgroundColor = .white

        var texts = [String]()

        texts.append("balance.sort.value".localized)
        texts.append("balance.sort.az".localized)
        texts.append("balance.sort.manual".localized)

        for (index, text) in texts.enumerated() {
            let item = TextSelectItem(text: text, tag: index) { [weak self] view in
                self?.handleToggle(index: index)
            }

            model.addItemView(item)
            items.append(item)
        }
    }

    private func handleToggle(index: Int) {
        delegate.onSelect(sort: convert(index: index))
    }

    private func convert(index: Int) -> BalanceSortType {
        switch index {
        case 0: return .value
        case 1: return .az
        case 2: return .manual
        default: return .manual
        }
    }

    private func convert(type: BalanceSortType) -> Int {
        switch type {
        case .value: return 0
        case .az: return 1
        case .manual: return 2
        }
    }

}

extension SortTypeViewController: ISortTypeView {

    func set(selected type: BalanceSortType) {
        items.forEach { $0.selected = false }
        items[convert(type: type)].selected = true
        model.reload?()
    }

}
