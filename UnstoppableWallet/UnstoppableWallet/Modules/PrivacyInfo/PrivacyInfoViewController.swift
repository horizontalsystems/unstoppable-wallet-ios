import UIKit
import SectionsTableView
import ThemeKit

class PrivacyInfoViewController: ThemeViewController {
    private let delegate: IPrivacyInfoViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: IPrivacyInfoViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_privacy_info.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerHeaderFooter(forClass: PrivacyInfoSeparatorHeaderView.self)
        tableView.registerHeaderFooter(forClass: PrivacyInfoHeaderView.self)
        tableView.registerCell(forClass: PrivacyInfoCell.self)

        tableView.sectionDataSource = self

        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    @objc private func onClose() {
        delegate.onTapClose()
    }

    private func header(text: String) -> ViewState<PrivacyInfoHeaderView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { width in
                    PrivacyInfoHeaderView.height(containerWidth: width, text: text)
                }
        )
    }

    private func row(text: String) -> RowProtocol {
        Row<PrivacyInfoCell>(
                id: text,
                dynamicHeight: { width in
                    PrivacyInfoCell.height(containerWidth: width, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

}

extension PrivacyInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let separatorHeaderState: ViewState<PrivacyInfoSeparatorHeaderView> = .cellType(
                hash: "separator",
                binder: nil,
                dynamicHeight: { _ in
                    PrivacyInfoSeparatorHeaderView.height
                }
        )

        return [
            Section(
                    id: "description",
                    headerState: separatorHeaderState,
                    rows: [row(text: "settings_privacy_info.description".localized)]
            ),
            Section(
                    id: "transactions",
                    headerState: header(text: "settings_privacy_info.header_blockchain_transactions".localized),
                    rows: [row(text: "settings_privacy_info.content_blockchain_transactions".localized)]
            ),
            Section(
                    id: "connection",
                    headerState: header(text: "settings_privacy_info.header_blockchain_connection".localized),
                    rows: [row(text: "settings_privacy_info.content_blockchain_connection".localized)]
            ),
            Section(
                    id: "restore",
                    headerState: header(text: "settings_privacy_info.header_blockchain_restore".localized),
                    footerState: .margin(height: .margin8x),
                    rows: [row(text: "settings_privacy_info.content_blockchain_restore".localized)]
            )
        ]
    }

}
