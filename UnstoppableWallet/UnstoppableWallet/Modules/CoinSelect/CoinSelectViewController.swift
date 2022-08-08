import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import MarketKit
import ComponentKit
import Alamofire

class CoinSelectViewController: ThemeSearchViewController {
    private let viewModel: CoinSelectViewModel
    private weak var delegate: ICoinSelectDelegate?
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private var viewItems = [CoinSelectViewModel.ViewItem]()

    init(viewModel: CoinSelectViewModel, delegate: ICoinSelectDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "choose_coin.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        navigationItem.searchController?.searchBar.placeholder = "placeholder.search".localized

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.handle(viewItems: $0) }
    }

    @objc func onTapClose() {
        dismiss(animated: true)
    }

    private func onSelect(token: Token) {
        delegate?.didSelect(token: token)
        dismiss(animated: true)
    }

    private func handle(viewItems: [CoinSelectViewModel.ViewItem]) {
        self.viewItems = viewItems

        tableView.reload()
    }

    override func onUpdate(filter: String?) {
        viewModel.apply(filter: filter)
    }

}

extension CoinSelectViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "coins",
                    headerState: .margin(height: .margin3x),
                    footerState: .margin(height: .margin8x),
                    rows: viewItems.enumerated().map { index, viewItem in
                        let isLast = index == viewItems.count - 1

                        return CellBuilderNew.row(
                                rootElement: .hStack([
                                    .image24 { component in
                                        component.setImage(urlString: viewItem.token.coin.imageUrl, placeholder: UIImage(named: viewItem.token.placeholderImageName))
                                    },
                                    .vStackCentered([
                                        .hStack([
                                            .text { component in
                                                component.font = .body
                                                component.textColor = .themeLeah
                                                component.text = viewItem.token.coin.code
                                            },
                                            .text { component in
                                                component.font = .body
                                                component.textColor = .themeLeah
                                                component.textAlignment = .right
                                                component.setContentCompressionResistancePriority(.required, for: .horizontal)
                                                component.text = viewItem.balance
                                            }
                                        ]),
                                        .margin(3),
                                        .hStack([
                                            .text { component in
                                                component.font = .subhead2
                                                component.textColor = .themeGray
                                                component.text = viewItem.token.coin.name
                                            },
                                            .text { component in
                                                component.setContentCompressionResistancePriority(.required, for: .horizontal)
                                                component.setContentHuggingPriority(.required, for: .horizontal)
                                                component.textAlignment = .right
                                                component.font = .subhead2
                                                component.textColor = .themeGray
                                                component.text = viewItem.fiatBalance
                                            }
                                        ])
                                    ])
                                ]),
                                tableView: tableView,
                                id: "coin_\(index)",
                                height: .heightDoubleLineCell,
                                autoDeselect: true,
                                bind: { cell in
                                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                                },
                                action: { [weak self] in
                                    self?.onSelect(token: viewItem.token)
                                }
                        )
                    }
            )
        ]
    }

}
