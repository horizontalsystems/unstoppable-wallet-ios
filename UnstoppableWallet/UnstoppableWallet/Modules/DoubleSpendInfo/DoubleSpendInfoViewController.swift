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
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none

        delegate.onLoad()

        tableView.buildSections()
    }

    private var header: ViewState<TopDescriptionHeaderFooterView> {
        let descriptionText = "double_spend_info.header".localized

        return .cellType(
                hash: "top_description",
                binder: { view in
                    view.bind(text: descriptionText)
                }, dynamicHeight: { containerWidth in
                    TopDescriptionHeaderFooterView.height(containerWidth: containerWidth, text: descriptionText)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "hashes",
                    headerState: header,
                    footerState: .margin(height: .margin6x),
                    rows: [
                        Row<D9Cell>(
                                id: "row_txHash",
                                height: .heightCell48,
                                bind: { [weak self] cell, _ in
                                    cell.set(backgroundStyle: .lawrence, isFirst: true)
                                    cell.title = "double_spend_info.this_hash".localized
                                    cell.viewItem = CopyableSecondaryButton.ViewItem(value: self?.transactionHash ?? "")
                                }
                        ),
                        Row<D9Cell>(
                                id: "row_conflictingTxHash",
                                height: .heightCell48,
                                bind: { [weak self] cell, _ in
                                    cell.set(backgroundStyle: .lawrence, isLast: true)
                                    cell.title = "double_spend_info.conflicting_hash".localized
                                    cell.viewItem = CopyableSecondaryButton.ViewItem(value: self?.conflictingTransactionHash ?? "")
                                }
                        )
                    ]
            )
        ]
    }

    func onTapHash() {
        delegate.onTapHash()
    }

    func onConflictingTapHash() {
        delegate.onTapConflictingHash()
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
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
