import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa

class SendBitcoinViewController: BaseSendViewController {
    private let disposeBag = DisposeBag()
    private let feeSettingsFactory: ISendFeeSettingsFactory

    private let feeWarningViewModel: ITitledCautionViewModel

    private let feeCell: EditableFeeCell
    private let feeCautionCell = TitledHighlightedDescriptionCell()

    private let timeLockCell: SendTimeLockCell?

    init(confirmationFactory: ISendConfirmationFactory,
         feeSettingsFactory: ISendFeeSettingsFactory,
         viewModel: SendViewModel,
         availableBalanceViewModel: SendAvailableBalanceViewModel,
         amountInputViewModel: AmountInputViewModel,
         amountCautionViewModel: SendAmountCautionViewModel,
         recipientViewModel: RecipientAddressViewModel,
         feeViewModel: SendFeeViewModel,
         feeWarningViewModel: ITitledCautionViewModel,
         timeLockViewModel: SendTimeLockViewModel?
    ) {

        self.feeSettingsFactory = feeSettingsFactory
        self.feeWarningViewModel = feeWarningViewModel

        feeCell = EditableFeeCell(viewModel: feeViewModel, isLast: timeLockViewModel == nil)

        timeLockCell = timeLockViewModel.map {
            SendTimeLockCell(viewModel: $0)
        }

        super.init(
                confirmationFactory: confirmationFactory,
                viewModel: viewModel,
                availableBalanceViewModel: availableBalanceViewModel,
                amountInputViewModel: amountInputViewModel,
                amountCautionViewModel: amountCautionViewModel,
                recipientViewModel: recipientViewModel
        )

        timeLockCell?.sourceViewController = self
        timeLockCell?.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

    private func openFeeSettings() {
        guard let viewController = try? feeSettingsFactory.feeSettingsViewController() else {
            return
        }

        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    var feeSection: SectionProtocol {
        Section(
                id: "fee",
                headerState: .margin(height: .margin12),
                rows: [
                    StaticRow(
                            cell: feeCell,
                            id: "fee",
                            height: .heightCell48,
                            autoDeselect: true,
                            action: { [weak self] in
                                self?.openFeeSettings()
                            }
                    )
                ]
        )
    }

    var timeLockSection: SectionProtocol? {
        timeLockCell.map { cell in
            Section(
                    id: "time-lock",
                    rows: [
                        StaticRow(
                                cell: cell,
                                id: "time_lock_cell",
                                height: .heightSingleLineCell
                        )
                    ]
            )
        }
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
        if let timeLockSection = timeLockSection {
            sections.append(timeLockSection)
        }
        sections.append(contentsOf: [feeWarningSection, buttonSection])

        return sections
    }

}
