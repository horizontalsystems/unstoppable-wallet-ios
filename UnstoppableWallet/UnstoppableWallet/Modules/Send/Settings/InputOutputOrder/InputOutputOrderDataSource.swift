import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class InputOutputOrderDataSource {
    private let viewModel: InputOutputOrderViewModel
    private let disposeBag = DisposeBag()

    private let orderCell: DropDownListCell

    weak var tableView: SectionsTableView?
    var onOpenInfo: ((String, String) -> ())? = nil
    var present: ((UIViewController) -> ())? = nil
    var onUpdateAlteredState: (() -> ())? = nil
    var onCaution: ((TitledCaution?) -> ())? = nil

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
                image: .local(image: UIImage(named: "arrow_medium_2_up_right_24")?.withTintColor(.themeGray)),
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
        guard let tableView = tableView else {
            return []
        }

        return [
            Section(
                    id: "input-order",
                    headerState: .margin(height: .margin24),
                    rows: [
                        tableView.subtitleWithInfoButtonRow(text: "fee_settings.transaction_settings".localized, uppercase: false)  { [weak self] in
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
                        )
                    ]
            )
        ]
    }

    func onTapReset() {
        viewModel.reset()
    }

}
