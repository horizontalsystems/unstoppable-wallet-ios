import UIKit
import SectionsTableView
import ThemeKit

class TransactionStatusInfoViewController: ThemeViewController {
    private let tableView = SectionsTableView(style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "status_info.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerHeaderFooter(forClass: InfoHeaderView.self)
        tableView.registerCell(forClass: DescriptionCell.self)

        tableView.sectionDataSource = self

        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func header(text: String) -> ViewState<InfoHeaderView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { width in
                    InfoHeaderView.height(containerWidth: width, text: text)
                }
        )
    }

    private func row(text: String) -> RowProtocol {
        Row<DescriptionCell>(
                id: text,
                dynamicHeight: { width in
                    DescriptionCell.height(containerWidth: width, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

}

extension TransactionStatusInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "pending",
                    headerState: header(text: "status_info.pending.title".localized),
                    rows: [
                        row(text: "status_info.pending.content".localized)
                    ]
            ),
            Section(
                    id: "sending-receiving",
                    headerState: header(text: "status_info.sending_receiving.title".localized),
                    rows: [
                        row(text: "status_info.sending_receiving.content".localized)
                    ]
            ),
            Section(
                    id: "confirmed",
                    headerState: header(text: "status_info.confirmed.title".localized),
                    rows: [
                        row(text: "status_info.confirmed.content".localized)
                    ]
            ),
            Section(
                    id: "failed",
                    headerState: header(text: "status_info.failed.title".localized),
                    footerState: .margin(height: .margin8x),
                    rows: [
                        row(text: "status_info.failed.content".localized)
                    ]
            )
        ]
    }

}
