import UIKit
import SectionsTableView
import ThemeKit

class ContactViewController: ThemeViewController {
    private let delegate: IContactViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var email: String?
    private var telegramWalletHelpAccount: String?

    init(delegate: IContactViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.contact.title".localized

        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        tableView.registerCell(forClass: ImageDoubleLineCell.self)
        tableView.registerCell(forClass: TitleCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
        tableView.buildSections()
    }

    private var reportRows: [RowProtocol] {
        [
            Row<ImageDoubleLineCell>(
                    id: "email",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { [weak self] cell, _ in
                        cell.bind(
                                image: UIImage(named: "Email Icon")?.tinted(with: .themeJacob),
                                title: "settings.contact.email".localized,
                                subtitle: self?.email
                        )
                    },
                    action: { [weak self] _ in
                        self?.delegate.didTapEmail()
                    }
            ),
            Row<ImageDoubleLineCell>(
                    id: "telegram_wallet_help",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { [weak self] cell, _ in
                        cell.bind(
                                image: UIImage(named: "Telegram Icon")?.tinted(with: .themeJacob),
                                title: "settings.contact.telegram_wallet".localized,
                                subtitle: self?.telegramWalletHelpAccount,
                                last: true
                        )
                    },
                    action: { [weak self] _ in
                        self?.delegate.didTapTelegramWalletHelp()
                    }
            )
        ]
    }

    private var debugRows: [RowProtocol] {
        [
            Row<TitleCell>(id: "debug_background_log", height: .heightSingleLineCell, autoDeselect: true, bind: { cell, _ in
                cell.bind(titleIcon: nil, title: "Show Log", showDisclosure: false, last: true)
            }, action: { [weak self] _ in
                self?.showDebugLog()
            })
        ]
    }

    private func showDebugLog() {
        delegate.didTapDebugLog()
    }

}

extension ContactViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(id: "report_section", headerState: .margin(height: .margin3x), footerState: .margin(height: .margin8x), rows: reportRows)
        ]

        if App.shared.appConfigProvider.officeMode {
            sections.append(Section(id: "debug", headerState: .margin(height: 50), footerState: .margin(height: 20), rows: debugRows))
        }

        return sections
    }

}

extension ContactViewController: IContactView {

    func set(email: String) {
        self.email = email
    }

    func set(telegramWalletHelpAccount: String) {
        self.telegramWalletHelpAccount = telegramWalletHelpAccount
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
