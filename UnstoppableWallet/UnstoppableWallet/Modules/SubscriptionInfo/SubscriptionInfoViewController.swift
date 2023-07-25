import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView

class SubscriptionInfoViewController: ThemeViewController {
    private let tableView = SectionsTableView(style: .grouped)

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        tableView.registerCell(forClass: MarkdownHeader1Cell.self)
        tableView.registerCell(forClass: MarkdownHeader3Cell.self)
        tableView.registerCell(forClass: MarkdownTextCell.self)

        let buttonsHolder = BottomGradientHolder()
        buttonsHolder.add(to: self, under: tableView)

        let getPremiumButton = PrimaryButton()
        buttonsHolder.addSubview(getPremiumButton)

        getPremiumButton.set(style: .yellow)
        getPremiumButton.setTitle("subscription_info.get_premium".localized, for: .normal)
        getPremiumButton.addTarget(self, action: #selector(onTapGetPremium), for: .touchUpInside)

        let alreadyHaveButton = PrimaryButton()
        buttonsHolder.addSubview(alreadyHaveButton)

        alreadyHaveButton.set(style: .transparent)
        alreadyHaveButton.setTitle("subscription_info.already_have".localized, for: .normal)
        alreadyHaveButton.addTarget(self, action: #selector(onTapAlreadyHave), for: .touchUpInside)

        tableView.buildSections()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    @objc private func onTapGetPremium() {
        UrlManager.open(url: AppConfig.analyticsLink, inAppController: self)
    }

    @objc private func onTapAlreadyHave() {
        let viewController = ActivateSubscriptionModule.viewController()
        let presentingViewController = presentingViewController

        dismiss(animated: true) {
            presentingViewController?.present(viewController, animated: true)
        }
    }

}

extension SubscriptionInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "info",
                    footerState: .margin(height: .margin32),
                    rows: [
                        MarkdownViewController.header1Row(id: "header", string: "subscription_info.title".localized),
                        MarkdownViewController.header3Row(id: "info1-title", string: "subscription_info.info1.title".localized),
                        MarkdownViewController.textRow(id: "info1-text", string: "subscription_info.info1.text".localized),
                        MarkdownViewController.header3Row(id: "info2-title", string: "subscription_info.info2.title".localized),
                        MarkdownViewController.textRow(id: "info2-text", string: "subscription_info.info2.text".localized),
                        MarkdownViewController.header3Row(id: "info3-title", string: "subscription_info.info3.title".localized),
                        MarkdownViewController.textRow(id: "info4-text", string: "subscription_info.info3.text".localized),
                    ]
            )
        ]
    }

}
