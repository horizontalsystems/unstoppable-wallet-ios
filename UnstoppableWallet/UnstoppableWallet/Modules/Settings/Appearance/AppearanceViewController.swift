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

        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.themeModeViewItemsDriver) { [weak self] in self?.sync(themeModeViewItems: $0) }
        subscribe(disposeBag, viewModel.launchScreenViewItemsDriver) { [weak self] in self?.sync(launchScreenViewItems: $0) }

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

    private func reloadTable() {
        if loaded {
            tableView.reload(animated: true)
        }
    }

}

extension AppearanceViewController: SectionsDataSource {

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { $0.bind(text: text) },
                dynamicHeight: { _ in SubtitleHeaderFooterView.height }
        )
    }

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
                        component.set(style: .b2)
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
                headerState: header(text: "appearance.theme".localized),
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
                headerState: header(text: "appearance.launch_screen".localized),
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

    func buildSections() -> [SectionProtocol] {
        [
            themeModeSection(viewItems: themeModeViewItems),
            launchScreenSection(viewItems: launchScreenViewItems)
        ]
    }

}
