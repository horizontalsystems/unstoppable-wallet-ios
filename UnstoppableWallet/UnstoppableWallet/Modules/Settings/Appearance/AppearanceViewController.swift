import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit
import RxSwift

class AppearanceViewController: ThemeViewController {
    private let viewModel: AppearanceViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var themeModeViewItems = [AppearanceViewModel.ViewItem]()
    private var launchScreenViewItems = [AppearanceViewModel.ViewItem]()
    private var appIconViewItems = [AppearanceViewModel.AppIconViewItem]()
    private var conversionViewItems = [AppearanceViewModel.ConversionViewItem]()
    private var balanceValueViewItems = [AppearanceViewModel.BalanceValueViewItem]()

    private var loaded = false

    init(viewModel: AppearanceViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "appearance.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: AppearanceAppIconsCell.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.themeModeViewItemsDriver) { [weak self] in self?.sync(themeModeViewItems: $0) }
        subscribe(disposeBag, viewModel.launchScreenViewItemsDriver) { [weak self] in self?.sync(launchScreenViewItems: $0) }
        subscribe(disposeBag, viewModel.appIconViewItemsDriver) { [weak self] in self?.sync(appIconViewItems: $0) }
        subscribe(disposeBag, viewModel.conversionViewItemsDriver) { [weak self] in self?.sync(conversionViewItems: $0) }
        subscribe(disposeBag, viewModel.balanceValueViewItemsDriver) { [weak self] in self?.sync(balanceValueViewItems: $0) }

        tableView.buildSections()
        loaded = true
    }

    private func sync(themeModeViewItems: [AppearanceViewModel.ViewItem]) {
        self.themeModeViewItems = themeModeViewItems
        reloadTable()
    }

    private func sync(launchScreenViewItems: [AppearanceViewModel.ViewItem]) {
        let changeSection = launchScreenViewItems.count != self.launchScreenViewItems.count
        self.launchScreenViewItems = launchScreenViewItems
        reloadTable(animated: !changeSection)
    }

    private func sync(appIconViewItems: [AppearanceViewModel.AppIconViewItem]) {
        self.appIconViewItems = appIconViewItems
        reloadTable()
    }

    private func sync(conversionViewItems: [AppearanceViewModel.ConversionViewItem]) {
        self.conversionViewItems = conversionViewItems
        reloadTable()
    }

    private func sync(balanceValueViewItems: [AppearanceViewModel.BalanceValueViewItem]) {
        self.balanceValueViewItems = balanceValueViewItems
        reloadTable()
    }

    private func toggleMarketTabVisible() {
        viewModel.onToggleShowMarketScreen()
    }

    private func reloadTable(animated: Bool = true) {
        if loaded {
            tableView.reload(animated: animated)
        }
    }

}

extension AppearanceViewController: SectionsDataSource {

    private func row(viewItem: AppearanceViewModel.ViewItem, id: String, isFirst: Bool, isLast: Bool, action: @escaping () -> ()) -> RowProtocol {
        tableView.universalRow48(
                id: id,
                image: .local(UIImage(named: viewItem.iconName)?.withTintColor(.themeGray)),
                title: .body(viewItem.title),
                accessoryType: .check(viewItem.selected),
                hash: "\(id)_\(viewItem.selected)",
                autoDeselect: true,
                isFirst: isFirst,
                isLast: isLast,
                action: action
        )
    }

    private func themeModeSection(viewItems: [AppearanceViewModel.ViewItem]) -> SectionProtocol {
        Section(
                id: "theme-mode",
                headerState: tableView.sectionHeader(text: "appearance.theme".localized),
                footerState: .margin(height: .margin24),
                rows: viewItems.enumerated().map { index,
                                                   viewItem in
                    row(
                            viewItem: viewItem,
                            id: "theme-mode-\(index)",
                            isFirst: index == 0,
                            isLast: index == viewItems.count - 1
                    ) { [weak self] in
                        self?.viewModel.onSelectThemeMode(index: index)
                    }
                }
        )
    }

    private func showMarketTabSection() -> SectionProtocol {
        Section(
                id: "market-tab-section",
                headerState: tableView.sectionHeader(text: "appearance.tab_settings".localized),
                footerState: .margin(height: .margin24),
                rows: [
                    tableView.universalRow48(
                            id: "show_market_tab",
                            image: .local(UIImage(named: "markets_24")),
                            title: .body("appearance.markets_tab".localized),
                            accessoryType: .switch(isOn: viewModel.showMarketTab) { [weak self] _ in self?.toggleMarketTabVisible() },
                            hash: "\(viewModel.showMarketTab)",
                            autoDeselect: true,
                            isFirst: true,
                            isLast: true
                    )
                ]
        )
    }

