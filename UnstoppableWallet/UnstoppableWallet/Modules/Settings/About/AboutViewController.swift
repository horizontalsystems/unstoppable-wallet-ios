import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa
import MessageUI
import SafariServices
import ComponentKit

class AboutViewController: ThemeViewController {
    private let viewModel: AboutViewModel
    private var urlManager: UrlManager

    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let headerCell = LogoHeaderCell()

    private var showTermsAlert = false

    init(viewModel: AboutViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

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

        tableView.registerCell(forClass: A1Cell.self)

        headerCell.image = .appIcon
        headerCell.title = "settings.about_app.app_name".localized
        headerCell.subtitle = "version".localized(viewModel.appVersion)

        subscribe(disposeBag, viewModel.termsAlertDriver) { [weak self] alert in
            self?.showTermsAlert = alert
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.openLinkSignal) { [weak self] url in
            self?.urlManager.open(url: url, from: self)
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

    private func row(viewItem: ViewItem, action: (() -> ())? = nil) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image20, .text, .image20, .margin8, .image20],
                tableView: tableView,
                id: viewItem.id,
                height: .heightCell48,
                bind: {cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: viewItem.isFirst, isLast: viewItem.isLast)

                    cell.bind(index: 0, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: viewItem.image)
                    })
                    cell.bind(index: 1, block: { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = viewItem.title.localized
                    })
                    cell.bind(index: 2, block: { (component: ImageComponent) in
                        component.imageView.image = viewItem.alert ? UIImage(named: "warning_2_20")?.withRenderingMode(.alwaysTemplate) : nil
                        component.imageView.tintColor = .themeLucian
                    })
                    cell.bind(index: 3, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "arrow_big_forward_20")
                    })
                },
                action: {
                    action?()
                }
        )
    }

}

extension AboutViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "header",
                    rows: [
                        StaticRow(
                                cell: headerCell,
                                id: "header",
                                height: LogoHeaderCell.height
                        )
                    ]
            ),

            Section(
                    id: "release-notes",
                    footerState: .margin(height: .margin32),
                    rows: [
                        row(viewItem: ViewItem(
                                id: "release-notes",
                                image: "circle_information_20",
                                title: "settings.about_app.whats_new",
                                alert: false,
                                isFirst: true,
                                isLast: true),
                                action: { [weak self] in
                                    guard let url = self?.viewModel.releaseNotesUrl else {
                                        return
                                    }

                                    self?.navigationController?.pushViewController(MarkdownModule.gitReleaseNotesMarkdownViewController(url: url, presented: false), animated: true)
                                })
                    ]
            ),

            Section(
                    id: "main",
                    footerState: .margin(height: .margin32),
                    rows: [
                        row(viewItem: ViewItem(
                                id: "app-status",
                                image: "app_status_20",
                                title: "app_status.title",
                                alert: false,
                                isFirst: true,
                                isLast: false),
                                action: { [weak self] in
                                    self?.navigationController?.pushViewController(AppStatusRouter.module(), animated: true)
                                }),
                        row(viewItem: ViewItem(
                                id: "terms",
                                image: "unordered_20",
                                title: "terms.title",
                                alert: showTermsAlert,
                                isFirst: false,
                                isLast: false),
                                action: { [weak self] in
                                    self?.navigationController?.pushViewController(TermsRouter.module(), animated: true)
                                }),
                        row(viewItem: ViewItem(
                                id: "privacy",
                                image: "user_20",
                                title: "coin_page.security_parameters.privacy",
                                alert: false,
                                isFirst: false,
                                isLast: true),
                                action: { [weak self] in
                                    self?.navigationController?.pushViewController(PrivacyPolicyViewController(config: .privacy), animated: true)
                                }),
                    ]
            ),

            Section(
                    id: "web",
                    footerState: .margin(height: .margin32),
                    rows: [
                        row(viewItem: ViewItem(
                                id: "github",
                                image: "github_20",
                                title: "GitHub",
                                alert: false,
                                isFirst: true,
                                isLast: false),
                                action: { [weak self] in
                                    self?.viewModel.onTapGithubLink()
                                }),
                        row(viewItem: ViewItem(
                                id: "website",
                                image: "globe_20",
                                title: "settings.about_app.website",
                                alert: false,
                                isFirst: false,
                                isLast: true),
                                action: { [weak self] in
                                    self?.viewModel.onTapWebPageLink()
                                })
                    ]
            ),
            Section(
                    id: "share",
                    footerState: .margin(height: .margin32),
                    rows: [
                        row(viewItem: ViewItem(
                                id: "rate-us",
                                image: "rate_20",
                                title: "settings.about_app.rate_us",
                                alert: false,
                                isFirst: true,
                                isLast: false),
                                action: { [weak self] in
                                    self?.viewModel.onTapRateApp()
                                }),
                        row(viewItem: ViewItem(
                                id: "tell-friends",
                                image: "share_1_20",
                                title: "settings.about_app.tell_friends",
                                alert: false,
                                isFirst: false,
                                isLast: true),
                                action: { [weak self] in
                                    self?.openTellFriends()
                                }),
                    ]
            ),
            Section(
                    id: "contact",
                    footerState: .margin(height: .margin32),
                    rows: [
                        row(viewItem: ViewItem(
                                id: "email",
                                image: "at_20",
                                title: "settings.about_app.contact",
                                alert: false,
                                isFirst: true,
                                isLast: true),
                                action: { [weak self] in
                                    self?.handleContact()
                                })
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

extension AboutViewController {

    struct ViewItem {
        let id: String
        let image: String
        let title: String
        let alert: Bool
        let isFirst: Bool
        let isLast: Bool
    }

}
