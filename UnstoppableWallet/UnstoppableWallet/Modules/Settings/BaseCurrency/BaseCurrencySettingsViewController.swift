import UIKit
import SectionsTableView
import ThemeKit
import RxSwift

class BaseCurrencySettingsViewController: ThemeViewController {
    private let viewModel: BaseCurrencySettingsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: BaseCurrencySettingsViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings.base_currency.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: G4Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.navigationController?.popViewController(animated: true) }

        tableView.buildSections()
    }

}

extension BaseCurrencySettingsViewController: SectionsDataSource {

    private func row(viewItem: BaseCurrencySettingsViewModel.ViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<G4Cell>(
                id: viewItem.code,
                height: .heightDoubleLineCell,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = viewItem.code
                    cell.titleImage = viewItem.icon
                    cell.subtitle = viewItem.symbol
                    cell.valueImage = viewItem.selected ? UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate) : nil
                    cell.valueImageTintColor = .themeJacob
                },
                action: { [weak self] _ in
                    self?.viewModel.onSelect(viewItem: viewItem)
                }
        )
    }

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { containerWidth in
                    SubtitleHeaderFooterView.height
                }
        )
    }

    private func footer(text: String) -> ViewState<BottomDescriptionHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { containerWidth in
                    BottomDescriptionHeaderFooterView.height(containerWidth: containerWidth, text: text)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "popular",
                    headerState: header(text: "settings.base_currency.popular".localized),
                    footerState: .margin(height: .margin32),
                    rows: viewModel.popularViewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, isFirst: index == 0, isLast: index == viewModel.popularViewItems.count - 1)
                    }
            ),
            Section(
                    id: "all",
                    headerState: header(text: "settings.base_currency.all".localized),
                    footerState: footer(text: "settings.base_currency.provided_by".localized),
                    rows: viewModel.allViewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, isFirst: index == 0, isLast: index == viewModel.allViewItems.count - 1)
                    }
            )
        ]
    }

}
