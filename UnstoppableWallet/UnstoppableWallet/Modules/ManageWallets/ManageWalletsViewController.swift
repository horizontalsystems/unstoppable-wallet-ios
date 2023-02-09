import UIKit
import RxSwift
import RxCocoa
import SnapKit
import SectionsTableView
import ComponentKit
import ThemeKit

class ManageWalletsViewController: ThemeSearchViewController {
    private let viewModel: ManageWalletsViewModel
    private let restoreSettingsView: RestoreSettingsView
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let notFoundPlaceholder = PlaceholderView(layoutType: .keyboard)

    private var viewItems: [ManageWalletsViewModel.ViewItem] = []
    private var isLoaded = false

    init(viewModel: ManageWalletsViewModel, restoreSettingsView: RestoreSettingsView) {
        self.viewModel = viewModel
        self.restoreSettingsView = restoreSettingsView

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "manage_wallets.title".localized
        navigationItem.searchController?.searchBar.placeholder = "manage_wallets.search_placeholder".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))

        if viewModel.addTokenEnabled {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onTapAddTokenButton))
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        view.addSubview(notFoundPlaceholder)
        notFoundPlaceholder.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        notFoundPlaceholder.image = UIImage(named: "not_found_48")
        notFoundPlaceholder.text = "manage_wallets.not_found".localized

        restoreSettingsView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
        }

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.onUpdate(viewItems: $0) }
        subscribe(disposeBag, viewModel.notFoundVisibleDriver) { [weak self] in self?.setNotFound(visible: $0) }
        subscribe(disposeBag, viewModel.disableItemSignal) { [weak self] in self?.setToggle(on: false, index: $0) }
        subscribe(disposeBag, viewModel.showBirthdayHeightSignal) { [weak self] in self?.showBirthdayHeight(viewItem: $0) }

        tableView.buildSections()

        isLoaded = true
    }

    private func open(controller: UIViewController) {
        navigationItem.searchController?.dismiss(animated: true)
        present(controller, animated: true)
    }

    @objc private func onTapDoneButton() {
        dismiss(animated: true)
    }

    @objc private func onTapAddTokenButton() {
        guard let module = AddTokenModule.viewController() else {
            return
        }

        present(module, animated: true)
    }

    private func onUpdate(viewItems: [ManageWalletsViewModel.ViewItem]) {
        let animated = self.viewItems.map { $0.uid } == viewItems.map { $0.uid }
        self.viewItems = viewItems

        if isLoaded {
            tableView.reload(animated: animated)
        }
    }

    private func setNotFound(visible: Bool) {
        notFoundPlaceholder.isHidden = !visible
    }

    private func showBirthdayHeight(viewItem: ManageWalletsViewModel.BirthdayHeightViewItem) {
        let viewController = BirthdayHeightViewController(
                blockchainImageUrl: viewItem.blockchainImageUrl,
                blockchainName: viewItem.blockchainName,
                birthdayHeight: viewItem.birthdayHeight
        )

        present(viewController.toBottomSheet, animated: true)
    }

    override func onUpdate(filter: String?) {
        viewModel.onUpdate(filter: filter ?? "")
    }

    private func onToggle(index: Int, enabled: Bool) {
        if enabled {
            viewModel.onEnable(index: index)
        } else {
            viewModel.onDisable(index: index)
        }
    }

    func setToggle(on: Bool, index: Int) {
        guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BaseThemeCell else {
            return
        }

        CellBuilderNew.buildStatic(cell: cell, rootElement: rootElement(index: index, viewItem: viewItems[index], forceToggleOn: on))
    }

}

extension ManageWalletsViewController: SectionsDataSource {

    private func rootElement(index: Int, viewItem: ManageWalletsViewModel.ViewItem, forceToggleOn: Bool? = nil) -> CellBuilderNew.CellElement {
        .hStack([
            .image32 { component in
                component.setImage(
                        urlString: viewItem.imageUrl,
                        placeholder: viewItem.placeholderImageName.flatMap { UIImage(named: $0) }
                )
            },
            .vStackCentered([
                .hStack([
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = viewItem.title
                        component.setContentHuggingPriority(.required, for: .horizontal)
                    },
                    .margin8,
                    .badge { component in
                        component.isHidden = viewItem.badge == nil
                        component.badgeView.set(style: .small)
                        component.badgeView.text = viewItem.badge
                    },
                    .margin0,
                    .text { _ in }
                ]),
                .margin(1),
                .text { component in
                    component.font = .subhead2
                    component.textColor = .themeGray
                    component.text = viewItem.subtitle
                }
            ]),
            viewItem.hasInfo ? .margin4 : .margin16,
            .transparentIconButton { [weak self] component in
                component.isHidden = !viewItem.hasInfo
                component.button.set(image: UIImage(named: "circle_information_20"))
                component.onTap = {
                    self?.viewModel.onTapInfo(index: index)
                }
            },
            .margin4,
            .switch { component in
                if let forceOn = forceToggleOn {
                    component.switchView.setOn(forceOn, animated: true)
                } else {
                    component.switchView.isOn = viewItem.enabled
                }

                component.onSwitch = { [weak self] enabled in
                    self?.onToggle(index: index, enabled: enabled)
                }
            }
        ])
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "coins",
                    headerState: .margin(height: .margin4),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        let isLast = index == viewItems.count - 1

                        return CellBuilderNew.row(
                                rootElement: rootElement(index: index, viewItem: viewItem),
                                tableView: tableView,
                                id: "token_\(viewItem.uid)",
                                hash: "token_\(viewItem.enabled)_\(viewItem.hasInfo)_\(isLast)",
                                height: .heightDoubleLineCell,
                                bind: { cell in
                                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                                }
                        )
                    }
            )
        ]
    }

}
