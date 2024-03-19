import ComponentKit
import RxCocoa
import RxSwift
import SectionsTableView
import ThemeKit
import UIKit

class SendBitcoinViewController: BaseSendViewController {
    private let disposeBag = DisposeBag()

    private let outputSelectorFactory: ISendOutputSelectorFactory
    private let feeCautionViewModel: ITitledCautionViewModel
    private let unspentOutputsViewModel: UnspentOutputsViewModel

    private let unspentOutputsCell: UnspentOutputsCell
    private let feeCell: FeeCell
    private let feeCautionCell = TitledHighlightedDescriptionCell()

    init(confirmationFactory: ISendConfirmationFactory,
         feeSettingsFactory: ISendFeeSettingsFactory,
         outputSelectorFactory: ISendOutputSelectorFactory,
         viewModel: SendViewModel,
         availableBalanceViewModel: SendAvailableBalanceViewModel,
         amountInputViewModel: AmountInputViewModel,
         amountCautionViewModel: SendAmountCautionViewModel,
         recipientViewModel: RecipientAddressViewModel,
         memoViewModel: SendMemoInputViewModel,
         unspentOutputsViewModel: UnspentOutputsViewModel,
         feeViewModel: SendFeeViewModel,
         feeCautionViewModel: ITitledCautionViewModel)
    {
        self.outputSelectorFactory = outputSelectorFactory
        self.feeCautionViewModel = feeCautionViewModel
        feeCell = FeeCell(viewModel: feeViewModel, title: "fee_settings.fee".localized, isFirst: false)
        self.unspentOutputsViewModel = unspentOutputsViewModel
        unspentOutputsCell = UnspentOutputsCell(viewModel: unspentOutputsViewModel, isFirst: true, isLast: false)

        super.init(
            confirmationFactory: confirmationFactory,
            feeSettingsFactory: feeSettingsFactory,
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

        subscribe(disposeBag, feeCautionViewModel.cautionDriver) { [weak self] in
            self?.handle(caution: $0)
        }

        didLoad()
    }

    private func handle(caution: TitledCaution?) {
        feeCautionCell.isVisible = caution != nil

        if let caution {
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
                    cell: unspentOutputsCell,
                    id: "unspent_outputs",
                    height: .heightCell48,
                    autoDeselect: true,
                    action: { [weak self] in
                        guard let view = try? self?.outputSelectorFactory.outputSelectorView() else {
                            return
                        }

                        self?.present(view.toNavigationViewController(), animated: true)
                    }
                ),
                StaticRow(
                    cell: feeCell,
                    id: "fee",
                    height: .heightDoubleLineCell
                ),
            ]
        )
    }

    var feeCautionSection: SectionProtocol {
        Section(
            id: "fee-caution",
            headerState: .margin(height: .margin12),
            rows: [
                StaticRow(
                    cell: feeCautionCell,
                    id: "fee-caution",
                    dynamicHeight: { [weak self] containerWidth in
                        self?.feeCautionCell.cellHeight(containerWidth: containerWidth) ?? 0
                    }
                ),
            ]
        )
    }

    override func buildSections() -> [SectionProtocol] {
        var sections = super.buildSections()
        sections.append(contentsOf: [
            memoSection,
            feeSection,
            feeCautionSection,
            buttonSection,
        ])

        return sections
    }
}
