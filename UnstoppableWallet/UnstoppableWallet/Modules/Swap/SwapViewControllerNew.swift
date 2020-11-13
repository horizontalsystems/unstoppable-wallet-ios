import UIKit
import ThemeKit
import UniswapKit
import HUD
import RxSwift
import RxCocoa
import SectionsTableView

class SwapViewControllerNew: ThemeViewController {
    private let animationDuration: TimeInterval = 0.2

    private static let levelColors: [UIColor] = [.themeGray, .themeRemus, .themeJacob, .themeLucian]

    private let disposeBag = DisposeBag()

    private let viewModel: SwapViewModelNew

    private let tableView = SectionsTableView(style: .grouped)

    private let fromCoinCardCell: SwapCoinCardCell
    private let priceCell = SwapPriceCell()
    private let toCoinCardCell: SwapCoinCardCell
//    private let slippageCell = AdditionalDataCellNew()
//    private let deadlineCell = AdditionalDataCellNew()
//    private let recipientCell = AdditionalDataCellNew()
    private let allowanceCell: SwapAllowanceCell
    private let priceImpactCell = AdditionalDataCellNew()
//    private let guaranteedAmountCell = AdditionalDataCellNew()

    private let feeCell: SendFeeCell
    private let feePriorityCell: SendFeePriorityCell

    private let errorCell = SendEthereumErrorCell()
    private let buttonStackCell = StackViewCell()
    private let approveButton = ThemeButton()
    private let proceedButton = ThemeButton()

    private var tradeViewItem: SwapViewModelNew.TradeViewItem?
    private var tradeOptionsViewItem: SwapViewModelNew.TradeOptionsViewItem?

    init(viewModel: SwapViewModelNew, allowanceViewModel: SwapAllowanceViewModelNew, feeViewModel: EthereumFeeViewModel) {
        self.viewModel = viewModel

        fromCoinCardCell = CoinCardModule.fromCell(service: viewModel.service, tradeService: viewModel.tradeService)
        toCoinCardCell = CoinCardModule.toCell(service: viewModel.service, tradeService: viewModel.tradeService)
        allowanceCell = SwapAllowanceCell(viewModel: allowanceViewModel)

        feeCell = SendFeeCell(viewModel: feeViewModel)
        feePriorityCell = SendFeePriorityCell(viewModel: feeViewModel)

        super.init()

        fromCoinCardCell.presentDelegate = self
        toCoinCardCell.presentDelegate = self
        allowanceCell.delegate = self
        feePriorityCell.delegate = self

        priceCell.onSwitch = { [weak self] in
            self?.viewModel.onTapSwitch()
        }

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.title".localized

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Info Icon Medium")?.tinted(with: .themeJacob), style: .plain, target: self, action: #selector(onInfo))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self
        tableView.keyboardDismissMode = .onDrag

        tableView.registerCell(forClass: D1Cell.self)

//        slippageCell.title = "swap.advanced_settings.slippage".localized
//        deadlineCell.title = "swap.advanced_settings.deadline".localized
//        recipientCell.title = "swap.advanced_settings.recipient_address".localized
        allowanceCell.title = "swap.allowance".localized
        priceImpactCell.title = "swap.price_impact".localized

        approveButton.apply(style: .primaryGray)
        approveButton.addTarget(self, action: #selector((onTapApproveButton)), for: .touchUpInside)
        buttonStackCell.add(view: approveButton)

        proceedButton.apply(style: .primaryYellow)
        proceedButton.setTitle("swap.proceed_button".localized, for: .normal)
        proceedButton.addTarget(self, action: #selector((onTapProceedButton)), for: .touchUpInside)
        buttonStackCell.add(view: proceedButton)

        tableView.buildSections()
        tableView.reloadData()

        subscribeToViewModel()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] in self?.handle(loading: $0) }
        subscribe(disposeBag, viewModel.swapErrorDriver) { [weak self] in self?.handle(error: $0) }
        subscribe(disposeBag, viewModel.tradeViewItemDriver) { [weak self] in self?.handle(tradeViewItem: $0) }
        subscribe(disposeBag, viewModel.tradeOptionsViewItemDriver) { [weak self] in self?.handle(tradeOptionsViewItem: $0) }
        subscribe(disposeBag, viewModel.proceedAllowedDriver) { [weak self] in self?.handle(proceedAllowed: $0) }
        subscribe(disposeBag, viewModel.approveActionDriver) { [weak self] in self?.handle(approveActionState: $0) }

        subscribe(disposeBag, viewModel.openApproveSignal) { [weak self] in self?.openApprove(approveData: $0) }
    }

    @objc func onClose() {
        dismiss(animated: true)
    }

