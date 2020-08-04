import UIKit
import SectionsTableView
import ThemeKit

class UniswapInfoViewController: ThemeViewController {
    private let delegate: IUniswapInfoViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: IUniswapInfoViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.uniswap_info.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerHeaderFooter(forClass: InfoSeparatorHeaderView.self)
        tableView.registerHeaderFooter(forClass: InfoHeaderView.self)
        tableView.registerCell(forClass: ButtonCell.self)
        tableView.registerCell(forClass: DescriptionCell.self)

        tableView.sectionDataSource = self

        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.buildSections()
    }

    @objc private func onClose() {
        delegate.onTapClose()
    }

    private func header(text: String) -> ViewState<InfoHeaderView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { width in
                    InfoHeaderView.height(containerWidth: width, text: text)
                }
        )
    }

    private func row(text: String) -> RowProtocol {
        Row<DescriptionCell>(
                id: text,
                dynamicHeight: { width in
                    DescriptionCell.height(containerWidth: width, text: text)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    private func onTapLink() {
        delegate.onTapLink()
    }

}

extension UniswapInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let separatorHeaderState: ViewState<InfoSeparatorHeaderView> = .cellType(
                hash: "separator",
                binder: nil,
                dynamicHeight: { _ in
                    InfoSeparatorHeaderView.height
                }
        )

        return [
            Section(
                    id: "description",
                    headerState: separatorHeaderState,
                    rows: [row(text: "swap.uniswap_info.description".localized)]
            ),
            Section(
                    id: "received",
                    headerState: header(text: "swap.uniswap_info.header_minimum_received".localized),
                    rows: [row(text: "swap.uniswap_info.content_minimum_received".localized)]
            ),
            Section(
                    id: "price_impact",
                    headerState: header(text: "swap.uniswap_info.header_price_impact".localized),
                    rows: [row(text: "swap.uniswap_info.content_price_impact".localized)]
            ),
            Section(
                    id: "swap_fee",
                    headerState: header(text: "swap.uniswap_info.header_swap_fee".localized),
                    rows: [row(text: "swap.uniswap_info.content_swap_fee".localized)]
            ),
            Section(
                    id: "swap_link_button",
                    headerState: .margin(height: .margin3x),
                    footerState: .margin(height: .margin8x),
                    rows: [
                        Row<ButtonCell>(
                                id: "swap_row",
                                height: ThemeButton.height(style: .secondaryDefault),
                                bind: { [weak self] cell, _ in
                                    cell.bind(style: .secondaryDefault, title: "swap.uniswap_info.link_button".localized, compact: true) { [weak self] in
                                        self?.onTapLink()
                                    }
                                }
                        )
                    ]
            )
        ]
    }

}
