import UIKit
import ThemeKit
import ComponentKit
import SectionsTableView

class SingleSelectorViewController: ThemeViewController {
    private let viewItems: [ViewItem]
    private let onSelect: (Int) -> ()

    private let tableView = SectionsTableView(style: .grouped)

    init(title: String, viewItems: [ViewItem], onSelect: @escaping (Int) -> ()) {
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .done, target: self, action: #selector(onTapClose))

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

    private func onTap(index: Int) {
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
                        tableView.universalRow48(
                                id: "item-\(index)",
                                image: .url(viewItem.imageUrl),
                                title: .body(viewItem.title),
                                accessoryType: .check(viewItem.selected),
                                isFirst: index == 0,
                                isLast: index == viewItems.count - 1,
                                action: { [weak self] in
                                    self?.onTap(index: index)
                                }
                        )
                    }
            )
        ]
    }

}

extension SingleSelectorViewController {

    struct ViewItem {
        let imageUrl: String
        let title: String
        let selected: Bool
    }

}
