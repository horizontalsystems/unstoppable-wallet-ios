import UIKit
import ThemeKit
import ComponentKit
import SectionsTableView

class SingleSelectorViewController: ThemeViewController {
    private let viewItems: [SelectorModule.ViewItem]
    private let onSelect: (Int) -> ()

    private let tableView = SectionsTableView(style: .grouped)

    init(title: String, viewItems: [SelectorModule.ViewItem], onSelect: @escaping (Int) -> ()) {
        self.viewItems = viewItems
        self.onSelect = onSelect

        super.init()

        self.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        tableView.buildSections()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func onSelect(index: Int) {
        onSelect(index)
        dismiss(animated: true)
    }

}

extension SingleSelectorViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        SelectorModule.row(
                                viewItem: viewItem,
                                tableView: tableView,
                                selected: viewItem.selected,
                                backgroundStyle: .lawrence,
                                index: index,
                                isFirst: index == 0,
                                isLast: index == viewItems.count - 1
                        ) { [weak self] in
                            self?.onSelect(index: index)
                        }
                    }
            )
        ]
    }

}
