import UIKit
import ActionSheet
import ThemeKit
import RxSwift
import SectionsTableView

class SwapApproveViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: SwapApproveViewModel
    private let feeViewModel: EthereumFeeViewModel
    private let delegate: ISwapApproveDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private let feeCell: SendFeeCell
    private let feePriorityCell: SendFeePriorityCell
    private let availableBalanceCell: AvailableBalanceCell
    private let amountCell: VerifiedInputCell
    private let buttonCell: ButtonCell

    private var error: String?

    init(viewModel: SwapApproveViewModel, feeViewModel: EthereumFeeViewModel, availableBalanceViewModel: Erc20AvailableBalanceViewModel, delegate: ISwapApproveDelegate) {
        self.viewModel = viewModel
        self.feeViewModel = feeViewModel
        self.delegate = delegate

        feeCell = SendFeeCell(viewModel: feeViewModel)
        feePriorityCell = SendFeePriorityCell(viewModel: feeViewModel)
        availableBalanceCell = AvailableBalanceCell(viewModel: availableBalanceViewModel)
        amountCell = VerifiedInputCell(viewModel: viewModel)
        buttonCell = ButtonCell()

        super.init()

        feePriorityCell.delegate = self
        amountCell.delegate = self
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

        buttonCell.bind(style: .primaryYellow, title: "button.approve".localized, compact: false, onTap: { [weak self] in self?.onTapApprove() })
        tableView.buildSections()

        subscribeToViewModel()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.approveSuccessSignal) { [weak self] in
            HudHelper.instance.showSuccess()
            self?.delegate.didApprove()
            self?.dismiss(animated: true)
        }

        subscribe(disposeBag, viewModel.approveAllowedDriver) { [weak self] approveAllowed in self?.buttonCell.set(enabled: approveAllowed) }
        subscribe(disposeBag, viewModel.errorDriver) { [weak self] errorString in
            guard self?.error != errorString else {
                return
            }

            self?.error = errorString
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.approveErrorSignal) { [weak self] error in self?.show(error: error.convertedError.smartDescription) }
    }

    private func onTapApprove() {
        viewModel.approve()
    }

    @objc private func onTapCancel() {
        view.endEditing(true)
        self.dismiss(animated: true)
    }

}

extension SwapApproveViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: [descriptionRow]
            ),
            Section(
                    id: "amount",
                    headerState: .margin(height: CGFloat.margin4x),
                    rows: [availableBalanceRow, amountRow]
            ),
            Section(
                    id: "fee",
                    headerState: .margin(height: CGFloat.margin4x),
                    rows: feeRows
            ),
            Section(
                    id: "approve_button",
                    rows: [approveButtonRow]
            )
        ]
    }

    private var availableBalanceRow: RowProtocol {
        StaticRow(
                cell: availableBalanceCell,
                id: "amount",
                height: 29
        )
    }

    private var amountRow: RowProtocol {
        StaticRow(
                cell: amountCell,
                id: "amount",
                dynamicHeight: { [weak self] width in
                    self?.amountCell.height(containerWidth: width) ?? 0
                }
        )
    }

    private var feeRows: [RowProtocol] {
        var rows = [RowProtocol]()

        rows.append(contentsOf: [
            StaticRow(
                    cell: feeCell,
                    id: "fee",
                    height: 29
            ),
            StaticRow(
                    cell: feePriorityCell,
                    id: "fee-priority",
                    dynamicHeight: { [weak self] _ in self?.feePriorityCell.currentHeight ?? 0 }
            )
        ])


        if let error = error {
            rows.append(errorRow(text: error))
        }

        return rows
    }

    private var descriptionRow: RowProtocol {
        Row<HighlightedDescriptionCell>(
                id: "description",
                dynamicHeight: { width in
                    HighlightedDescriptionCell.height(containerWidth: width, text: "swap.approve.description".localized)
                },
                bind: { cell, _ in
                    cell.bind(text: "swap.approve.description".localized)
                }
        )
    }

    private func errorRow(text: String) -> RowProtocol {
        Row<SendEthereumErrorCell>(
                id: "error_row",
                hash: text,
                dynamicHeight: { width in
                    SendEthereumErrorCell.height(text: text, containerWidth: width)
                },
                bind: { cell, _ in
                    cell.bind(text: text)
                }
        )
    }

    private var approveButtonRow: RowProtocol {
        StaticRow(
                cell: buttonCell,
                id: "approve-button",
                height: ButtonCell.height(style: .primaryYellow)
        )
    }

}

extension SwapApproveViewController: IDynamicHeightCellDelegate {

    func onChangeHeight() {
        UIView.performWithoutAnimation { [weak self] in
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
