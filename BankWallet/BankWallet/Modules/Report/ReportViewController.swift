import UIKit
import SectionsTableView

class ReportViewController: WalletViewController {
    private let delegate: IReportViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var email: String?
    private var telegramGroup: String?

    init(delegate: IReportViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.report_problem.title".localized

        tableView.registerCell(forClass: DoubleLineCell.self)
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

}

extension ReportViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        return [
            Section(
                    id: "section",
                    headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight),
                    rows: [
                        Row<DoubleLineCell>(id: "email", hash: "email", height: SettingsTheme.doubleLineCellHeight, autoDeselect: true, bind: { [weak self] cell, _ in
                            cell.bind(icon: UIImage(named: "Email Icon"), tintIcon: true, title: "settings.report_problem.email".localized, subtitle: self?.email)
                        }, action: { [weak self] _ in
                            self?.delegate.didTapEmail()
                        }),
                        Row<DoubleLineCell>(id: "telegram", hash: "telegram", height: SettingsTheme.doubleLineCellHeight, autoDeselect: true, bind: { [weak self] cell, _ in
                            cell.bind(icon: UIImage(named: "Telegram Icon"), tintIcon: true, title: "settings.report_problem.telegram".localized, subtitle: self?.telegramGroup, last: true)
                        }, action: { [weak self] _ in
                            self?.delegate.didTapTelegram()
                        })
                    ]
            )
        ]
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
