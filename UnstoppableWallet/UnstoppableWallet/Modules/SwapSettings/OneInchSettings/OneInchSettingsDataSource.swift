import ComponentKit
import RxCocoa
import RxSwift
import SectionsTableView
import ThemeKit
import UIKit

class OneInchSettingsDataSource: ISwapSettingsDataSource {
    private let disposeBag = DisposeBag()

    private let viewModel: OneInchSettingsViewModel
    private let slippageViewModel: SwapSlippageViewModel

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private let slippageCell = ShortcutInputCell()
    private let slippageCautionCell = FormCautionCell()

    private let serviceFeeNoteCell = HighlightedDescriptionCell(showVerticalMargin: false)

    var onOpen: ((UIViewController) -> Void)?
    var onClose: (() -> Void)?
    var onReload: (() -> Void)?
    var onChangeButtonState: ((Bool, String) -> Void)?

    init(viewModel: OneInchSettingsViewModel, recipientViewModel: RecipientAddressViewModel, slippageViewModel: SwapSlippageViewModel) {
        self.viewModel = viewModel
        self.slippageViewModel = slippageViewModel

        recipientCell = RecipientAddressInputCell(viewModel: recipientViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: recipientViewModel)
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func viewDidLoad() {
        recipientCell.onChangeHeight = { [weak self] in self?.onReload?() }
        recipientCell.onOpenViewController = { [weak self] in self?.onOpen?($0) }

        recipientCautionCell.onChangeHeight = { [weak self] in self?.onReload?() }

        slippageCell.inputPlaceholder = slippageViewModel.placeholder
        slippageCell.inputText = slippageViewModel.initialValue
        slippageCell.set(shortcuts: slippageViewModel.shortcuts)
        slippageCell.keyboardType = .decimalPad
        slippageCell.isValidText = { [weak self] text in self?.slippageViewModel.isValid(text: text) ?? true }
        slippageCell.onChangeHeight = { [weak self] in self?.onReload?() }
        slippageCell.onChangeText = { [weak self] text in self?.slippageViewModel.onChange(text: text) }

        slippageCautionCell.onChangeHeight = { [weak self] in self?.onReload?() }

        serviceFeeNoteCell.descriptionText = "swap.advanced_settings.service_fee_description".localized

        subscribe(disposeBag, slippageViewModel.cautionDriver) { [weak self] in
            self?.slippageCell.set(cautionType: $0?.type)
            self?.slippageCautionCell.set(caution: $0)
        }

        subscribe(disposeBag, viewModel.actionDriver) { [weak self] actionState in
            switch actionState {
            case .enabled:
                self?.onChangeButtonState?(true, "button.apply".localized)
            case let .disabled(title):
                self?.onChangeButtonState?(false, title)
            }
        }
    }

    @objc func didTapApply() {
        if viewModel.doneDidTap() {
            onClose?()
        } else {
            HudHelper.instance.show(banner: .error(string: "alert.unknown_error".localized))
        }
    }
}

extension OneInchSettingsDataSource {
    func buildSections(tableView: SectionsTableView) -> [SectionProtocol] {
        [
            Section(
                id: "top-margin",
                headerState: .margin(height: .margin12)
            ),

            Section(
                id: "recipient",
                headerState: tableView.sectionHeader(text: "swap.advanced_settings.recipient_address".localized),
                footerState: tableView.sectionFooter(text: "swap.advanced_settings.recipient.footer".localized),
                rows: [
                    StaticRow(
                        cell: recipientCell,
                        id: "recipient-input",
                        dynamicHeight: { [weak self] width in
                            self?.recipientCell.height(containerWidth: width) ?? 0
                        }
                    ),
                    StaticRow(
                        cell: recipientCautionCell,
                        id: "recipient-caution",
                        dynamicHeight: { [weak self] width in
                            self?.recipientCautionCell.height(containerWidth: width) ?? 0
                        }
                    ),
                ]
            ),

            Section(
                id: "slippage",
                headerState: tableView.sectionHeader(text: "swap.advanced_settings.slippage".localized),
                footerState: tableView.sectionFooter(text: "swap.advanced_settings.slippage.footer".localized),
                rows: [
                    StaticRow(
                        cell: slippageCell,
                        id: "slippage",
                        dynamicHeight: { [weak self] width in
                            self?.slippageCell.height(containerWidth: width) ?? 0
                        }
                    ),
                    StaticRow(
                        cell: slippageCautionCell,
                        id: "slippage-caution",
                        dynamicHeight: { [weak self] width in
                            self?.slippageCautionCell.height(containerWidth: width) ?? 0
                        }
                    ),
                ]
            ),

            Section(
                id: "service-fee",
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                        cell: serviceFeeNoteCell,
                        id: "service-fee-cell",
                        dynamicHeight: { [weak self] width in
                            self?.serviceFeeNoteCell.height(containerWidth: width) ?? 0
                        }
                    ),
                ]
            ),
        ]
    }
}
