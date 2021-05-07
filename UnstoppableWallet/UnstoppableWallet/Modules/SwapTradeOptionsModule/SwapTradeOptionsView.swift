import ThemeKit
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit

class SwapTradeOptionsView: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: SwapTradeOptionsViewModel
    private let slippageViewModel: SwapSlippageViewModel
    private let deadlineViewModel: SwapDeadlineViewModel

    private let tableView = SectionsTableView(style: .grouped)

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private let slippageCell = ShortcutInputCell()
    private let slippageCautionCell = FormCautionCell()

    private let deadlineCell = ShortcutInputCell()

    private let buttonCell = ButtonCell(style: .default, reuseIdentifier: nil)

    init(viewModel: SwapTradeOptionsViewModel, recipientViewModel: RecipientAddressViewModel, slippageViewModel: SwapSlippageViewModel, deadlineViewModel: SwapDeadlineViewModel) {
        self.viewModel = viewModel
        self.slippageViewModel = slippageViewModel
        self.deadlineViewModel = deadlineViewModel

        recipientCell = RecipientAddressInputCell(viewModel: recipientViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: recipientViewModel)

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.advanced_settings".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionDataSource = self

        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        recipientCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        recipientCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        recipientCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        slippageCell.inputPlaceholder = slippageViewModel.placeholder
        slippageCell.inputText = slippageViewModel.initialValue
        slippageCell.set(shortcuts: slippageViewModel.shortcuts)
        slippageCell.keyboardType = .decimalPad
        slippageCell.isValidText = { [weak self] text in self?.slippageViewModel.isValid(text: text) ?? true }
        slippageCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        slippageCell.onChangeText = { [weak self] text in self?.slippageViewModel.onChange(text: text) }

        slippageCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        deadlineCell.inputPlaceholder = deadlineViewModel.placeholder
        deadlineCell.inputText = deadlineViewModel.initialValue
        deadlineCell.set(shortcuts: deadlineViewModel.shortcuts)
        deadlineCell.keyboardType = .numberPad
        deadlineCell.isValidText = { [weak self] text in self?.deadlineViewModel.isValid(text: text) ?? true }
        deadlineCell.onChangeHeight = { [weak self] in self?.reloadTable() }
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

        tableView.buildSections()
    }

    @objc private func didTapApply() {
        if viewModel.doneDidTap() {
            dismiss(animated: true)
        } else {
            HudHelper.instance.showError(title: "alert.unknown_error".localized)
        }
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
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

    private func reloadTable() {
        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension SwapTradeOptionsView: SectionsDataSource {

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