    @objc func onInfo() {
        let module = UniswapInfoRouter.module()
        present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    private func handle(loading: Bool) {
        priceCell.set(loading: loading)
    }

    private func handle(error: String?) {
        if let error = error {
            errorCell.isVisible = true
            errorCell.bind(text: error)
        } else {
            errorCell.isVisible = false
        }

        reloadTable()
    }

    private func handle(tradeViewItem: SwapViewModelNew.TradeViewItem?) {
        priceCell.set(price: tradeViewItem?.executionPrice)

        if let tradeViewItem = tradeViewItem {
            priceImpactCell.isVisible = true
            priceImpactCell.value = tradeViewItem.priceImpact
            let index = tradeViewItem.priceImpactLevel.rawValue % SwapViewControllerNew.levelColors.count
            priceImpactCell.valueColor = SwapViewControllerNew.levelColors[index]

//            guaranteedAmountCell.isVisible = true
//            guaranteedAmountCell.title = tradeViewItem.minMaxTitle
//            guaranteedAmountCell.value = tradeViewItem.minMaxAmount
        } else {
            priceImpactCell.isVisible = false
//            guaranteedAmountCell.isVisible = false
        }

        reloadTable()
    }

    private func handle(tradeOptionsViewItem: SwapViewModelNew.TradeOptionsViewItem?) {
//        if let slippage = tradeOptionsViewItem?.slippage {
//            slippageCell.isVisible = true
//            slippageCell.value = slippage
//        } else {
//            slippageCell.isVisible = false
//        }
//
//        if let deadline = tradeOptionsViewItem?.deadline {
//            deadlineCell.isVisible = true
//            deadlineCell.value = deadline
//        } else {
//            deadlineCell.isVisible = false
//        }
//
//        if let recipient = tradeOptionsViewItem?.recipient {
//            recipientCell.isVisible = true
//            recipientCell.value = recipient
//        } else {
//            recipientCell.isVisible = false
//        }
//
//        reloadTable()
    }

    private func handle(proceedAllowed: Bool) {
        proceedButton.isEnabled = proceedAllowed
    }

    private func handle(approveActionState: SwapViewModelNew.ApproveActionState) {
        switch approveActionState {
        case .hidden:
            approveButton.isHidden = true
        case .visible:
            approveButton.isHidden = false
            approveButton.isEnabled = true
            approveButton.setTitle("button.approve".localized, for: .normal)
        case .pending:
            approveButton.isHidden = false
            approveButton.isEnabled = false
            approveButton.setTitle("swap.approving_button".localized, for: .normal)
        }
    }

    @objc private func onTapApproveButton() {
        viewModel.onTapApprove()
    }

    @objc private func onTapProceedButton() {
        let viewController = SwapConfirmationModule.viewController(
                service: viewModel.service,
                tradeService: viewModel.tradeService,
                transactionService: viewModel.transactionService
        )
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc func onTapAdvancedSettings() {
        let viewController = SwapTradeOptionsModule.viewController(tradeService: viewModel.tradeService)
        present(viewController, animated: true)
    }

    private func openApprove(approveData: SwapAllowanceService.ApproveData) {
        guard let viewController = SwapApproveModule.instance(data: approveData, delegate: self) else {
            return
        }

        self.present(viewController, animated: true)
    }

    private func reloadTable() {
        tableView.buildSections()

        UIView.animate(withDuration: animationDuration) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension SwapViewControllerNew: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(
                id: "main",
                rows: [
                    StaticRow(
                            cell: fromCoinCardCell,
                            id: "from-card",
                            height: fromCoinCardCell.cellHeight
                    ),
                    StaticRow(
                            cell: priceCell,
                            id: "price",
                            height: priceCell.cellHeight
                    ),
                    StaticRow(
                            cell: toCoinCardCell,
                            id: "to-card",
                            height: toCoinCardCell.cellHeight
                    )
                ]
        ))

        sections.append(Section(
                id: "info",
                rows: [
//                    StaticRow(
//                            cell: slippageCell,
//                            id: "slippage",
//                            height: slippageCell.cellHeight
//                    ),
//                    StaticRow(
//                            cell: deadlineCell,
//                            id: "deadline",
//                            height: deadlineCell.cellHeight
//                    ),
//                    StaticRow(
//                            cell: recipientCell,
//                            id: "recipient",
//                            height: recipientCell.cellHeight
//                    ),
                    StaticRow(
                            cell: allowanceCell,
                            id: "allowance",
                            height: allowanceCell.cellHeight
                    ),
                    StaticRow(
                            cell: priceImpactCell,
                            id: "price-impact",
                            height: priceImpactCell.cellHeight
                    ),
//                    StaticRow(
//                            cell: guaranteedAmountCell,
//                            id: "guaranteed-amount",
//                            height: guaranteedAmountCell.cellHeight
//                    )
                ]
        ))

        sections.append(Section(
                id: "fee",
                rows: [
                    StaticRow(
                            cell: feeCell,
                            id: "fee",
                            height: 29
                    )
                ]
        ))
        sections.append(Section(
                id: "fee-priority",
                headerState: .margin(height: 6),
                rows: [
                    StaticRow(
                            cell: feePriorityCell,
                            id: "fee-priority",
                            height: feePriorityCell.currentHeight
                    )
                ]
        ))

        sections.append(Section(
                id: "advanced_settings",
                rows: [
                    Row<D1Cell>(
                            id: "advanced",
                            height: .heightSingleLineCell,
                            autoDeselect: true,
                            bind: { cell, _ in
                                cell.set(backgroundStyle: .transparent, topSeparator: true)
                                cell.title  = "swap.advanced_settings".localized
                            },
                            action: { [weak self] _ in
                                self?.onTapAdvancedSettings()
                            }
                    ),
                ]
        ))

        sections.append(Section(id: "error",
                rows: [
                    StaticRow(
                            cell: errorCell,
                            id: "error",
                            dynamicHeight: { [weak self] width in
                                self?.errorCell.cellHeight(width: width) ?? 0
                            }
                    )
                ]
        ))

        sections.append(Section(
                id: "buttons",
                headerState: .margin(height: .margin4x),
                footerState: .margin(height: .margin8x),
                rows: [
                    StaticRow(
                            cell: buttonStackCell,
                            id: "button",
                            height: ThemeButton.height(style: .primaryYellow)
                    )
                ]
        ))

        return sections
    }

}

extension SwapViewControllerNew: IPresentDelegate {

    func show(viewController: UIViewController) {
        present(viewController, animated: true)
    }

}

extension SwapViewControllerNew: ISwapApproveDelegate {

    func didApprove() {
        viewModel.didApprove()
    }

}

extension SwapViewControllerNew: ISendFeePriorityCellDelegate {

    func open(viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func onChangeHeight() {
        reloadTable()
    }

}
