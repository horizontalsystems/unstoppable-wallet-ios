import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa
import MessageUI
import SafariServices

class AboutViewController: ThemeViewController {
    private let viewModel: AboutViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let headerCell = TermsHeaderCell()
    private let buttonsCell = DoubleButtonCell()
    private let termsCell = A3Cell()

    init(viewModel: AboutViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.about_app.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        tableView.registerCell(forClass: TermsHeaderCell.self)
        tableView.registerCell(forClass: DoubleButtonCell.self)
        tableView.registerCell(forClass: A1Cell.self)

        headerCell.bind(
                image: UIImage(named: "App Icon"),
                title: "settings.about_app.app_name".localized,
                subtitle: "version".localized(viewModel.appVersion)
        )

        buttonsCell.leftTitle = "GitHub"
        buttonsCell.rightTitle = "settings.about_app.site".localized
        buttonsCell.onTapLeft = { [weak self] in
            self?.viewModel.onTapGithubLink()
        }
        buttonsCell.onTapRight = { [weak self] in
            self?.viewModel.onTapWebPageLink()
        }

        termsCell.set(backgroundStyle: .lawrence)
        termsCell.titleImage = UIImage(named: "wallet_20")
        termsCell.title = "terms.title".localized

        subscribe(disposeBag, viewModel.termsAlertDriver) { [weak self] alert in
            self?.termsCell.valueImage = alert ? UIImage(named: "attention_20")?.tinted(with: .themeLucian) : nil
        }
        subscribe(disposeBag, viewModel.openLinkSignal) { [weak self] url in
            self?.present(SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration()), animated: true)
        }

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func openTellFriends() {
        let text = "settings_tell_friends.text".localized + "\n" + viewModel.appWebPageLink
        let activityViewController = UIActivityViewController(activityItems: [text], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }

    private func handleContact() {
        let email = viewModel.contactEmail

        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.setToRecipients([email])
            controller.mailComposeDelegate = self

            present(controller, animated: true)
        } else {
            UIPasteboard.general.setValue(email, forPasteboardType: "public.plain-text")
            HudHelper.instance.showSuccess(title: "settings.about_app.email_copied".localized)
        }
    }

}

extension AboutViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: headerCell,
                                id: "header",
                                height: TermsHeaderCell.height
                        ),
                        StaticRow(
                                cell: buttonsCell,
                                id: "buttons",
                                height: buttonsCell.cellHeight
                        ),
                        Row<A1Cell>(
                                id: "contact",
                                height: .heightSingleLineCell,
                                autoDeselect: true,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence)
                                    cell.titleImage = UIImage(named: "notification_20")
                                    cell.title = "settings.about_app.contact".localized
                                },
                                action: { [weak self] _ in
                                    self?.handleContact()
                                }
                        ),
                        Row<A1Cell>(
                                id: "app-status",
                                height: .heightSingleLineCell,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence)
                                    cell.titleImage = UIImage(named: "notification_20")
                                    cell.title = "app_status.title".localized
                                },
                                action: { [weak self] _ in
                                    self?.navigationController?.pushViewController(AppStatusRouter.module(), animated: true)
                                }
                        ),
                        StaticRow(
                                cell: termsCell,
                                id: "terms",
                                height: .heightSingleLineCell,
                                action: { [weak self] in
                                    self?.navigationController?.pushViewController(TermsRouter.module(), animated: true)
                                }
                        ),
                        Row<A1Cell>(
                                id: "rate-us",
                                height: .heightSingleLineCell,
                                autoDeselect: true,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence)
                                    cell.titleImage = UIImage(named: "notification_20")
                                    cell.title = "settings.about_app.rate_us".localized
                                },
                                action: { _ in
                                    // todo
                                }
                        ),
                        Row<A1Cell>(
                                id: "tell-friends",
                                height: .heightSingleLineCell,
                                autoDeselect: true,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence, bottomSeparator: true)
                                    cell.titleImage = UIImage(named: "notification_20")
                                    cell.title = "settings.about_app.tell_friends".localized
                                },
                                action: { [weak self] _ in
                                    self?.openTellFriends()
                                }
                        )
                    ]
            )
        ]
    }

}

extension AboutViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }

}
