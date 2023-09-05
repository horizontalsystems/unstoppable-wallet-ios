import Combine
import UIKit
import Alamofire
import RxSwift
import SnapKit
import ComponentKit
import MarketKit
import ThemeKit
import SectionsTableView

class TransactionsCoinSelectViewController: ThemeSearchViewController {
    private let viewModel: TransactionsCoinSelectViewModel
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private var viewItems = [TransactionsCoinSelectViewModel.ViewItem]()

    init(viewModel: TransactionsCoinSelectViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "transactions.choose_coin".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        navigationItem.searchController?.searchBar.placeholder = "placeholder.search".localized

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.handle(viewItems: $0) }

        $filter
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.viewModel.apply(filter: $0) }
                .store(in: &cancellables)
    }

    @objc func onTapCancel() {
        dismiss(animated: true)
    }

    private func onSelect(index: Int) {
        viewModel.onSelect(index: index)
        dismiss(animated: true)
    }

    private func handle(viewItems: [TransactionsCoinSelectViewModel.ViewItem]) {
        self.viewItems = viewItems

        tableView.reload()
    }

}

extension TransactionsCoinSelectViewController: SectionsDataSource {

    private func allRow(selected: Bool, index: Int, isLast: Bool) -> RowProtocol {
        tableView.universalRow48(
                id: "all-row",
                image: .local(UIImage(named: "circle_coin_24")?.withTintColor(.themeGray)),
                title: .body("transactions.all_coins".localized),
                accessoryType: .check(selected),
                backgroundStyle: .transparent,
                isLast: isLast,
                action: { [weak self] in
                    self?.onSelect(index: index)
                }
        )
    }

    private func row(viewItem: TransactionsCoinSelectViewModel.TokenViewItem, selected: Bool, index: Int, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .imageElement(image: .url(viewItem.imageUrl, placeholder: viewItem.placeholderImageName), size: .image32),
                    .vStackCentered([
                        .hStack([
                            .textElement(text: .body(viewItem.code),  parameters: .highHugging),
                            .margin(6),
                            .badge { (component: BadgeComponent) -> () in
                                component.badgeView.isHidden = viewItem.badge == nil
                                component.badgeView.text = viewItem.badge
                                component.badgeView.set(style: .small)
                            },
                            .margin0,
                            .text { _ in  }
                        ]),
                        .margin(1),
                        .textElement(text: .subhead2(viewItem.name))
                    ]),
                    .image20 { (component: ImageComponent) -> () in
                        component.isHidden = !selected
                        component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                    }
                ]),
                tableView: tableView,
                id: "row-\(index)",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                },
                action: { [weak self] in
                    self?.onSelect(index: index)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "coins",
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        let isLast = index == viewItems.count - 1

                        switch viewItem.type {
                        case .all:
                            return allRow(selected: viewItem.selected, index: index, isLast: isLast)
                        case .token(let tokenViewItem):
                            return row(viewItem: tokenViewItem, selected: viewItem.selected, index: index, isLast: isLast)
                        }
                    }
            )
        ]
    }

}
