import Foundation
import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD

class ActivateSubscriptionViewController: ThemeViewController {
    private let viewModel: ActivateSubscriptionViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()
    private let noSubscriptionsView = PlaceholderView()

    private let buttonsHolder = BottomGradientHolder()
    private let signButton = PrimaryButton()
    private let activatingButton = PrimaryButton()
    private let rejectButton = PrimaryButton()

    private var viewItem: ActivateSubscriptionViewModel.ViewItem?

    init(viewModel: ActivateSubscriptionViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "activate_subscription.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        view.addSubview(spinner)
        spinner.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.configureSyncError(action: { [weak self] in self?.viewModel.onTapRetry() })

        view.addSubview(noSubscriptionsView)
        noSubscriptionsView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        noSubscriptionsView.image = UIImage(named: "sync_error_48")?.withTintColor(.themeGray)
        noSubscriptionsView.text = "activate_subscription.no_subscriptions".localized
        noSubscriptionsView.addPrimaryButton(style: .yellow, title: "subscription_info.get_premium".localized, target: self, action: #selector(onTapGetPremium))

        buttonsHolder.add(to: self, under: tableView)
        buttonsHolder.addSubview(signButton)

        signButton.set(style: .yellow)
        signButton.setTitle("activate_subscription.sign".localized, for: .normal)
        signButton.addTarget(self, action: #selector(onTapSign), for: .touchUpInside)

        buttonsHolder.addSubview(activatingButton)
        activatingButton.set(style: .yellow, accessoryType: .spinner)
        activatingButton.isEnabled = false
        activatingButton.setTitle("activate_subscription.activating".localized, for: .normal)

        buttonsHolder.addSubview(rejectButton)
        rejectButton.set(style: .gray)
        rejectButton.setTitle("button.reject".localized, for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)

        viewModel.$spinnerVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] visible in self?.spinner.isHidden = !visible }
                .store(in: &cancellables)

        viewModel.$errorVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] visible in self?.errorView.isHidden = !visible }
                .store(in: &cancellables)

        viewModel.$noSubscriptionsVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] visible in self?.noSubscriptionsView.isHidden = !visible }
                .store(in: &cancellables)

        viewModel.$viewItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] viewItem in
                    if let viewItem {
                        self?.viewItem = viewItem
                        self?.tableView.reload()
                        self?.tableView.isHidden = false
                        self?.buttonsHolder.isHidden = false
                    } else {
                        self?.tableView.isHidden = true
                        self?.buttonsHolder.isHidden = true
                    }
                }
                .store(in: &cancellables)

        viewModel.$signVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] visible in self?.signButton.isHidden = !visible }
                .store(in: &cancellables)

        viewModel.$activatingVisible
                .receive(on: DispatchQueue.main)
                .sink { [weak self] visible in self?.activatingButton.isHidden = !visible }
                .store(in: &cancellables)

        viewModel.$rejectEnabled
                .receive(on: DispatchQueue.main)
                .sink { [weak self] enabled in self?.rejectButton.isEnabled = enabled }
                .store(in: &cancellables)

        viewModel.errorPublisher
                .receive(on: DispatchQueue.main)
                .sink { text in HudHelper.instance.showErrorBanner(title: text) }
                .store(in: &cancellables)

        viewModel.finishPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    HudHelper.instance.show(banner: .success(string: "activate_subscription.activated".localized))
                    self?.dismiss(animated: true)
                }
                .store(in: &cancellables)
    }

    @objc private func onTapSign() {
        viewModel.onTapSign()
    }

    @objc private func onTapReject() {
        dismiss(animated: true)
    }

    @objc private func onTapGetPremium() {
        UrlManager.open(url: AppConfig.analyticsLink, inAppController: self)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

}

extension ActivateSubscriptionViewController: SectionsDataSource {

    private func addressRow(tableView: UITableView, value: String) -> RowProtocol {
        let backgroundStyle: BaseThemeCell.BackgroundStyle = .lawrence
        let title = "activate_subscription.address".localized
        let titleFont: UIFont = .subhead2
        let valueFont: UIFont = .subhead1

        return CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = titleFont
                        component.textColor = .themeGray
                        component.text = title
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                    },
                    .text { component in
                        component.font = valueFont
                        component.textColor = .themeLeah
                        component.text = value
                        component.textAlignment = .right
                        component.numberOfLines = 0
                    },
                    .margin8,
                    .secondaryCircleButton { component in
                        component.button.set(image: UIImage(named: "copy_20"))
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: value)
                        }
                    }
                ]),
                tableView: tableView,
                id: "address",
                hash: value,
                dynamicHeight: { containerWidth in
                    CellBuilderNew.height(
                            containerWidth: containerWidth,
                            backgroundStyle: backgroundStyle,
                            text: value,
                            font: valueFont,
                            elements: [
                                .fixed(width: TextComponent.width(font: titleFont, text: title)),
                                .multiline,
                                .margin8,
                                .fixed(width: SecondaryCircleButton.size)
                            ]
                    )
                },
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isLast: true)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let viewItem else {
            return []
        }

        return [
            Section(
                    id: "main",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin24),
                    rows: [
                        tableView.universalRow48(
                                id: "wallet-name",
                                title: .subhead2("activate_subscription.wallet".localized),
                                value: .subhead1(viewItem.walletName),
                                isFirst: true
                        ),
                        addressRow(tableView: tableView, value: viewItem.address)
                    ]
            ),
            Section(
                    id: "message",
                    headerState: tableView.sectionHeader(text: "activate_subscription.message".localized),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.messageRow(text: viewItem.message)
                    ]
            )
        ]
    }

}
