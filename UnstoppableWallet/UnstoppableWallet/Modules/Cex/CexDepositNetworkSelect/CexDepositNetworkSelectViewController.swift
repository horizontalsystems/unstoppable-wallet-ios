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

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

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
        super.viewWillAppear(animated)
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc func onTapCancel() {
        dismiss(animated: true)
    }

    private func onSelect(network: CexDepositNetwork) {
        let cexAsset = viewModel.cexAsset

        guard let viewController = CexDepositModule.viewController(cexAsset: cexAsset, network: network) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
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
                        let isFirst = index == 0
                        let isLast = index == viewModel.viewItems.count - 1

                        return CellBuilderNew.row(
                                rootElement: .hStack([
                                    .image32 { component in
                                        component.setImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: "placeholder_rectangle_32"))
                                    },
                                    .textElement(text: .body(viewItem.title)),
                                    .imageElement(image: viewItem.enabled ? .local(UIImage(named: "arrow_big_forward_20")) : nil, size: .image20),
                                    .badge { component in
                                        component.isHidden = viewItem.enabled
                                        component.badgeView.set(style: .small)
                                        component.badgeView.text = "cex_coin_select.suspended".localized.uppercased()
                                    }
                                ]),
                                tableView: tableView,
                                id: "cex-network-\(index)",
                                height: .heightCell56,
                                bind: { cell in
                                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                                },
                                action: viewItem.enabled ? { [weak self] in
                                    self?.onSelect(network: viewItem.network)
                                } : nil
                        )
                    }
            )
        ]
    }

}
