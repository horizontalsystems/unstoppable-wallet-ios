import UIKit
import ActionSheet
import ThemeKit
import RxSwift
import SectionsTableView

class SwapApproveViewController: KeyboardAwareViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: SwapApproveViewModel
    private let feeViewModel: EthereumFeeViewModel
    private let delegate: ISwapApproveDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private let amountCell = InputCell()
    private let amountCautionCell = FormCautionCell()
    private let feeCell: SendFeeCell
    private let feePriorityCell: SendFeePriorityCell
    private let errorCell = SendEthereumErrorCell()
    private let buttonCell: ButtonCell

    private var isLoaded = false

    init(viewModel: SwapApproveViewModel, feeViewModel: EthereumFeeViewModel, delegate: ISwapApproveDelegate) {
        self.viewModel = viewModel
        self.feeViewModel = feeViewModel
        self.delegate = delegate

        feeCell = SendFeeCell(viewModel: feeViewModel)
        feePriorityCell = SendFeePriorityCell(viewModel: feeViewModel)
        buttonCell = ButtonCell()

        super.init(scrollView: tableView)

        feePriorityCell.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.approve.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))

        tableView.registerCell(forClass: HighlightedDescriptionCell.self)
        tableView.registerCell(forClass: SendEthereumErrorCell.self)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .interactive

        amountCell.inputText = viewModel.initialAmount
        amountCell.inputPlaceholder = "send.amount_placeholder".localized
        amountCell.keyboardType = .decimalPad
        amountCell.isValidText = { [weak self] in self?.viewModel.isValid(amount: $0) ?? true }
        amountCell.onChangeText = { [weak self] in self?.viewModel.onChange(amount: $0) }

        amountCautionCell.onChangeHeight = { [weak self] in self?.onChangeHeight() }

        buttonCell.bind(style: .primaryYellow, title: "button.approve".localized, compact: false, onTap: { [weak self] in self?.onTapApprove() })

        subscribeToViewModel()
        tableView.buildSections()

        isLoaded = true
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.approveSuccessSignal) { [weak self] in
            HudHelper.instance.showSuccess()
            self?.delegate.didApprove()
            self?.dismiss(animated: true)
        }

        subscribe(disposeBag, viewModel.approveAllowedDriver) { [weak self] approveAllowed in self?.buttonCell.set(enabled: approveAllowed) }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] error in
            if let error = error {
                self?.errorCell.isVisible = true
                self?.errorCell.bind(text: error)
            } else {
                self?.errorCell.isVisible = false
            }

            self?.onChangeHeight()
        }
        subscribe(disposeBag, viewModel.approveErrorSignal) { [weak self] error in self?.show(error: error) }

        subscribe(disposeBag, viewModel.amountCautionDriver) { [weak self] caution in
            self?.amountCell.set(cautionType: caution?.type)
            self?.amountCautionCell.set(caution: caution)
        }
    }

    private func onTapApprove() {
        viewModel.approve()
    }

    @objc private func onTapCancel() {
        view.endEditing(true)
        dismiss(animated: true)
    }

}

extension SwapApproveViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: [
                        Row<HighlightedDescriptionCell>(
                                id: "description",
                                dynamicHeight: { width in
                                    HighlightedDescriptionCell.height(containerWidth: width, text: "swap.approve.description".localized)
                                },
                                bind: { cell, _ in
                                    cell.bind(text: "swap.approve.description".localized)
                                }
                        )
                    ]
            ),
            Section(
                    id: "amount",
                    headerState: .margin(height: CGFloat.margin4x),
                    rows: [
                        StaticRow(
                                cell: amountCell,
                                id: "amount",
                                dynamicHeight: { [weak self] width in
                                    self?.amountCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: amountCautionCell,
                                id: "amount-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.amountCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),
            Section(
                    id: "fee",
                    headerState: .margin(height: CGFloat.margin4x),
                    rows: [
                        StaticRow(
                                cell: feeCell,
                                id: "fee",
                                height: feeCell.cellHeight
                        ),
                        StaticRow(
                                cell: feePriorityCell,
                                id: "fee-priority",
                                dynamicHeight: { [weak self] _ in
                                    self?.feePriorityCell.cellHeight ?? 0
                                }
                        )
                    ]
            ),
            Section(
                    id: "error",
                    rows: [
                        StaticRow(
                                cell: errorCell,
                                id: "error",
                                dynamicHeight: { [weak self] width in
                                    self?.errorCell.cellHeight(width: width) ?? 0
                                }
                        )
                    ]
            ),
            Section(
                    id: "approve_button",
                    rows: [
                        StaticRow(
                                cell: buttonCell,
                                id: "approve-button",
                                height: ButtonCell.height(style: .primaryYellow)
                        )
                    ]
            )
        ]
    }

}

extension SwapApproveViewController: IDynamicHeightCellDelegate {

    func onChangeHeight() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
    }

}

extension SwapApproveViewController {

    private func show(error: String) {
        HudHelper.instance.showError(title: error)
    }

}

extension SwapApproveViewController: ISendFeePriorityCellDelegate {

    func open(viewController: UIViewController) {
        present(viewController, animated: true)
    }

}
