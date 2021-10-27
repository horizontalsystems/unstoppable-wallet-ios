import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import ComponentKit

class CoinPageInfoViewController: ThemeViewController {
    private let header: String
    private let viewItems: [CoinDetailsViewModel.SecurityInfoViewItem]

    private let tableView = SectionsTableView(style: .grouped)

    init(header: String, viewItems: [CoinDetailsViewModel.SecurityInfoViewItem]) {
        self.header = header
        self.viewItems = viewItems

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_page.info".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapCloseButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: BCell.self)
        tableView.registerCell(forClass: CoinPageInfoCell.self)

        tableView.buildSections()
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

}

extension CoinPageInfoViewController: SectionsDataSource {

    private func headerRow(title: String) -> RowProtocol {
        Row<BCell>(
                id: "header_cell_\(title)",
                hash: title,
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent)
                    cell.selectionStyle = .none
                    cell.title = title
                }
        )
    }

    private func row(viewItem: CoinDetailsViewModel.SecurityInfoViewItem) -> RowProtocol {
        Row<CoinPageInfoCell>(
                id: viewItem.title,
                dynamicHeight: { width in
                    CoinPageInfoCell.height(containerWidth: width, description: viewItem.text)
                },
                bind: { cell, _ in
                    cell.bind(viewItem: viewItem)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "header",
                    headerState: .margin(height: .margin12),
                    rows: [
                        headerRow(title: header)

                    ]
            ),
            Section(
                    id: "items",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin8),
                    rows: viewItems.map {
                        row(viewItem: $0)
                    }
            )
        ]
    }

}
