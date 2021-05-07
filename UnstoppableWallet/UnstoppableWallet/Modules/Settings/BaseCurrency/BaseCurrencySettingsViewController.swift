import UIKit
import SectionsTableView
import ThemeKit
import ComponentKit
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
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.disclaimerSignal) { [weak self] in self?.openDisclaimer(codes: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.navigationController?.popViewController(animated: true) }

        tableView.buildSections()
    }

    private func openDisclaimer(codes: String) {
        let viewController = BaseCurrencyDisclaimerViewController(codes: codes) { [weak self] in
            self?.viewModel.onAcceptDisclaimer()
        }

        present(viewController.toBottomSheet, animated: true)
    }

}

extension BaseCurrencySettingsViewController: SectionsDataSource {

    private func row(viewItem: BaseCurrencySettingsViewModel.ViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<G4Cell>(
                id: viewItem.code,
                height: .heightDoubleLineCell,
                autoDeselect: true,
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

    private func rows(viewItems: [BaseCurrencySettingsViewModel.ViewItem]) -> [RowProtocol] {
        viewItems.enumerated().map { index, viewItem in
            row(viewItem: viewItem, isFirst: index == 0, isLast: index == viewItems.count - 1)
        }
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

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "popular",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin12),
                    rows: rows(viewItems: viewModel.popularViewItems)
            ),
            Section(
                    id: "other",
                    headerState: header(text: "settings.base_currency.other".localized.uppercased()),
                    footerState: .margin(height: .margin32),
                    rows: rows(viewItems: viewModel.otherViewItems)
            ),
            Section(
                    id: "crypto",
                    footerState: .margin(height: viewModel.cryptoViewItems.isEmpty ? 0 : .margin32),
                    rows: rows(viewItems: viewModel.cryptoViewItems)
            )
        ]
    }

}

