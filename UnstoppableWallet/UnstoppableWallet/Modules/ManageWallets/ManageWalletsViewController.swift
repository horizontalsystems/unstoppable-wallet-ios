import Combine
import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ComponentKit
import SectionsTableView
import ThemeKit

class ManageWalletsViewController: ThemeSearchViewController {
    private let viewModel: ManageWalletsViewModel
    private let restoreSettingsView: RestoreSettingsView
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

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
        subscribe(disposeBag, viewModel.showInfoSignal) { [weak self] in self?.showInfo(viewItem: $0) }
        subscribe(disposeBag, viewModel.showBirthdayHeightSignal) { [weak self] in self?.showBirthdayHeight(viewItem: $0) }
        subscribe(disposeBag, viewModel.showContractSignal) { [weak self] in self?.showContract(viewItem: $0) }

        $filter
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.viewModel.onUpdate(filter: $0 ?? "") }
                .store(in: &cancellables)

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

    private func showInfo(viewItem: ManageWalletsViewModel.InfoViewItem) {
        showBottomSheet(viewItem: viewItem.coin, items: [
            .description(text: viewItem.text)
        ])
    }

    private func showBirthdayHeight(viewItem: ManageWalletsViewModel.BirthdayHeightViewItem) {
        showBottomSheet(viewItem: viewItem.coin, items: [
            .copyableValue(title: "birthday_height.title".localized, value: viewItem.height)
        ])
    }

    private func showContract(viewItem: ManageWalletsViewModel.ContractViewItem) {
        showBottomSheet(viewItem: viewItem.coin, items: [
            .contractAddress(imageUrl: viewItem.blockchainImageUrl, value: viewItem.value, explorerUrl: viewItem.explorerUrl)
        ])
    }

    private func showBottomSheet(viewItem: ManageWalletsViewModel.CoinViewItem, items: [BottomSheetModule.Item]) {
        let viewController = BottomSheetModule.viewController(
                image: .remote(url: viewItem.coinImageUrl, placeholder: viewItem.coinPlaceholderImageName),
                title: viewItem.coinCode,
                subtitle: viewItem.coinName,
                items: items
        )

        present(viewController, animated: true)
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
                    .textElement(text: .body(viewItem.title), parameters: .highHugging),
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
                .textElement(text: .subhead2(viewItem.subtitle))
            ]),
            .secondaryCircleButton { [weak self] component in
                component.isHidden = !viewItem.hasInfo
                component.button.set(image: UIImage(named: "circle_information_20"), style: .transparent)
                component.onTap = {
                    self?.viewModel.onTapInfo(index: index)
                }
            },
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
                                autoDeselect: true,
                                bind: { cell in
                                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                                }
                        )
                    }
            )
        ]
    }

}
