import ComponentKit
import SectionsTableView
import ThemeKit
import UIKit

class MultiSelectorViewController: ThemeViewController {
    private let viewItems: [SelectorModule.ViewItem]
    private var currentIndexes = Set<Int>()
    private let onFinish: ([Int]) -> Void

    private let tableView = SectionsTableView(style: .grouped)

    init(title: String, viewItems: [SelectorModule.ViewItem], onFinish: @escaping ([Int]) -> Void) {
        self.viewItems = viewItems

        for (index, viewItem) in viewItems.enumerated() {
            if viewItem.selected {
                currentIndexes.insert(index)
            }
        }

        self.onFinish = onFinish

        super.init()

        self.title = title
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
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
    func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "main",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: [
                    tableView.universalRow48(
                        id: "any",
                        title: .body("selector.any".localized),
                        accessoryType: .check(currentIndexes.isEmpty),
                        hash: "\(currentIndexes.isEmpty)",
                        autoDeselect: true,
                        isFirst: true,
                        action: { [weak self] in
                            self?.onTapAny()
                        }
                    ),
                ] + viewItems.enumerated().map { index, viewItem in
                    SelectorModule.row(
                        viewItem: viewItem,
                        tableView: tableView,
                        selected: currentIndexes.contains(index),
                        backgroundStyle: .lawrence,
                        index: index,
                        isLast: index == viewItems.count - 1
                    ) { [weak self] in
                        self?.onTap(index: index)
                    }
                }
            ),
        ]
    }
}
