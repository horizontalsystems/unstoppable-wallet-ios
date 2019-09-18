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
