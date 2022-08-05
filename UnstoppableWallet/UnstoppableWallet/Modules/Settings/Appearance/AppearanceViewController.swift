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
        self.launchScreenViewItems = launchScreenViewItems
        reloadTable()
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

    private func reloadTable() {
        if loaded {
            tableView.reload(animated: true)
        }
    }

}

extension AppearanceViewController: SectionsDataSource {

    private func row(viewItem: AppearanceViewModel.ViewItem, id: String, isFirst: Bool, isLast: Bool, action: @escaping () -> ()) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image20, .text, .image20],
                tableView: tableView,
                id: id,
                hash: "\(viewItem.selected)",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: viewItem.iconName)?.withTintColor(.themeGray)
                    }
                    cell.bind(index: 1) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = viewItem.title
                    }
                    cell.bind(index: 2) { (component: ImageComponent) in
                        component.isHidden = !viewItem.selected
                        component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                    }
                },
                action: action
        )
    }

    private func themeModeSection(viewItems: [AppearanceViewModel.ViewItem]) -> SectionProtocol {
        Section(
                id: "theme-mode",
                headerState: tableView.sectionHeader(text: "appearance.theme".localized),
                footerState: .margin(height: .margin24),
                rows: viewItems.enumerated().map { index, viewItem in
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

    private func launchScreenSection(viewItems: [AppearanceViewModel.ViewItem]) -> SectionProtocol {
        Section(
                id: "launch-screen",
                headerState: tableView.sectionHeader(text: "appearance.launch_screen".localized),
                footerState: .margin(height: .margin24),
                rows: viewItems.enumerated().map { index, viewItem in
                    row(
                            viewItem: viewItem,
                            id: "launch-screen-\(index)",
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
                footerState: .margin(height: .margin24),
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
                    let isFirst = index == 0
                    let isLast = index == viewItems.count - 1

                    return CellBuilder.selectableRow(
                            elements: [.image24, .text, .image20],
                            tableView: tableView,
                            id: "balance-conversion-\(index)",
                            hash: "\(viewItem.selected)",
                            height: .heightCell48,
                            autoDeselect: true,
                            bind: { cell in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                                cell.bind(index: 0) { (component: ImageComponent) in
                                    component.setImage(urlString: viewItem.urlString, placeholder: nil)
                                }
                                cell.bind(index: 1) { (component: TextComponent) in
                                    component.font = .body
                                    component.textColor = .themeLeah
                                    component.text = viewItem.title
                                }
                                cell.bind(index: 2) { (component: ImageComponent) in
                                    component.isHidden = !viewItem.selected
                                    component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                                }
                            },
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
                    let isFirst = index == 0
                    let isLast = index == viewItems.count - 1

                    return CellBuilder.selectableRow(
                            elements: [.multiText, .image20],
                            tableView: tableView,
                            id: "balance-value-\(index)",
                            hash: "\(viewItem.selected)",
                            height: .heightDoubleLineCell,
                            autoDeselect: true,
                            bind: { cell in
                                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)

                                cell.bind(index: 0) { (component: MultiTextComponent) in
                                    component.set(style: .m1)
                                    component.title.font = .body
                                    component.title.textColor = .themeLeah
                                    component.subtitle.font = .subhead2
                                    component.subtitle.textColor = .themeGray

                                    component.title.text = viewItem.title
                                    component.subtitle.text = viewItem.subtitle
                                }
                                cell.bind(index: 1) { (component: ImageComponent) in
                                    component.isHidden = !viewItem.selected
                                    component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                                }
                            },
                            action: { [weak self] in
                                self?.viewModel.onSelectBalanceValue(index: index)
                            }
                    )
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(id: "top-margin", headerState: .margin(height: .margin12)),
            themeModeSection(viewItems: themeModeViewItems),
            launchScreenSection(viewItems: launchScreenViewItems),
            appIconSection(viewItems: appIconViewItems),
            conversionSection(viewItems: conversionViewItems),
            balanceValueSection(viewItems: balanceValueViewItems)
        ]
    }

}
