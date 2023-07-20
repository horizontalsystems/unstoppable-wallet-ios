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

        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.disclaimerSignal) { [weak self] in self?.openDisclaimer(codes: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.navigationController?.popViewController(animated: true) }

        tableView.buildSections()
    }

    private func openDisclaimer(codes: String) {
        let viewController = BottomSheetModule.viewController(
                image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)),
                title: "settings.base_currency.disclaimer".localized,
                items: [
                    .highlightedDescription(text: "settings.base_currency.disclaimer.description".localized(AppConfig.appName, codes))
                ],
                buttons: [
                    .init(style: .yellow, title: "settings.base_currency.disclaimer.set".localized) { [ weak self] in self?.viewModel.onAcceptDisclaimer() },
                    .init(style: .transparent, title: "button.cancel".localized)
                ]
        )

        present(viewController, animated: true)
    }

}

extension BaseCurrencySettingsViewController: SectionsDataSource {

    private func row(viewItem: BaseCurrencySettingsViewModel.ViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        tableView.universalRow62(
                id: viewItem.code,
                image: .local(viewItem.icon),
                title: .body(viewItem.code),
                description: .subhead2(viewItem.symbol),
                accessoryType: .check(viewItem.selected),
                hash: "\(viewItem.selected)",
                autoDeselect: true,
                isFirst: isFirst,
                isLast: isLast,
                action: { [weak self] in
                    self?.viewModel.onSelect(viewItem: viewItem)
                }
        )
    }

    private func rows(viewItems: [BaseCurrencySettingsViewModel.ViewItem]) -> [RowProtocol] {
        viewItems.enumerated().map { index, viewItem in
            row(viewItem: viewItem, isFirst: index == 0, isLast: index == viewItems.count - 1)
        }
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "popular",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin24),
                    rows: rows(viewItems: viewModel.popularViewItems)
            ),
            Section(
                    id: "other",
                    headerState: tableView.sectionHeader(text: "settings.base_currency.other".localized.uppercased()),
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

