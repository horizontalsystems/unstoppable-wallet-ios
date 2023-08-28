import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import ComponentKit
import MarketKit

class DonateAddressViewController: ThemeViewController {
    typealias ViewItem = (String, BlockchainType, String)
    private let viewItems: [ViewItem]

    private let tableView = SectionsTableView(style: .grouped)

    override init() {
        var viewItems = [ViewItem]()

        for (coinName, address) in AppConfig.donationAddresses {
            switch coinName {
                case "BTC": viewItems.append(ViewItem("Bitcoin", .bitcoin, address))
                case "ETH": viewItems.append(ViewItem("Ethereum", .ethereum, address))
                case "BNB": viewItems.append(ViewItem("BNB Smart Chain", .binanceSmartChain, address))
                default: ()
            }
        }

        self.viewItems = viewItems

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.donate.title".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: DonateCell.self)
        tableView.registerCell(forClass: MarkdownHeader1Cell.self)

        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.buildSections()
    }

    @objc private func onTapDoneButton() {
        dismiss(animated: true)
    }

    private var desriptionSections: [SectionProtocol] {
        [
            Section(
                id: "description-section",
                headerState: .margin(height: .margin24),
                footerState: .margin(height: .margin24),
                rows: [
                    Row<DonateCell>(
                        id: "description",
                        autoDeselect: true,
                        dynamicHeight: { containerWidth in DonateCell.height(text: "settings.donate.description".localized) },
                        bind: { cell, _ in
                            cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                            cell.bind(
                                icon: UIImage(named: "heart_fill_48")?.withTintColor(.themeJacob),
                                text: "settings.donate.description".localized
                            )
                        }
                    )
                ]
            )
        ]
    }

    private var addressSections: [SectionProtocol] {
        viewItems
            .sorted(by: { $0.1.order < $1.1.order })
            .enumerated().map { index, viewItem -> SectionProtocol in
                Section(
                    id: "section-id-\(index)",
                    headerState: tableView.sectionHeader(text: viewItem.0),
                    footerState: .margin(height: .margin24),
                    rows: [
                        CellBuilderNew.row(
                            rootElement: .hStack([
                                .image32 { (component: ImageComponent) -> () in
                                    component.setImage(
                                        urlString: viewItem.1.imageUrl,
                                        placeholder: UIImage(named: viewItem.1.placeholderImageName(tokenProtocol: .native))
                                    )
                                },
                                .text { component in
                                    component.font = .subhead2
                                    component.textColor = .themeLeah
                                    component.text = viewItem.2
                                    component.textAlignment = .right
                                    component.numberOfLines = 0
                                },
                                .secondaryCircleButton { component in
                                    component.button.set(image: UIImage(named: "copy_20"))
                                    component.onTap = {
                                        CopyHelper.copyAndNotify(value: viewItem.2)
                                    }
                                }
                            ]),
                            tableView: tableView,
                            id: "donate-address-\(index)",
                            hash: "donate-address-hash-\(index)",
                            height: .heightCell56,
                            bind: { cell in
                                cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                            }
                        )
                    ]
                )
            }
    }

}

extension DonateAddressViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        desriptionSections + addressSections
    }

}
