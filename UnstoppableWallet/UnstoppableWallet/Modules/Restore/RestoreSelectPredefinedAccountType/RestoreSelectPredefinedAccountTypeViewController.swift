import UIKit
import UIExtensions
import SnapKit
import SectionsTableView
import ThemeKit

class RestoreSelectPredefinedAccountTypeViewController: ThemeViewController {
    private let restoreView: RestoreView
    private let viewModel: RestoreSelectPredefinedAccountTypeViewModel

    private let tableView = SectionsTableView(style: .grouped)
    private let viewItems: [RestoreSelectPredefinedAccountTypeViewModel.ViewItem]

    init(restoreView: RestoreView, viewModel: RestoreSelectPredefinedAccountTypeViewModel) {
        self.restoreView = restoreView
        self.viewModel = viewModel
        viewItems = viewModel.viewItems

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.title".localized

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "button.back".localized, style: .plain, target: nil, action: nil)

        tableView.registerCell(forClass: RestoreSelectPredefinedAccountTypeCell.self)
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.buildSections()
    }

    private var walletRows: [RowProtocol] {
        viewItems.enumerated().map { (index, viewItem) in
            Row<RestoreSelectPredefinedAccountTypeCell>(
                    id: "wallet_\(index)_row",
                    autoDeselect: true,
                    dynamicHeight: { containerWidth in
                        RestoreSelectPredefinedAccountTypeCell.height(containerWidth: containerWidth, viewItem: viewItem)
                    },
                    bind: { cell, _ in
                        cell.bind(viewItem: viewItem)
                    },
                    action: { [weak self] _ in
                        self?.onSelect(index: index)
                    }
            )
        }
    }

    private func onSelect(index: Int) {
        restoreView.viewModel.onSelect(predefinedAccountType: viewItems[index].predefinedAccountType)
    }

}

extension RestoreSelectPredefinedAccountTypeViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "wallets",
                    headerState: .margin(height: .margin4x),
                    rows: walletRows
            )
        ]
    }

}
