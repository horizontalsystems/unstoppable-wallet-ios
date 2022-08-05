import UIKit
import SnapKit
import SectionsTableView
import ThemeKit
import ComponentKit

class DoubleSpendInfoViewController: ThemeViewController {
    private let transactionHash: String
    private let conflictingTransactionHash: String

    private let tableView = SectionsTableView(style: .grouped)

    init(transactionHash: String, conflictingTransactionHash: String) {
        self.transactionHash = transactionHash
        self.conflictingTransactionHash = conflictingTransactionHash

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "double_spend_info.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    @objc private func onClose() {
        dismiss(animated: true)
    }

}

extension DoubleSpendInfoViewController: SectionsDataSource {

    private func row(id: String, title: String, value: String, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = title
                    },
                    .secondaryButton { component in
                        component.button.set(style: .default)
                        component.button.setTitle(value.shortened, for: .normal)
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: value)
                        }
                    }
                ]),
                tableView: tableView,
                id: id,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "alert",
                    rows: [
                        tableView.highlightedDescriptionRow(id: "alert", text: "double_spend_info.header".localized)
                    ]
            ),
            Section(
                    id: "hashes",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        row(
                                id: "tx-hash",
                                title: "double_spend_info.this_hash".localized,
                                value: transactionHash,
                                isFirst: true,
                                isLast: false
                        ),
                        row(
                                id: "conflicting-tx-hash",
                                title: "double_spend_info.conflicting_hash".localized,
                                value: conflictingTransactionHash,
                                isFirst: false,
                                isLast: true
                        )
                    ]
            )
        ]
    }

}