    private func launchScreenSection(viewItems: [AppearanceViewModel.ViewItem]) -> SectionProtocol? {
        guard !viewItems.isEmpty else {
            return nil
        }

        return Section(
                id: "launch-screen",
                headerState: tableView.sectionHeader(text: "appearance.launch_screen".localized),
                footerState: .margin(height: .margin24),
                rows: viewItems.enumerated().map { index, viewItem in
                    row(
                            viewItem: viewItem,
                            id: "launch-screen-\(viewItem.title)",
                            isFirst: index == 0,
                            isLast: index == viewItems.count - 1
                    ) { [weak self] in
                        self?.viewModel.onSelectLaunchScreen(index: index)
                    }
                }
        )
    }

    private func appIconSection(viewItems: [AppearanceViewModel.AppIconViewItem]) -> SectionProtocol {
        Section(
                id: "app-icon",
                headerState: tableView.sectionHeader(text: "appearance.app_icon".localized),
                footerState: .margin(height: .margin32),
                rows: [
                    Row<AppearanceAppIconsCell>(
                            id: "app-icon",
                            hash: "\(viewItems.map { "\($0.selected)" }.joined(separator: "-"))",
                            height: AppearanceAppIconsCell.height(viewItemsCount: viewItems.count),
                            bind: { [weak self] cell, _ in
                                cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

                                cell.bind(viewItems: viewItems) { index in
                                    self?.viewModel.onSelectAppIcon(index: index)
                                }
                            }
                    )
                ]
        )
    }

    private func conversionSection(viewItems: [AppearanceViewModel.ConversionViewItem]) -> SectionProtocol {
        Section(
                id: "balance-conversion",
                headerState: tableView.sectionHeader(text: "appearance.balance_conversion".localized),
                footerState: .margin(height: .margin24),
                rows: viewItems.enumerated().map { index, viewItem in
                    tableView.universalRow56(
                            id: "balance-conversion-\(index)",
                            image: .url(viewItem.urlString, placeholder: "placeholder_circle_32"),
                            title: .body(viewItem.title),
                            accessoryType: .check(viewItem.selected),
                            hash: "\(viewItem.selected)",
                            autoDeselect: true,
                            isFirst: index == 0,
                            isLast: index == viewItems.count - 1,
                            action: { [weak self] in
                                self?.viewModel.onSelectConversionCoin(index: index)
                            }
                    )
                }
        )
    }

    private func balanceValueSection(viewItems: [AppearanceViewModel.BalanceValueViewItem]) -> SectionProtocol {
        Section(
                id: "balance-value",
                headerState: tableView.sectionHeader(text: "appearance.balance_value".localized),
                footerState: .margin(height: .margin32),
                rows: viewItems.enumerated().map { index, viewItem in
                    tableView.universalRow62(
                            id: "balance-value-\(index)",
                            title: .body(viewItem.title),
                            description: .subhead2(viewItem.subtitle),
                            accessoryType: .check(viewItem.selected),
                            hash: "\(viewItem.selected)",
                            autoDeselect: true,
                            isFirst: index == 0,
                            isLast: index == viewItems.count - 1,
                            action: { [weak self] in
                                self?.viewModel.onSelectBalanceValue(index: index)
                            }
                    )
                }
        )
    }

    private func balanceAutoHideSection() -> SectionProtocol {
        Section(
                id: "balance-auto-hide",
                footerState: .margin(height: .margin24),
                rows: [
                    tableView.universalRow48(
                            id: "balance-auto-hide",
                            image: .local(UIImage(named: "eye_off_24")),
                            title: .body("appearance.balance_auto_hide".localized),
                            accessoryType: .switch(isOn: viewModel.balanceAutoHide) { [weak self] in self?.viewModel.onSet(balanceAutoHide: $0) },
                            hash: "\(viewModel.balanceAutoHide)",
                            isFirst: true,
                            isLast: true
                    )
                ]
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(id: "top-margin", headerState: .margin(height: .margin12)),
            themeModeSection(viewItems: themeModeViewItems),
            showMarketTabSection(),
        ]
        if let launchScreenSection = launchScreenSection(viewItems: launchScreenViewItems) {
            sections.append(launchScreenSection)
        }
        sections.append(contentsOf: [
            conversionSection(viewItems: conversionViewItems),
            balanceValueSection(viewItems: balanceValueViewItems),
            balanceAutoHideSection(),
            appIconSection(viewItems: appIconViewItems)
        ])
        return sections
    }

}
