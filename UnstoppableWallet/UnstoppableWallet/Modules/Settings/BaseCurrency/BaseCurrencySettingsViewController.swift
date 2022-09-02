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
        let title = BottomSheetItem.ComplexTitleViewItem(title: "settings.base_currency.disclaimer".localized, image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob))
        let description = InformationModule.Item.description(text: "settings.base_currency.disclaimer.description".localized(codes), isHighlighted: true)
        let setButton = InformationModule.ButtonItem(style: .yellow, title: "settings.base_currency.disclaimer.set".localized, action: InformationModule.afterClose{ [weak self] in
            self?.viewModel.onAcceptDisclaimer()
        })
        let cancelButton = InformationModule.ButtonItem(style: .transparent, title: "button.cancel".localized, action: InformationModule.afterClose())
        let viewController = InformationModule.viewController(title: .complex(viewItem: title), items: [description], buttons: [setButton, cancelButton]).toBottomSheet

        present(viewController.toBottomSheet, animated: true)
    }

}

extension BaseCurrencySettingsViewController: SectionsDataSource {

    private func row(viewItem: BaseCurrencySettingsViewModel.ViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { component in
                        component.imageView.image = viewItem.icon
                    },
                    .vStackCentered([
                        .text { component in
                            component.font = .body
                            component.textColor = .themeLeah
                            component.text = viewItem.code
                        },
                        .margin(3),
                        .text { component in
                            component.font = .subhead2
                            component.textColor = .themeGray
                            component.text = viewItem.symbol
                        }
                    ]),
                    .image20 { component in
                        component.isHidden = !viewItem.selected
                        component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                    }
                ]),
                tableView: tableView,
                id: viewItem.code,
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                },
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

