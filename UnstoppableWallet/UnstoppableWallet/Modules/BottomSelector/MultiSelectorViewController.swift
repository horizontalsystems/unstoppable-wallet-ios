import UIKit
import ThemeKit
import SectionsTableView
import ComponentKit

class MultiSelectorViewController: ThemeViewController {
    private let values: [String]
    private var currentIndexes = Set<Int>()
    private let onFinish: ([Int]) -> ()

    private let tableView = SectionsTableView(style: .grouped)

    init(title: String, viewItems: [ViewItem], onFinish: @escaping ([Int]) -> ()) {
        values = viewItems.map { $0.value }

        for (index, viewItem) in viewItems.enumerated() {
            if viewItem.selected {
                currentIndexes.insert(index)
            }
        }

        self.onFinish = onFinish

        super.init()

        self.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDone))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.buildSections()
    }

    @objc private func onTapDone() {
        onFinish(Array(currentIndexes))
        dismiss(animated: true)
    }

    private func onTap(index: Int) {
        if currentIndexes.contains(index) {
            currentIndexes.remove(index)
        } else {
            currentIndexes.insert(index)
        }

        tableView.reload(animated: true)
    }

    private func onTapAny() {
        currentIndexes.removeAll()
        tableView.reload(animated: true)
    }

}

extension MultiSelectorViewController: SectionsDataSource {

    private func row(id: String, isFirst: Bool, isLast: Bool, value: String, valueColor: UIColor, selected: Bool, action: @escaping () -> ()) -> RowProtocol {
        tableView.universalRow48(
                id: id,
                title: .body(value, color: valueColor),
                accessoryType: .check(selected),
                hash: "\(selected)",
                autoDeselect: true,
                isFirst: isFirst,
                isLast: isLast,
                action: action
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        row(
                                id: "any-row",
                                isFirst: true,
                                isLast: false,
                                value: "market.advanced_search.any".localized,
                                valueColor: .themeGray,
                                selected: currentIndexes.isEmpty,
                                action: { [weak self] in
                                    self?.onTapAny()
                                }
                        )
                    ] + values.enumerated().map { index, value in
                        row(
                                id: "item_\(index)",
                                isFirst: false,
                                isLast: index == values.count - 1,
                                value: value,
                                valueColor: .themeLeah,
                                selected: currentIndexes.contains(index),
                                action: { [weak self] in
                                    self?.onTap(index: index)
                                }
                        )
                    }
            )
        ]
    }

}

extension MultiSelectorViewController {

    struct ViewItem {
        let value: String
        let selected: Bool
    }

}
