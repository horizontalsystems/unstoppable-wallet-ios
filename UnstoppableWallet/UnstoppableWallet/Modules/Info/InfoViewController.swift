import ComponentKit
import SectionsTableView
import ThemeKit
import UIKit

class InfoViewController: ThemeViewController {
    private let viewItems: [InfoModule.ViewItem]

    private let tableView = SectionsTableView(style: .grouped)

    init(viewItems: [InfoModule.ViewItem]) {
        self.viewItems = viewItems

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: MarkdownHeader1Cell.self)
        tableView.registerCell(forClass: MarkdownHeader3Cell.self)
        tableView.registerCell(forClass: MarkdownTextCell.self)
        tableView.registerCell(forClass: MarkdownListItemCell.self)

        tableView.sectionDataSource = self
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    @objc private func onClose() {
        dismiss(animated: true)
    }
}

extension InfoViewController: SectionsDataSource {
    public func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "section",
                footerState: .margin(height: .margin32),
                rows: rows()
            ),
        ]
    }

    private func rows() -> [RowProtocol] {
        viewItems.enumerated().map { index, viewItem in
            switch viewItem {
            case let .header1(text):
                return MarkdownViewController.header1Row(id: "header-\(index)", string: text)
            case let .header3(text):
                return MarkdownViewController.header3Row(id: "header-\(index)", string: text)
            case let .text(text):
                return MarkdownViewController.textRow(id: "text-\(index)", string: text)
            case let .listItem(text):
                return MarkdownViewController.listItemRow(id: "list-item-\(index)", string: text)
            }
        }
    }
}
