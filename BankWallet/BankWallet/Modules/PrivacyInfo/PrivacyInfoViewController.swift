import UIKit
import SectionsTableView
import ThemeKit

class PrivacyInfoViewController: ThemeViewController {
    let delegate: IPrivacyInfoViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var sortMode: String?
    private var connectionItems: [PrivacyViewItem]?
    private var syncModeItems: [PrivacyViewItem]?

    private let headers: [String] = [
        "settings_privacy_info.header_blockchain_transactions".localized,
        "settings_privacy_info.header_blockchain_connection".localized,
        "settings_privacy_info.header_blockchain_restore".localized
    ]
    private let cells: [String] = [
        "settings_privacy_info.content_blockchain_transactions".localized,
        "settings_privacy_info.content_blockchain_connection".localized,
        "settings_privacy_info.content_blockchain_restore".localized
    ]

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

        tableView.registerHeaderFooter(forClass: PrivacyInfoHeaderView.self)
        tableView.registerCell(forClass: PrivacyInfoCell.self)

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.reload()
    }

    @objc private func onClose() {
        delegate.onClose()
    }

    private func section(title: String, text: String, first: Bool) -> SectionProtocol {
        Section(
                id: title,
                headerState: header(hash: title, text: title, first: first),
                rows: [
                    row(id: text, text: text)
                ]
        )
    }

    private func header(hash: String, text: String, first: Bool) -> ViewState<PrivacyInfoHeaderView> {
        let width = view.bounds.width
        return .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text, first: first)
                }, dynamicHeight: { _ in
                    PrivacyInfoHeaderView.height(containerWidth: width, text: text)
                }
        )
    }

    private func row(id: String, text: String) -> RowProtocol {
        let width = view.bounds.width
        return Row<PrivacyInfoCell>(id: id, hash: text, dynamicHeight: { _ in
            PrivacyInfoCell.height(containerWidth: width, text: text)
        }, bind: { cell, _ in
            cell.bind(text: text)
        })
    }

}

extension PrivacyInfoViewController: IPrivacyInfoView {

}

extension PrivacyInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
          zip(headers, cells).enumerated().map { tuple -> SectionProtocol in
              section(title: tuple.element.0, text: tuple.element.1, first: tuple.offset == 0)
          }
    }

}
