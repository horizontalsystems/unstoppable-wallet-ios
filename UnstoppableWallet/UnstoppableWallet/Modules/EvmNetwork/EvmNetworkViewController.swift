import UIKit
import SectionsTableView
import ThemeKit
import RxSwift
import ComponentKit

class EvmNetworkViewController: ThemeViewController {
    private let viewModel: EvmNetworkViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private var isLoaded = false

    private var viewItems = [EvmNetworkViewModel.ViewItem]()

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

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: F4Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }

        tableView.buildSections()

        isLoaded = true
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }

}

extension EvmNetworkViewController: SectionsDataSource {

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { $0.bind(text: text) },
                dynamicHeight: { _ in SubtitleHeaderFooterView.height }
        )
    }

    private func row(viewItem: EvmNetworkViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<F4Cell>(
                id: viewItem.name,
                hash: "\(viewItem.selected)",
                height: .heightDoubleLineCell,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = viewItem.name
                    cell.subtitle = viewItem.url
                    cell.valueImage = viewItem.selected ? UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate) : nil
                    cell.valueImageTintColor = .themeRemus
                },
                action: { [weak self] _ in
                    self?.viewModel.onSelectViewItem(index: index)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewItems.count - 1)
                    }
            )
        ]
    }

}
