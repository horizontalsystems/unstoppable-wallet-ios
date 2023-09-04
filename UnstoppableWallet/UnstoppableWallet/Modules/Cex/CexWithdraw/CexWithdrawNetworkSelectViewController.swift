import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView

protocol ICexWithdrawNetworkSelectDelegate: AnyObject {
    func onSelect(index: Int)
}

class CexWithdrawNetworkSelectViewController: ThemeViewController {
    weak var delegate: ICexWithdrawNetworkSelectDelegate?

    private let tableView = SectionsTableView(style: .grouped)
    private let viewItems: [CexWithdrawViewModel.NetworkViewItem]
    private let selectedNetworkIndex: Int?

    init(viewItems: [CexWithdrawViewModel.NetworkViewItem], selectedNetworkIndex: Int?) {
        self.viewItems = viewItems
        self.selectedNetworkIndex = selectedNetworkIndex

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "cex_withdraw_network_select.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .plain, target: self, action: #selector(onTapDone))
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

    @objc func onTapDone() {
        _ = navigationController?.popViewController(animated: true)
    }

    private func onSelect(index: Int) {
        delegate?.onSelect(index: index)
        dismiss(animated: true)
    }

}

extension CexWithdrawNetworkSelectViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "description",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: [
                    tableView.descriptionRow(
                        id: "description",
                        text: "cex_withdraw_network_select.description".localized,
                        font: .subhead2,
                        textColor: .themeGray,
                        ignoreBottomMargin: true
                    )
                ]
            ),
            Section(
                id: "cex-networks",
                footerState: .margin(height: .margin32),
                rows: viewItems.enumerated().map { index, viewItem in
                    let isFirst = index == 0
                    let isLast = index == viewItems.count - 1

                    return CellBuilderNew.row(
                        rootElement: .hStack([
                            .image32 { component in
                                component.setImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: "placeholder_rectangle_32"))
                            },
                            .textElement(text: .body(viewItem.title)),
                            .imageElement(image: selectedNetworkIndex == index ? .local(UIImage(named: "check_1_20")) : nil, size: .image20),
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
                            self?.onSelect(index: viewItem.index)
                        } : nil
                    )
                }
            )
        ]
    }

}
