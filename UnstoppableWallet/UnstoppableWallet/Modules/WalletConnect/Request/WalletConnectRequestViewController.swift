import ThemeKit
import RxSwift
import RxCocoa
import SectionsTableView
import CurrencyKit

class WalletConnectRequestViewController: ThemeActionSheetController {
    private let viewModel: IWalletConnectRequestViewModel
    private let feeViewModel: EthereumFeeViewModel
    private let onApprove: (Data) -> ()
    private let onReject: () -> ()

    private let titleView = BottomSheetTitleView()
    private let amountInfoView = AmountInfoView()
    private let separatorView = UIView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let approveButton = ThemeButton()
    private let rejectButton = ThemeButton()

    private var viewItems = [WalletConnectRequestViewItem]()

    private let disposeBag = DisposeBag()

    init(viewModel: IWalletConnectRequestViewModel, feeViewModel: EthereumFeeViewModel, onApprove: @escaping (Data) -> (), onReject: @escaping () -> ()) {
        self.viewModel = viewModel
        self.feeViewModel = feeViewModel
        self.onApprove = onApprove
        self.onReject = onReject

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(title: "Send Confirm", subtitle: "Uniswap Interface", image: UIImage(named: "Attention Icon")?.tinted(with: .themeGray))

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(amountInfoView)
        amountInfoView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
            maker.height.equalTo(72)
        }

        amountInfoView.bind(primaryAmountInfo: viewModel.amountData.primary, secondaryAmountInfo: viewModel.amountData.secondary)

        view.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(amountInfoView)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separatorView.backgroundColor = .themeSteel20

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(amountInfoView.snp.bottom)
        }

        tableView.registerCell(forClass: TransactionInfoFromToCell.self)
        tableView.registerCell(forClass: TransactionInfoValueCell.self)
        tableView.sectionDataSource = self
        tableView.allowsSelection = false

        view.addSubview(approveButton)
        approveButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        approveButton.apply(style: .primaryYellow)
        approveButton.setTitle("Approve".localized, for: .normal)
        approveButton.addTarget(self, action: #selector(onTapApprove), for: .touchUpInside)

        view.addSubview(rejectButton)
        rejectButton.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(approveButton.snp.bottom).offset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        rejectButton.apply(style: .primaryGray)
        rejectButton.setTitle("Reject".localized, for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)

        viewModel.approveSignal
                .emit(onNext: { [weak self] transactionId in
                    self?.onApprove(transactionId)
                    self?.dismiss(animated: true)
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

    private func fromToRow(title: String, value: String, onTap: @escaping () -> ()) -> RowProtocol {
        Row<TransactionInfoFromToCell>(
                id: title,
                hash: value,
                height: .heightSingleLineCell,
                bind: { cell, _ in
                    cell.bind(title: title, value: value, onTap: onTap)
                }
        )
    }

    private func fromRow(value: String) -> RowProtocol {
        fromToRow(title: "tx_info.from_hash".localized, value: TransactionInfoAddressMapper.map(value)) { [weak self] in
        }
    }

    private func toRow(value: String) -> RowProtocol {
        fromToRow(title: "tx_info.to_hash".localized, value: TransactionInfoAddressMapper.map(value)) { [weak self] in
        }
    }

    private func inputRow(value: String) -> RowProtocol {
        fromToRow(title: "tx_info.input".localized, value: value) { [weak self] in
        }
    }

    private func valueRow(title: String, value: String?) -> RowProtocol {
        Row<TransactionInfoValueCell>(
                id: title,
                hash: value ?? "",
                height: .heightSingleLineCell,
                bind: { cell, _ in
                    cell.bind(title: title, value: value)
                }
        )
    }

    private func feeRow(coinValue: CoinValue, currencyValue: CurrencyValue?) -> RowProtocol {
        var parts = [String]()

        if let formattedCoinValue = ValueFormatter.instance.format(coinValue: coinValue) {
            parts.append(formattedCoinValue)
        }

        if let currencyValue = currencyValue, let formattedCurrencyValue = ValueFormatter.instance.format(currencyValue: currencyValue) {
            parts.append(formattedCurrencyValue)
        }

        return valueRow(
                title: "tx_info.fee".localized,
                value: parts.joined(separator: " | ")
        )
    }

    private func row(viewItem: WalletConnectRequestViewItem) -> RowProtocol {
        switch viewItem {
        case let .from(value): return fromRow(value: value)
        case let .to(value): return toRow(value: value)
        case let .input(value): return inputRow(value: value)
        }
    }

}

extension WalletConnectRequestViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: viewItems.map { viewItem in
                        row(viewItem: viewItem)
                    }
            )
        ]
    }

}
