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

    init(viewModel: InputOutputOrderViewModel) {
        self.viewModel = viewModel

        orderCell = DropDownListCell(viewModel: viewModel, title: "fee_settings.inputs_outputs".localized)
    }

    func viewDidLoad() {
        orderCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        orderCell.showList = { [weak self] in self?.showList() }
    }

    private func showList() {
        let alertController: UIViewController = AlertRouter.module(
                title: "fee_settings.transaction_settings".localized,
                viewItems: viewModel.itemsList
        ) { [weak self] index in
            self?.viewModel.onSelect(index)
        }

        present?(alertController)
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
                            self?.onOpenInfo?("fee_settings.transaction_settings".localized, "fee_settings.transaction_settings.info".localized)
                        },
                        StaticRow(
                                cell: orderCell,
                                id: "input-order-cell",
                                height: .heightDoubleLineCell,
                                autoDeselect: true
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
