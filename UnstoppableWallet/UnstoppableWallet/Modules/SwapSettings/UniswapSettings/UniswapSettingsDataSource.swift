import ThemeKit
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit

class UniswapSettingsDataSource: ISwapSettingsDataSource {
    private let disposeBag = DisposeBag()

    private let viewModel: UniswapSettingsViewModel
    private let slippageViewModel: SwapSlippageViewModel
    private let deadlineViewModel: SwapDeadlineViewModel

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private let slippageCell = ShortcutInputCell()
    private let slippageCautionCell = FormCautionCell()

    private let deadlineCell = ShortcutInputCell()

    private let buttonCell = ButtonCell(style: .default, reuseIdentifier: nil)

    var onOpen: ((UIViewController) -> ())?
    var onClose: (() -> ())?
    var onReload: (() -> ())?

    init(viewModel: UniswapSettingsViewModel, recipientViewModel: RecipientAddressViewModel, slippageViewModel: SwapSlippageViewModel, deadlineViewModel: SwapDeadlineViewModel) {
        self.viewModel = viewModel
        self.slippageViewModel = slippageViewModel
        self.deadlineViewModel = deadlineViewModel

        recipientCell = RecipientAddressInputCell(viewModel: recipientViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: recipientViewModel)
        viewDidLoad()
    }

    required public init?(coder aDecoder: NSCoder) {
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

        deadlineCell.inputPlaceholder = deadlineViewModel.placeholder
        deadlineCell.inputText = deadlineViewModel.initialValue
        deadlineCell.set(shortcuts: deadlineViewModel.shortcuts)
        deadlineCell.keyboardType = .numberPad
        deadlineCell.isValidText = { [weak self] text in self?.deadlineViewModel.isValid(text: text) ?? true }
        deadlineCell.onChangeHeight = { [weak self] in self?.onReload?() }
        deadlineCell.onChangeText = { [weak self] text in self?.deadlineViewModel.onChange(text: text) }

        buttonCell.bind(style: .primaryYellow, title: "button.apply".localized) { [weak self] in
            self?.didTapApply()
        }

        subscribe(disposeBag, slippageViewModel.cautionDriver) { [weak self] in
            self?.slippageCell.set(cautionType: $0?.type)
            self?.slippageCautionCell.set(caution: $0)
        }

        subscribe(disposeBag, viewModel.actionDriver) { [weak self] actionState in
            switch actionState {
            case .enabled:
                self?.buttonCell.isEnabled = true
                self?.buttonCell.title = "button.apply".localized
            case .disabled(let title):
                self?.buttonCell.isEnabled = false
                self?.buttonCell.title = title
            }
        }
    }

    @objc private func didTapApply() {
        if viewModel.doneDidTap() {
            onClose?()
        } else {
            HudHelper.instance.show(banner: .error(string: "alert.unknown_error".localized))
        }
    }

    private func header(hash: String, text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

    private func footer(hash: String, text: String) -> ViewState<BottomDescriptionHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { width in
                    BottomDescriptionHeaderFooterView.height(containerWidth: width, text: text)
                }
        )
    }

}

extension UniswapSettingsDataSource: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "top-margin",
                    headerState: .margin(height: .margin12)
            ),

            Section(
                    id: "recipient",
                    headerState: header(hash: "recipient_header", text: "swap.advanced_settings.recipient_address".localized),
                    footerState: footer(hash: "recipient_footer", text: "swap.advanced_settings.recipient.footer".localized),
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
                        )
                    ]
            ),

            Section(
                    id: "slippage",
                    headerState: header(hash: "slippage_header", text: "swap.advanced_settings.slippage".localized),
                    footerState: footer(hash: "slippage_footer", text: "swap.advanced_settings.slippage.footer".localized),
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
                        )
                    ]
            ),

            Section(
                    id: "deadline",
                    headerState: header(hash: "deadline_header", text: "swap.advanced_settings.deadline".localized),
                    footerState: footer(hash: "deadline_footer", text: "swap.advanced_settings.deadline.footer".localized),
                    rows: [
                        StaticRow(
                                cell: deadlineCell,
                                id: "deadline",
                                dynamicHeight: { [weak self] width in
                                    self?.deadlineCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),

            Section(
                    id: "button",
                    rows: [
                        StaticRow(
                                cell: buttonCell,
                                id: "button",
                                height: ButtonCell.height(style: .primaryYellow)
                        )
                    ]
            )
        ]
    }

}
