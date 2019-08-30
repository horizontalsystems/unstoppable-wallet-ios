import UIKit
import SectionsTableView

class ReportViewController: WalletViewController, SectionsDataSource {
    private let delegate: IReportViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

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

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: DoubleLineCell.self)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.reload()
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        var rows = [RowProtocol]()

        rows.append(Row<DoubleLineCell>(id: "email", hash: "email", height: SettingsTheme.doubleLineCellHeight, autoDeselect: true, bind: { [unowned self] cell, _ in
            cell.bind(icon: UIImage(named: "Email Icon"), tintIcon: true, title: "settings.report_problem.email".localized, subtitle: self.delegate.email)
        }, action: { [weak self] _ in
            self?.delegate.didTapEmail()
        }))

        rows.append(Row<DoubleLineCell>(id: "telegram", hash: "telegram", height: SettingsTheme.doubleLineCellHeight, autoDeselect: true, bind: { [unowned self] cell, _ in
            cell.bind(icon: UIImage(named: "Telegram Icon"), tintIcon: true, title: "settings.report_problem.telegram".localized, subtitle: self.delegate.telegramGroup, last: true)
        }, action: { [weak self] _ in
            self?.delegate.didTapTelegram()
        }))

        sections.append(Section(id: "section", headerState: .margin(height: SettingsTheme.subSettingsHeaderHeight), rows: rows))

        return sections
    }

}

extension ReportViewController: IReportView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
