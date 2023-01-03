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

    private var viewItems = [EvmNetworkViewModel.ViewItem]()
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.iconSize24)
        }
        iconImageView.setImage(withUrlString: viewModel.iconUrl, placeholder: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.dismiss(animated: true)
        }

        tableView.buildSections()

        isLoaded = true
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    private func reloadTable() {
        if isLoaded {
            tableView.reload(animated: true)
        }
    }

    private func openSyncModeInfo() {
        present(InfoModule.syncModeInfo, animated: true)
    }

}

extension EvmNetworkViewController: SectionsDataSource {

    private func row(viewItem: EvmNetworkViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        tableView.universalRow62(id: "sync-node-\(index)",
                title: .body(viewItem.name),
                description: .subhead2(viewItem.url),
                accessoryType: .check(viewItem.selected),
                hash: "\(viewItem.selected)",
                isFirst: isFirst,
                isLast: isLast,
                action: { [weak self] in
                    self?.viewModel.onSelectViewItem(index: index)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "sync-node",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.subtitleWithInfoButtonRow(text: "evm_network.sync_node".localized) { [weak self] in
                            self?.openSyncModeInfo()
                        }
                    ] + viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewItems.count - 1)
                    }
            )
        ]
    }

}
