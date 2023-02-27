import UIKit
import ThemeKit
import ComponentKit
import SectionsTableView
import RxSwift
import RxCocoa

class SendBitcoinViewController: BaseSendViewController {
    private let disposeBag = DisposeBag()

    private let feeWarningViewModel: ITitledCautionViewModel

    private let feeCell: FeeCell
    private let feeCautionCell = TitledHighlightedDescriptionCell()

    init(confirmationFactory: ISendConfirmationFactory,
         feeSettingsFactory: ISendFeeSettingsFactory,
         viewModel: SendViewModel,
         availableBalanceViewModel: SendAvailableBalanceViewModel,
         amountInputViewModel: AmountInputViewModel,
         amountCautionViewModel: SendAmountCautionViewModel,
         recipientViewModel: RecipientAddressViewModel,
         feeViewModel: SendFeeViewModel,
         feeWarningViewModel: ITitledCautionViewModel
    ) {

        self.feeWarningViewModel = feeWarningViewModel

        feeCell = FeeCell(viewModel: feeViewModel, title: "fee_settings.fee".localized)

        super.init(
                confirmationFactory: confirmationFactory,
                feeSettingsFactory: feeSettingsFactory,
                viewModel: viewModel,
                availableBalanceViewModel: availableBalanceViewModel,
                amountInputViewModel: amountInputViewModel,
                amountCautionViewModel: amountCautionViewModel,
                recipientViewModel: recipientViewModel
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        feeCell.onOpenInfo = { [weak self] in
            self?.openInfo(title: "fee_settings.fee".localized, description: "fee_settings.fee.info".localized)
        }

        subscribe(disposeBag, feeWarningViewModel.cautionDriver) { [weak self] in
            self?.handle(caution: $0)
        }

        didLoad()
    }

    private func handle(caution: TitledCaution?) {
        feeCautionCell.isVisible = caution != nil

        if let caution = caution {
            feeCautionCell.bind(caution: caution)
        }

        reloadTable()
    }

    private func openInfo(title: String, description: String) {
        let viewController = BottomSheetModule.description(title: title, text: description)
        present(viewController, animated: true)
    }

    var feeSection: SectionProtocol {
        Section(
                id: "fee",
                headerState: .margin(height: .margin12),
                rows: [
                    StaticRow(
                            cell: feeCell,
                            id: "fee",
                            height: .heightDoubleLineCell
                    )
                ]
        )
    }

    var feeWarningSection: SectionProtocol {
        Section(
                id: "fee-warning",
                headerState: .margin(height: .margin12),
                rows: [
                    StaticRow(
                            cell: feeCautionCell,
                            id: "fee-warning",
                            dynamicHeight: { [weak self] containerWidth in
                                self?.feeCautionCell.cellHeight(containerWidth: containerWidth) ?? 0
                            }
                    )
                ]
        )
    }

    override func buildSections() -> [SectionProtocol] {
        var sections = [availableBalanceSection, amountSection, recipientSection, feeSection]
        sections.append(contentsOf: [feeWarningSection, buttonSection])

        return sections
    }

}
