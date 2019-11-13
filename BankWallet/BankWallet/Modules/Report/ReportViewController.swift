import UIKit
import SectionsTableView

class ReportViewController: WalletViewController {
    private let delegate: IReportViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var email: String?
    private var telegramGroup: String?

    init(delegate: IReportViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.report_problem.title".localized

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
                    height: SettingsTheme.doubleLineCellHeight,
                    autoDeselect: true,
                    bind: { [weak self] cell, _ in
                        cell.bind(
                                image: UIImage(named: "Email Icon")?.tinted(with: .appJacob),
                                title: "settings.report_problem.email".localized,
                                subtitle: self?.email
                        )
                    },
                    action: { [weak self] _ in
                        self?.delegate.didTapEmail()
                    }
            ),
            Row<ImageDoubleLineCell>(
                    id: "telegram",
                    height: SettingsTheme.doubleLineCellHeight,
                    autoDeselect: true,
                    bind: { [weak self] cell, _ in
                        cell.bind(
                                image: UIImage(named: "Telegram Icon")?.tinted(with: .appJacob),
                                title: "settings.report_problem.telegram".localized,
                                subtitle: self?.telegramGroup,
                                last: true
                        )
                    },
                    action: { [weak self] _ in
                        self?.delegate.didTapTelegram()
                    }
            )
        ]
    }

    private var statusRows: [RowProtocol] {
        [
            Row<TitleCell>(
                    id: "status",
                    height: SettingsTheme.cellHeight,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.bind(titleIcon: nil, title: "settings.report_problem.app_status".localized, showDisclosure: true, last: true)
                    },
                    action: { [weak self] _ in
                        self?.delegate.didTapStatus()
                    }
            )
        ]
    }

    private var debugRows: [RowProtocol] {
        [
            Row<TitleCell>(id: "debug_background_log", height: SettingsTheme.cellHeight, autoDeselect: true, bind: { cell, _ in
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

extension ReportViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(id: "report_section", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: reportRows),
            Section(id: "status_section", headerState: .margin(height: SettingsTheme.headerHeight), rows: statusRows)
        ]

        if App.shared.appConfigProvider.officeMode {
            sections.append(Section(id: "debug", headerState: .margin(height: 50), footerState: .margin(height: 20), rows: debugRows))
        }

        return sections
    }

}

extension ReportViewController: IReportView {

    func set(email: String) {
        self.email = email
    }

    func set(telegramGroup: String) {
        self.telegramGroup = telegramGroup
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
