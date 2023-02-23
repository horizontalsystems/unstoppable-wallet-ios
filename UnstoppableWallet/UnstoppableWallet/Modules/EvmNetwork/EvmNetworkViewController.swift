import UIKit
import SectionsTableView
import ThemeKit
import RxSwift
import ComponentKit

class EvmNetworkViewController: ThemeViewController {
    private let viewModel: EvmNetworkViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let iconImageView = UIImageView()

    private var defaultViewItems = [EvmNetworkViewModel.ViewItem]()
    private var customViewItems = [EvmNetworkViewModel.ViewItem]()
    private var isLoaded = false

    init(viewModel: EvmNetworkViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .plain, target: self, action: #selector(onTapDone))

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.iconSize24)
        }
        iconImageView.cornerRadius = .cornerRadius4
        iconImageView.cornerCurve = .continuous
        iconImageView.setImage(withUrlString: viewModel.iconUrl, placeholder: UIImage(named: "placeholder_rectangle_24"))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.stateDriver) { [weak self] state in
            self?.defaultViewItems = state.defaultViewItems
            self?.customViewItems = state.customViewItems
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.dismiss(animated: true)
        }

        tableView.buildSections()

        isLoaded = true
    }

    @objc private func onTapDone() {
        dismiss(animated: true)
    }

    private func reloadTable() {
        if isLoaded {
            tableView.reload(animated: true)
        }
    }

    private func openRpcSourceInfo() {
        present(InfoModule.rpcSourceInfo, animated: true)
    }

    private func openAddNew() {
        let module = AddEvmSyncSourceModule.viewController(blockchainType: viewModel.blockchainType)
        present(module, animated: true)
    }

}

extension EvmNetworkViewController: SectionsDataSource {

    private func customRowActions(index: Int) -> [RowAction] {
        [
            RowAction(
                    pattern: .icon(image: UIImage(named: "circle_minus_shifted_24"), background: UIColor(red: 0, green: 0, blue: 0, alpha: 0)),
                    action: { [weak self] _ in
                        self?.viewModel.onRemoveCustom(index: index)
                    }
            )
        ]
    }

    private func row(id: String, viewItem: EvmNetworkViewModel.ViewItem, rowActionProvider: (() -> [RowAction])? = nil, isFirst: Bool, isLast: Bool, action: @escaping () -> ()) -> RowProtocol {
        tableView.universalRow62(
                id: id,
                title: .body(viewItem.name),
                description: .subhead2(viewItem.url),
                accessoryType: .check(viewItem.selected),
                hash: "\(viewItem.selected)-\(isFirst)-\(isLast)",
                autoDeselect: true,
                rowActionProvider: rowActionProvider,
                isFirst: isFirst,
                isLast: isLast,
                action: action
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "default",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: customViewItems.isEmpty ? .margin32 : .margin24),
                    rows: [
                        tableView.subtitleWithInfoButtonRow(text: "evm_network.rpc_source".localized) { [weak self] in
                            self?.openRpcSourceInfo()
                        }
                    ] + defaultViewItems.enumerated().map { index, viewItem in
                        row(
                                id: "default-\(index)",
                                viewItem: viewItem,
                                isFirst: index == 0,
                                isLast: index == defaultViewItems.count - 1,
                                action: { [weak self] in
                                    self?.viewModel.onSelectDefault(index: index)
                                }
                        )
                    }
            )
        ]

        if !customViewItems.isEmpty {
            sections.append(
                    Section(
                            id: "custom",
                            headerState: tableView.sectionHeader(text: "evm_network.added".localized),
                            footerState: .margin(height: .margin32),
                            rows: customViewItems.enumerated().map { index, viewItem in
                                row(
                                        id: "custom-\(index)",
                                        viewItem: viewItem,
                                        rowActionProvider: { [weak self] in
                                            self?.customRowActions(index: index) ?? []
                                        },
                                        isFirst: index == 0,
                                        isLast: index == customViewItems.count - 1,
                                        action: { [weak self] in
                                            self?.viewModel.onSelectCustom(index: index)
                                        }
                                )
                            }
                    )
            )
        }

        sections.append(
                Section(
                        id: "add-new",
                        footerState: .margin(height: .margin32),
                        rows: [
                            tableView.universalRow48(
                                    id: "add-new",
                                    image: .local(UIImage(named: "plus_24")?.withTintColor(.themeJacob)),
                                    title: .body("evm_network.add_new".localized, color: .themeJacob),
                                    autoDeselect: true,
                                    isFirst: true,
                                    isLast: true,
                                    action: { [weak self] in
                                        self?.openAddNew()
                                    }
                            )
                        ]
                )
        )

        return sections
    }

}
