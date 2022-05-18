import UIKit
import ThemeKit
import SnapKit
import SectionsTableView

class SendZcashViewController: BaseSendViewController {

    private let memoCell: SendMemoInputCell
    private let feeCell: FeeCell

    init(confirmationFactory: ISendConfirmationFactory,
         viewModel: SendViewModel,
         availableBalanceViewModel: SendAvailableBalanceViewModel,
         amountInputViewModel: AmountInputViewModel,
         amountCautionViewModel: SendAmountCautionViewModel,
         recipientViewModel: RecipientAddressViewModel,
         memoViewModel: SendMemoInputViewModel,
         feeViewModel: SendFeeViewModel
    ) {
        memoCell = SendMemoInputCell(viewModel: memoViewModel, topInset: .margin12)
        feeCell = FeeCell(viewModel: feeViewModel)

        super.init(
                confirmationFactory: confirmationFactory,
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

        memoCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }

        didLoad()
    }

    var memoSection: SectionProtocol {
        Section(
                id: "memo",
                rows: [
                    StaticRow(
                            cell: memoCell,
                            id: "memo-input",
                            dynamicHeight: { [weak self] width in
                                self?.memoCell.height(containerWidth: width) ?? 0
                            }
                    )
                ]
        )
    }

    var feeSection: SectionProtocol {
        Section(
                id: "fee",
                headerState: .margin(height: .margin12),
                rows: [
                    StaticRow(
                            cell: feeCell,
                            id: "fee",
                            height: .heightCell48
                    )
                ]
        )
    }

    override func buildSections() -> [SectionProtocol] {
        [
            availableBalanceSection,
            amountSection,
            recipientSection,
            memoSection,
            feeSection,
            buttonSection
        ]
    }

}
