import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView

class CexDepositNetworkSelectViewController: ThemeViewController {
    private let viewModel: CexDepositNetworkSelectViewModel

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: CexDepositNetworkSelectViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "cex_deposit_network_select.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc func onTapCancel() {
        dismiss(animated: true)
    }

    private func onSelect(cexNetwork: CexNetwork) {
        let cexAsset = viewModel.cexAsset
        // todo
    }

}

extension CexDepositNetworkSelectViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.descriptionRow(
                                id: "description",
                                text: "cex_deposit_network_select.description".localized,
                                font: .subhead2,
                                textColor: .themeGray,
                                ignoreBottomMargin: true
                        )
                    ]
            ),
            Section(
                    id: "cex-networks",
                    footerState: .margin(height: .margin32),
                    rows: viewModel.viewItems.enumerated().map { index, viewItem in
                        tableView.universalRow56(
                                id: "cex-network-\(index)",
                                image: .url(viewItem.imageUrl, placeholder: "placeholder_rectangle_32"),
                                title: .body(viewItem.title),
                                accessoryType: .disclosure,
                                isFirst: index == 0,
                                isLast: index == viewModel.viewItems.count - 1,
                                action: { [weak self] in
                                    self?.onSelect(cexNetwork: viewItem.cexNetwork)
                                }
                        )
                    }
            )
        ]
    }

}
