import ComponentKit
import RxCocoa
import RxSwift
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class InputOutputOrderDataSource {
    private let viewModel: InputOutputOrderViewModel
    private let disposeBag = DisposeBag()

    private let orderCell: DropDownListCell

    weak var tableView: SectionsTableView?
    var onOpenInfo: ((String, String) -> Void)?
    var present: ((UIViewController) -> Void)?
    var onUpdateAlteredState: (() -> Void)?
    var onCaution: ((TitledCaution?) -> Void)?

    init(viewModel: InputOutputOrderViewModel) {
        self.viewModel = viewModel

        orderCell = DropDownListCell(viewModel: viewModel, title: "fee_settings.inputs_outputs".localized)
    }

    func viewDidLoad() {
        orderCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        orderCell.showList = { [weak self] in self?.showList() }

        subscribe(disposeBag, viewModel.alteredStateSignal) { [weak self] in self?.onUpdateAlteredState?() }
    }

    private func showList() {
        let viewController = SelectorModule.bottomSingleSelectorViewController(
            image: .local(name: "arrow_medium_2_up_right_24", tint: .gray),
            title: "fee_settings.transaction_settings".localized,
            viewItems: viewModel.itemsList,
            onSelect: { [weak self] index in
                self?.viewModel.onSelect(index)
            }
        )

        present?(viewController)
    }
}

extension InputOutputOrderDataSource: ISendSettingsDataSource {
    var altered: Bool {
        viewModel.altered
    }

    var buildSections: [SectionProtocol] {
        guard let tableView else {
            return []
        }

        return [
            Section(
                id: "input-order",
                headerState: .margin(height: .margin24),
                rows: [
                    tableView.subtitleWithInfoButtonRow(text: "fee_settings.transaction_settings".localized, uppercase: false) { [weak self] in
                        self?.present?(InfoModule.transactionInputsOutputsInfo)
                    },
                    StaticRow(
                        cell: orderCell,
                        id: "input-order-cell",
                        height: .heightDoubleLineCell
                    ),
                    tableView.descriptionRow(
                        id: "input-order-description-cell",
                        text: "fee_settings.transaction_settings.description".localized,
                        font: .subhead2,
                        textColor: .themeGray,
                        ignoreBottomMargin: true
                    ),
                ]
            ),
        ]
    }

    func onTapReset() {
        viewModel.reset()
    }
}
