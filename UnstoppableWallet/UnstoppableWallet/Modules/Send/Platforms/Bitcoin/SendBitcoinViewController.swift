import UIKit
import ThemeKit
import ComponentKit
import SectionsTableView
import RxSwift
import RxCocoa

class SendBitcoinViewController: BaseSendViewController {
    private let disposeBag = DisposeBag()
    private let feeSettingsFactory: ISendFeeSettingsFactory

    private let feeWarningViewModel: ITitledCautionViewModel
    private let timeLockViewModel: SendTimeLockViewModel?

    private let feeCell: EditableFeeCell
    private let feeCautionCell = TitledHighlightedDescriptionCell()

    private var timeLockCell: BaseSelectableThemeCell?

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
        self.timeLockViewModel = timeLockViewModel

        feeCell = EditableFeeCell(viewModel: feeViewModel, isLast: timeLockViewModel == nil)

        if timeLockViewModel != nil {
            let timeLockCell = BaseSelectableThemeCell()

            CellBuilder.build(cell: timeLockCell, elements: [.text, .text, .margin8, .image20])
            timeLockCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)

            timeLockCell.bind(index: 0) { (component: TextComponent) in
                component.font = .subhead2
                component.textColor = .themeGray
                component.text = "send.hodler_locktime".localized
            }
            timeLockCell.bind(index: 2) { (component: ImageComponent) in
                component.imageView.image = UIImage(named: "arrow_small_down_20")?.withTintColor(.themeGray)
            }

            self.timeLockCell = timeLockCell
        }

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

        subscribe(disposeBag, feeWarningViewModel.cautionDriver) { [weak self] in
            self?.handle(caution: $0)
        }

        if let timeLockViewModel = timeLockViewModel {
            subscribe(disposeBag, timeLockViewModel.lockTimeDriver) { [weak self] priority in
                self?.timeLockCell?.bind(index: 1) { (component: TextComponent) in
                    component.font = .subhead1
                    component.textColor = .themeLeah
                    component.text = priority
                }
            }
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

    private func onTapLockTimeSelect() {
        guard let timeLockViewModel = timeLockViewModel else {
            return
        }

        let alertController = AlertRouter.module(
                title: "send.hodler_locktime".localized,
                viewItems: timeLockViewModel.lockTimeViewItems
        ) { index in
            timeLockViewModel.onSelect(index)
        }

        present(alertController, animated: true)
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
                                height: .heightSingleLineCell,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.onTapLockTimeSelect()
                                }
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
