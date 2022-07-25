import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import MarketKit
import ComponentKit
import Alamofire

class TransactionsCoinSelectViewController: ThemeSearchViewController {
    private let viewModel: TransactionsCoinSelectViewModel
    private let disposeBag = DisposeBag()

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

    override func onUpdate(filter: String?) {
        viewModel.apply(filter: filter)
    }

}

extension TransactionsCoinSelectViewController: SectionsDataSource {

    private func allRow(selected: Bool, index: Int, isLast: Bool) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image24, .text, .image20],
                tableView: tableView,
                id: "all-row",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: "circle_coin_24")?.withTintColor(.themeGray)
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = "transactions.all_coins".localized
                    }

                    cell.bind(index: 2) { (component: ImageComponent) in
                        component.isHidden = !selected
                        component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                    }
                },
                action: { [weak self] in
                    self?.onSelect(index: index)
                }
        )
    }

    private func row(viewItem: TransactionsCoinSelectViewModel.TokenViewItem, selected: Bool, index: Int, isLast: Bool) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image24, .multiText, .image20],
                tableView: tableView,
                id: "row-\(index)",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.setImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: viewItem.placeholderImageName))
                    }

                    cell.bind(index: 1) { (component: MultiTextComponent) in
                        component.set(style: .m7)
                        component.title.font = .body
                        component.title.textColor = .themeLeah
                        component.subtitle.font = .subhead2
                        component.subtitle.textColor = .themeGray

                        component.title.text = viewItem.code
                        component.subtitle.text = viewItem.name

                        component.titleBadge.isHidden = viewItem.badge == nil
                        component.titleBadge.text = viewItem.badge
                    }

                    cell.bind(index: 2) { (component: ImageComponent) in
                        component.isHidden = !selected
                        component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                    }
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
