import UIKit
import SectionsTableView
import UIExtensions
import HUD
import SnapKit
import RxSwift
import ThemeKit
import ComponentKit

class DoubleSpendInfoViewController: ThemeViewController, SectionsDataSource {
    private let delegate: IDoubleSpendInfoViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var transactionHash: String?
    private var conflictingTransactionHash: String?

    public init(delegate: IDoubleSpendInfoViewDelegate) {
        self.delegate = delegate
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
        tableView.backgroundColor = .clear
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: D9Cell.self)
        tableView.registerCell(forClass: HighlightedDescriptionCell.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none

        delegate.onLoad()

        tableView.buildSections()
    }

    private func highlightedDescriptionRow(text: String) -> RowProtocol {
        Row<HighlightedDescriptionCell>(
                id: "alert",
                dynamicHeight: { width in
                    HighlightedDescriptionCell.height(containerWidth: width, text: text)
                },
                bind: { cell, _ in
                    cell.descriptionText = text
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "alert",
                    rows: [
                        highlightedDescriptionRow(text: "double_spend_info.header".localized)
                    ]
            ),
            Section(
                    id: "hashes",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin6x),
                    rows: [
                        Row<D9Cell>(
                                id: "row_txHash",
                                height: .heightCell48,
                                bind: { [weak self] cell, _ in
                                    cell.set(backgroundStyle: .lawrence, isFirst: true)
                                    cell.title = "double_spend_info.this_hash".localized
                                    cell.viewItem = .init(type: .raw, value: { [weak self] in self?.transactionHash ?? "" })
                                }
                        ),
                        Row<D9Cell>(
                                id: "row_conflictingTxHash",
                                height: .heightCell48,
                                bind: { [weak self] cell, _ in
                                    cell.set(backgroundStyle: .lawrence, isLast: true)
                                    cell.title = "double_spend_info.conflicting_hash".localized
                                    cell.viewItem = .init(type: .raw, value: { [weak self] in self?.conflictingTransactionHash ?? "" })
                                }
                        )
                    ]
            )
        ]
    }

    @objc func onClose() {
        dismiss(animated: true)
    }

}


extension DoubleSpendInfoViewController: IDoubleSpendInfoView {

    func set(transactionHash: String, conflictingTransactionHash: String) {
        self.transactionHash = transactionHash
        self.conflictingTransactionHash = conflictingTransactionHash
    }

    func showCopied() {
        HudHelper.instance.show(banner: .copied)
    }

}
