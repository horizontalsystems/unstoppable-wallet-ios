import ThemeKit
import RxSwift
import RxCocoa
import SectionsTableView
import CurrencyKit
import HUD

class WalletConnectRequestViewController: ThemeViewController {
    private let viewModel: WalletConnectSendEthereumTransactionRequestViewModel
    private let onApprove: (Data) -> ()
    private let onReject: () -> ()

    private let tableView = SectionsTableView(style: .grouped)
    private let estimatedFeeCell: SendEstimatedFeeCell
    private let maxFeeCell: SendMaxFeeCell
    private let feePriorityCell: SendFeePriorityCell

    private let buttonsHolder = BottomGradientHolder()
    private let approveButton = ThemeButton()
    private let rejectButton = ThemeButton()

    private var viewItems = [WalletConnectRequestViewItem]()
    private var error: String?

    private let disposeBag = DisposeBag()

    init(viewModel: WalletConnectSendEthereumTransactionRequestViewModel, feeViewModel: EthereumFeeViewModel, onApprove: @escaping (Data) -> (), onReject: @escaping () -> ()) {
        self.viewModel = viewModel
        self.onApprove = onApprove
        self.onReject = onReject

        estimatedFeeCell = SendEstimatedFeeCell(viewModel: feeViewModel)
        maxFeeCell = SendMaxFeeCell(viewModel: feeViewModel)
        feePriorityCell = SendFeePriorityCell(viewModel: feeViewModel)

        super.init()

        feePriorityCell.delegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.request_title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: SendConfirmationAmountCell.self)

        tableView.registerCell(forClass: D9Cell.self)
        tableView.registerCell(forClass: SendEthereumErrorCell.self)
        tableView.sectionDataSource = self
        tableView.allowsSelection = false

        view.addSubview(buttonsHolder)
        buttonsHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin4x)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        buttonsHolder.addSubview(rejectButton)
        rejectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().offset(-CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        rejectButton.apply(style: .primaryGray)
        rejectButton.setTitle("button.reject".localized, for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)

        buttonsHolder.addSubview(approveButton)
        approveButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin8x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(rejectButton.snp.top).offset(-CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        approveButton.apply(style: .primaryYellow)
        approveButton.setTitle("button.approve".localized, for: .normal)
        approveButton.addTarget(self, action: #selector(onTapApprove), for: .touchUpInside)

        viewModel.approveEnabledDriver
                .drive(onNext: { [weak self] enabled in
                    self?.approveButton.isEnabled = enabled
                })
                .disposed(by: disposeBag)

        viewModel.rejectEnabledDriver
                .drive(onNext: { [weak self] enabled in
                    self?.rejectButton.isEnabled = enabled
                })
                .disposed(by: disposeBag)

        viewModel.errorDriver
                .drive(onNext: { [weak self] error in
                    self?.error = error
                    self?.tableView.reload()
                })
                .disposed(by: disposeBag)

        viewModel.sendingDriver
                .drive(onNext: { sending in
                    if sending {
                        HudHelper.instance.showSpinner(userInteractionEnabled: false)
                    }
                })
                .disposed(by: disposeBag)

        viewModel.approveSignal
                .emit(onNext: { [weak self] transactionId in
                    self?.onApprove(transactionId)
                    self?.dismiss(animated: true)
                    HudHelper.instance.showSuccess()
                })
                .disposed(by: disposeBag)

        viewItems = viewModel.viewItems
        tableView.buildSections()
    }

    @objc private func onTapApprove() {
        viewModel.approve()
    }

    @objc private func onTapReject() {
        onReject()
        dismiss(animated: true)
    }

}

extension WalletConnectRequestViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var feeRows = [RowProtocol]()

        feeRows.append(
                StaticRow(
                        cell: feePriorityCell,
                        id: "fee-priority",
                        height: feePriorityCell.cellHeight
                )
        )

        if let error = error {
            feeRows.append(errorRow(text: error))
        }

        return [
            Section(
                    id: "main",
                    footerState: .margin(height: 6),
                    rows: [amountRow(isLast: viewItems.isEmpty)] + viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, isLast: index == viewItems.count - 1)
                    }
            ),
            Section(id: "fee",
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
                    rows: feeRows
            )
        ]
    }

    private func amountRow(isLast: Bool) -> RowProtocol {
        let amountViewItem = viewModel.amountData

        return Row<SendConfirmationAmountCell>(
                id: "amount",
                hash: amountViewItem.primary.formattedString,
                height: SendConfirmationAmountCell.height,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: isLast)
                    cell.bind(primaryAmountInfo: amountViewItem.primary, secondaryAmountInfo: amountViewItem.secondary)
                }
        )
    }

    private func buttonRow(title: String, viewItem: CopyableSecondaryButton.ViewItem, isLast: Bool) -> RowProtocol {
        Row<D9Cell>(
                id: title,
                hash: viewItem.value,
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isLast: isLast)
                    cell.title = title
                    cell.viewItem = viewItem
                }
        )
    }

    private func row(viewItem: WalletConnectRequestViewItem, isLast: Bool) -> RowProtocol {
        switch viewItem {
        case let .from(value):
            return buttonRow(title: "tx_info.from_hash".localized, viewItem: .init(title: TransactionInfoAddressMapper.title(value: value), value: value), isLast: isLast)
        case let .to(value):
            return buttonRow(title: "tx_info.to_hash".localized, viewItem: .init(title: TransactionInfoAddressMapper.title(value: value), value: value), isLast: isLast)
        case let .input(value):
            return buttonRow(title: "tx_info.input".localized, viewItem: .init(value: value), isLast: isLast)
        }
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

}

extension WalletConnectRequestViewController: ISendFeePriorityCellDelegate {

    func open(viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func onChangeHeight() {
        tableView.reload()
    }

}
