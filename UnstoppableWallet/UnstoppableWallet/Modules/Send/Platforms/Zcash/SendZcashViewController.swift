import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class SendZcashViewController: BaseSendViewController {
    private let feeCell: FeeCell

    init(confirmationFactory: ISendConfirmationFactory,
         viewModel: SendViewModel,
         availableBalanceViewModel: SendAvailableBalanceViewModel,
         amountInputViewModel: AmountInputViewModel,
         amountCautionViewModel: SendAmountCautionViewModel,
         recipientViewModel: RecipientAddressViewModel,
         memoViewModel: SendMemoInputViewModel,
         feeViewModel: SendFeeViewModel)
    {
        feeCell = FeeCell(viewModel: feeViewModel, title: "fee_settings.fee".localized)

        super.init(
            confirmationFactory: confirmationFactory,
            viewModel: viewModel,
            availableBalanceViewModel: availableBalanceViewModel,
            amountInputViewModel: amountInputViewModel,
            amountCautionViewModel: amountCautionViewModel,
            recipientViewModel: recipientViewModel,
            memoViewModel: memoViewModel
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        feeCell.onOpenInfo = { [weak self] in
            self?.openInfo(title: "fee_settings.fee".localized, description: "fee_settings.fee.info".localized)
        }

        didLoad()
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
                    height: .heightCell48
                ),
            ]
        )
    }

    override func buildSections() -> [SectionProtocol] {
        var sections = super.buildSections()
        sections.append(contentsOf: [
            memoSection,
            feeSection,
            buttonSection,
        ])

        return sections
    }
}
