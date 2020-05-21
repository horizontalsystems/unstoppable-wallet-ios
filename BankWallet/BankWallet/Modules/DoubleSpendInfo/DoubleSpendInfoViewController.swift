import UIKit
import SectionsTableView
import UIExtensions
import HUD
import SnapKit
import RxSwift
import ThemeKit

class DoubleSpendInfoViewController: ThemeViewController, SectionsDataSource {
    private let delegate: IDoubleSpendInfoViewDelegate

    let tableView = SectionsTableView(style: .grouped)

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

        tableView.registerCell(forClass: DoubleSpendInfoCell.self)
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none

        tableView.reload()
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
                        Row<DoubleSpendInfoCell>(
                                id: "row_txHash",
                                height: .heightSingleLineCell,
                                bind: { [unowned self] cell, _ in
                                    cell.bind(
                                            title: "double_spend_info.this_hash".localized,
                                            hash: self.delegate.txHash,
                                            last: false,
                                            onTap: { [weak self] in
                                                self?.onTapHash()
                                            }
                                    )
                                }
                        ),
                        Row<DoubleSpendInfoCell>(
                                id: "row_conflictingTxHash",
                                height: .heightSingleLineCell,
                                bind: { [unowned self] cell, _ in
                                    cell.bind(
                                            title: "double_spend_info.conflicting_hash".localized,
                                            hash: self.delegate.conflictingTxHash,
                                            last: true,
                                            onTap: { [weak self] in
                                                self?.onConflictingTapHash()
                                            }
                                    )
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
        delegate.onConflictingTapHash()
    }

    @objc func onClose() {
        dismiss(animated: true)
    }

}


extension DoubleSpendInfoViewController: IDoubleSpendInfoView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
