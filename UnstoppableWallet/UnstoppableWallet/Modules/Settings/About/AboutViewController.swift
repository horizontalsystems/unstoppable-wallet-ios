import ComponentKit
import RxCocoa
import RxSwift
import SafariServices
import SectionsTableView
import SnapKit
import ThemeKit

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

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.about_app.title".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: DescriptionCell.self)

        headerCell.image = UIImage(named: AppIcon.main.imageName)
        headerCell.title = "settings.about_app.app_name".localized(AppConfig.appName)
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
        super.viewWillAppear(animated)
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    private func openTwitter() {
        let account = AppConfig.appTwitterAccount

        if let appUrl = URL(string: "twitter://user?screen_name=\(account)"), UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
        } else {
            urlManager.open(url: "https://twitter.com/\(account)", from: self)
        }
    }
}

extension AboutViewController: SectionsDataSource {
    private func row(id: String, image: String, title: String, alert: Bool = false, isFirst: Bool = false, isLast: Bool = false, action: @escaping () -> Void) -> RowProtocol {
        var elements = tableView.universalImage24Elements(image: .local(UIImage(named: image)), title: .body(title), value: nil, accessoryType: .disclosure)
        if alert {
            elements.insert(.imageElement(image: .local(UIImage(named: "warning_2_24")?.withTintColor(.themeLucian)), size: .image24), at: 2)
        }
        return CellBuilderNew.row(
            rootElement: .hStack(elements),
            tableView: tableView,
            id: id,
            height: .heightCell48,
            autoDeselect: true,
            bind: { cell in
                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
            },
            action: action
        )
    }

    func buildSections() -> [SectionProtocol] {
        let descriptionText = "settings.about_app.description".localized(AppConfig.appName, AppConfig.appName)

        return [
            Section(
                id: "header",
                rows: [
                    StaticRow(
                        cell: headerCell,
                        id: "header",
                        height: LogoHeaderCell.height
                    ),
                    Row<DescriptionCell>(
                        id: "description",
                        dynamicHeight: { containerWidth in
                            DescriptionCell.height(containerWidth: containerWidth, text: descriptionText)
                        },
                        bind: { cell, _ in
                            cell.label.text = descriptionText
                        }
                    ),
                ]
            ),

            Section(
                id: "release-notes",
                headerState: .margin(height: .margin24),
                footerState: .margin(height: .margin32),
                rows: [
                    row(
                        id: "release-notes",
                        image: "circle_information_24",
                        title: "settings.about_app.whats_new".localized,
                        isFirst: true,
                        isLast: true,
                        action: { [weak self] in
                            guard let url = self?.viewModel.releaseNotesUrl else {
                                return
                            }

                            self?.navigationController?.pushViewController(MarkdownModule.gitReleaseNotesMarkdownViewController(url: url, presented: false), animated: true)
                        }
                    ),
                ]
            ),

            Section(
                id: "main",
                footerState: .margin(height: .margin32),
                rows: [
                    row(
                        id: "app-status",
                        image: "app_status_24",
                        title: "app_status.title".localized,
                        isFirst: true,
                        action: { [weak self] in
                            let viewController = AppStatusModule.view().toViewController(title: "app_status.title".localized)
                            self?.navigationController?.pushViewController(viewController, animated: true)
                        }
                    ),
                    row(
                        id: "terms",
                        image: "unordered_24",
                        title: "terms.title".localized,
                        alert: showTermsAlert,
                        action: { [weak self] in
                            self?.present(TermsModule.viewController(), animated: true)
                        }
                    ),
                    row(
                        id: "privacy",
                        image: "user_24",
                        title: "settings.privacy".localized,
                        isLast: true,
                        action: { [weak self] in
                            self?.navigationController?.pushViewController(PrivacyPolicyViewController(config: .privacy), animated: true)
                        }
                    ),
                ]
            ),

            Section(
                id: "web",
                footerState: .margin(height: .margin32),
                rows: [
                    row(
                        id: "github",
                        image: "github_24",
                        title: "GitHub",
                        isFirst: true,
                        action: { [weak self] in
                            self?.viewModel.onTapGithubLink()
                        }
                    ),
                    row(
                        id: "twitter",
                        image: "twitter_24",
                        title: "Twitter",
                        action: { [weak self] in
                            self?.openTwitter()
                        }
                    ),
                    row(
                        id: "website",
                        image: "globe_24",
                        title: "settings.about_app.website".localized,
                        isLast: true,
                        action: { [weak self] in
                            self?.viewModel.onTapWebPageLink()
                        }
                    ),
                ]
            ),
        ]
    }
}
