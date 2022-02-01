import UIKit
import ActionSheet
import ThemeKit
import RxSwift
import SectionsTableView
import EthereumKit

class SwapApproveViewController: KeyboardAwareViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: SwapApproveViewModel
    private weak var delegate: ISwapApproveDelegate?
    private let dex: SwapModule.Dex

    private let tableView = SectionsTableView(style: .grouped)

    private let amountCell = InputCell()
    private let amountCautionCell = FormCautionCell()
    private let buttonCell: ButtonCell

    private var isLoaded = false

    init(viewModel: SwapApproveViewModel, delegate: ISwapApproveDelegate, dex: SwapModule.Dex) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.dex = dex

        buttonCell = ButtonCell()

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.approve.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))

        tableView.registerCell(forClass: HighlightedDescriptionCell.self)

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

        buttonCell.bind(style: .primaryYellow, title: "swap.proceed_button".localized, compact: false, onTap: { [weak self] in self?.onTapApprove() })

        subscribeToViewModel()
        tableView.buildSections()

        isLoaded = true
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.approveAllowedDriver) { [weak self] approveAllowed in self?.buttonCell.set(enabled: approveAllowed) }
        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] in self?.openConfirm(transactionData: $0) }

        subscribe(disposeBag, viewModel.amountCautionDriver) { [weak self] caution in
            self?.amountCell.set(cautionType: caution?.type)
            self?.amountCautionCell.set(caution: caution)
        }
    }

    private func onTapApprove() {
        viewModel.proceed()
    }

    @objc private func onTapCancel() {
        view.endEditing(true)
        dismiss(animated: true)
    }

    private func openConfirm(transactionData: TransactionData) {
        let sendEvmData = SendEvmData(transactionData: transactionData, additionalInfo: nil, warnings: [])

        guard let viewController = SwapApproveConfirmationModule.viewController(sendData: sendEvmData, dex: dex, delegate: delegate) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
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
                                    cell.descriptionText = "swap.approve.description".localized
                                }
                        )
                    ]
            ),
            Section(
                    id: "amount",
                    headerState: .margin(height: CGFloat.margin16),
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
                    id: "approve_button",
                    headerState: .margin(height: .margin8),
                    footerState: .margin(height: .margin32),
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
