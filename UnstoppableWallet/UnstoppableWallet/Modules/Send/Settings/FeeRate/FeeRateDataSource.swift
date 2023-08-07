import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class FeeRateDataSource {
    private let feeRateViewModel: FeeRateViewModel
    private let disposeBag = DisposeBag()

    private let feeCell: FeeCell
    private let feeRateCell: StepperAmountInputCell

    weak var tableView: SectionsTableView?
    var onOpenInfo: ((String, String) -> ())? = nil
    var present: ((UIViewController) -> ())? = nil
    var onUpdateAlteredState: (() -> ())? = nil
    var onCaution: ((TitledCaution?) -> ())? = nil

    init(feeViewModel: SendFeeViewModel, feeRateViewModel: FeeRateViewModel) {
        self.feeRateViewModel = feeRateViewModel

        feeCell = FeeCell(viewModel: feeViewModel, title: "fee_settings.fee".localized)
        feeRateCell = StepperAmountInputCell(allowFractionalNumbers: false)
    }

    func viewDidLoad() {
        feeCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)

        feeCell.onOpenInfo = { [weak self] in
            self?.onOpenInfo?("fee_settings.fee".localized, "fee_settings.fee.info".localized)
        }

        subscribe(disposeBag, feeRateViewModel.feeRateDriver) { [weak self] in self?.feeRateCell.value = $0 }
        subscribe(disposeBag, feeRateViewModel.alteredStateSignal) { [weak self] in self?.onUpdateAlteredState?() }
        subscribe(disposeBag, feeRateViewModel.cautionDriver) { [weak self] in self?.handleCaution(caution: $0) }

        feeRateCell.onChangeValue = { [weak self] value in self?.feeRateViewModel.set(value: value) }
    }

    private func handleCaution(caution: TitledCaution?) {
        feeRateCell.set(cautionType: caution?.type)
        onCaution?(caution)
    }

}

extension FeeRateDataSource: ISendSettingsDataSource {

    var altered: Bool {
        feeRateViewModel.altered
    }

    var buildSections: [SectionProtocol] {
        guard let tableView = tableView else {
            return []
        }

        return [
            Section(
                    id: "fee",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: feeCell,
                                id: "fee-cell",
                                height: .heightDoubleLineCell
                        )
                    ]
            ),
            Section(
                    id: "fee-rate",
                    headerState: .margin(height: .margin24),
                    rows: [
                        tableView.subtitleWithInfoButtonRow(text: "fee_settings.fee_rate".localized + " (Sat/Byte)", uppercase: false)  { [weak self] in
                            self?.present?(InfoModule.feeInfo)
                        },
                        StaticRow(
                                cell: feeRateCell,
                                id: "fee-rate-cell",
                                height: .heightCell48
                        ),
                        tableView.descriptionRow(
                                id: "fee-rate-description-cell",
                                text: "fee_settings.fee_rate.description".localized,
                                font: .subhead2,
                                textColor: .themeGray,
                                ignoreBottomMargin: true
                        )
                    ]
            )
        ]
    }

    func onTapReset() {
        feeRateViewModel.reset()
    }

}
