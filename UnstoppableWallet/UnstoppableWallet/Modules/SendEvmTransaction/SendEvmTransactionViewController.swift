import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa

class SendEvmTransactionViewController: ThemeViewController {
    let disposeBag = DisposeBag()

    let transactionViewModel: SendEvmTransactionViewModel

    private let tableView = SectionsTableView(style: .grouped)
    let bottomWrapper = BottomGradientHolder()

    private let estimatedFeeCell: SendEstimatedFeeCell
    private let maxFeeCell: SendMaxFeeCell
    private let feePriorityCell: SendFeePriorityCell
    private let errorCell = SendEthereumErrorCell()

    private let viewItems: [SendEvmTransactionViewModel.ViewItem]
    private var isLoaded = false

    init(transactionViewModel: SendEvmTransactionViewModel, feeViewModel: EthereumFeeViewModel) {
        self.transactionViewModel = transactionViewModel

        estimatedFeeCell = SendEstimatedFeeCell(viewModel: feeViewModel)
        maxFeeCell = SendMaxFeeCell(viewModel: feeViewModel)
        feePriorityCell = SendFeePriorityCell(viewModel: feeViewModel)

        viewItems = transactionViewModel.viewItems

        super.init()

        feePriorityCell.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        tableView.allowsSelection = false

        tableView.registerCell(forClass: SendConfirmationAmountCell.self)
        tableView.registerCell(forClass: D9Cell.self)
        tableView.registerCell(forClass: AdditionalDataCell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        view.addSubview(bottomWrapper)
        bottomWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        subscribe(disposeBag, transactionViewModel.errorDriver) { [weak self] in self?.handle(error: $0) }
        subscribe(disposeBag, transactionViewModel.sendingSignal) { HudHelper.instance.showSpinner() }
        subscribe(disposeBag, transactionViewModel.sendSuccessSignal) { [weak self] in self?.handleSendSuccess(transactionHash: $0) }
        subscribe(disposeBag, transactionViewModel.sendFailedSignal) { [weak self] in self?.handleSendFailed(error: $0) }

        isLoaded = true
    }

    private func handle(error: String?) {
        errorCell.bind(text: error)
        reloadTable()
    }

    func handleSendSuccess(transactionHash: Data) {
        HudHelper.instance.showSuccess()

        dismiss(animated: true)
    }

    private func handleSendFailed(error: String) {
        HudHelper.instance.showError(title: error)
    }

    private func reloadTable() {
        tableView.buildSections()

        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

    private func row(title: String, value: String) -> RowProtocol {
        Row<AdditionalDataCell>(
                id: title,
                height: AdditionalDataCell.height,
                bind: { cell, _ in
                    cell.bind(title: title, value: value)
                }
        )
    }

    private func amountRow(amountData: AmountData, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<SendConfirmationAmountCell>(
                id: "amount-\(index)",
                height: SendConfirmationAmountCell.height,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.bind(primaryAmountInfo: amountData.primary, secondaryAmountInfo: amountData.secondary)
                }
        )
    }

    private func hexRow(title: String, value: String, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        Row<D9Cell>(
                id: "address-\(index)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                    cell.title = title
                    cell.viewItem = .init(title: TransactionInfoAddressMapper.title(value: value), value: value)
                }
        )
    }

    private func row(viewItem: SendEvmTransactionViewModel.ViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        switch viewItem {
        case .amount(let amountData): return amountRow(amountData: amountData, index: index, isFirst: isFirst, isLast: isLast)
        case let .address(title, value): return hexRow(title: title, value: value, index: index, isFirst: isFirst, isLast: isLast)
        case .input(let value): return hexRow(title: "Input", value: value, index: index, isFirst: isFirst, isLast: isLast)
        }
    }

}

extension SendEvmTransactionViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "transaction",
                    headerState: .margin(height: .margin16),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == viewItems.count - 1)
                    }
            ),
            Section(
                    id: "fee",
                    headerState: header(text: "Network Fee".uppercased()),
                    rows: [
                        StaticRow(
                                cell: estimatedFeeCell,
                                id: "estimated-fee",
                                height: estimatedFeeCell.cellHeight
                        ),
                        StaticRow(
                                cell: maxFeeCell,
                                id: "fee",
                                height: maxFeeCell.cellHeight
                        )
                    ]
            ),
            Section(
                    id: "fee-priority",
                    headerState: .margin(height: 6),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: feePriorityCell,
                                id: "fee-priority",
                                height: feePriorityCell.cellHeight
                        ),
                        StaticRow(
                                cell: errorCell,
                                id: "error",
                                dynamicHeight: { [weak self] width in
                                    self?.errorCell.cellHeight(width: width) ?? 0
                                }
                        )
                    ]
            )
        ]
    }

}

extension SendEvmTransactionViewController: ISendFeePriorityCellDelegate {

    func open(viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func onChangeHeight() {
        reloadTable()
    }

}
