import UIKit
import ThemeKit
import UniswapKit
import HUD
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit

class UniswapDataSource {
    private static let levelColors: [UIColor] = [.themeRemus, .themeJacob, .themeLucian]

    private let disposeBag = DisposeBag()

    private let viewModel: UniswapViewModel

    private let settingsHeaderView = TextDropDownAndSettingsView()

    private let fromCoinCardCell: SwapCoinCardCell
    private let switchCell = SwapSwitchCell()
    private let toCoinCardCell: SwapCoinCardCell
//    private let slippageCell = AdditionalDataCellNew()
//    private let deadlineCell = AdditionalDataCellNew()
//    private let recipientCell = AdditionalDataCellNew()
    private let buyPriceCell = AdditionalDataCellNew()
    private let sellPriceCell = AdditionalDataCellNew()
    private let allowanceCell: SwapAllowanceCell
    private let priceImpactCell = AdditionalDataCellNew()
    private let guaranteedAmountCell = AdditionalDataCellNew()

    private let warningCell = HighlightedDescriptionCell(showVerticalMargin: false)
    private let errorCell = SendEthereumErrorCell()
    private let buttonStackCell = StackViewCell()
    private let revokeButton = PrimaryButton()
    private let approveButton = PrimaryButton()
    private let proceedButton = PrimaryButton()
    private let approveStepCell = SwapStepCell()

    var onOpen: ((_ viewController: UIViewController, _ viaPush: Bool) -> ())? = nil
    var onOpenSelectProvider: (() -> ())? = nil
    var onOpenSettings: (() -> ())? = nil
    var onClose: (() -> ())? = nil
    var onReload: (() -> ())? = nil

    init(viewModel: UniswapViewModel, allowanceViewModel: SwapAllowanceViewModel) {
        self.viewModel = viewModel

        fromCoinCardCell = CoinCardModule.fromCell(service: viewModel.service, tradeService: viewModel.tradeService, switchService: viewModel.switchService)
        toCoinCardCell = CoinCardModule.toCell(service: viewModel.service, tradeService: viewModel.tradeService, switchService: viewModel.switchService)
        allowanceCell = SwapAllowanceCell(viewModel: allowanceViewModel)

        fromCoinCardCell.presentDelegate = self
        toCoinCardCell.presentDelegate = self
        allowanceCell.delegate = self

        switchCell.onSwitch = { [weak self] in
            self?.viewModel.onTapSwitch()
        }

        settingsHeaderView.bind(dropdownTitle: viewModel.dexName)
        settingsHeaderView.onTapDropDown = { [weak self] in self?.onOpenSelectProvider?() }
        settingsHeaderView.onTapSettings = { [weak self] in self?.onOpenSettings?() }

        initCells()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initCells() {
//        slippageCell.title = "swap.advanced_settings.slippage".localized
//        deadlineCell.title = "swap.advanced_settings.deadline".localized
//        recipientCell.title = "swap.advanced_settings.recipient_address".localized

        buyPriceCell.title = "swap.buy_price".localized
        buyPriceCell.isVisible = false
        sellPriceCell.title = "swap.sell_price".localized
        sellPriceCell.isVisible = false
        allowanceCell.title = "swap.allowance".localized
        priceImpactCell.title = "swap.price_impact".localized

        revokeButton.set(style: .yellow)
        revokeButton.addTarget(self, action: #selector((onTapRevokeButton)), for: .touchUpInside)
        buttonStackCell.add(view: revokeButton)

        approveButton.set(style: .gray)
        approveButton.addTarget(self, action: #selector((onTapApproveButton)), for: .touchUpInside)
        buttonStackCell.add(view: approveButton)

        proceedButton.set(style: .yellow)
        proceedButton.addTarget(self, action: #selector((onTapProceedButton)), for: .touchUpInside)
        buttonStackCell.add(view: proceedButton)

        subscribeToViewModel()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] in self?.handle(loading: $0) }
        subscribe(disposeBag, viewModel.swapErrorDriver) { [weak self] in self?.handle(error: $0) }
        subscribe(disposeBag, viewModel.tradeViewItemDriver) { [weak self] in self?.handle(tradeViewItem: $0) }
        subscribe(disposeBag, viewModel.settingsViewItemDriver) { [weak self] in self?.handle(settingsViewItem: $0) }
        subscribe(disposeBag, viewModel.proceedActionDriver) { [weak self] in self?.handle(proceedActionState: $0) }
        subscribe(disposeBag, viewModel.revokeWarningDriver) { [weak self] in self?.handle(revokeWarning: $0) }
        subscribe(disposeBag, viewModel.revokeActionDriver) { [weak self] in self?.handle(revokeActionState: $0) }
        subscribe(disposeBag, viewModel.approveActionDriver) { [weak self] in self?.handle(approveActionState: $0) }
        subscribe(disposeBag, viewModel.approveStepDriver) { [weak self] in self?.handle(approveStepState: $0) }

        subscribe(disposeBag, viewModel.openRevokeSignal) { [weak self] in self?.openRevoke(approveData: $0) }
        subscribe(disposeBag, viewModel.openApproveSignal) { [weak self] in self?.openApprove(approveData: $0) }
        subscribe(disposeBag, viewModel.openConfirmSignal) { [weak self] in self?.openConfirm(sendData: $0) }
    }

    private func handle(loading: Bool) {
        switchCell.set(loading: loading)
    }

    private func handle(revokeWarning: String?) {
        warningCell.descriptionText = revokeWarning

        onReload?()
    }

    private func handle(revokeActionState: UniswapViewModel.ActionState) {
        handle(actionState: revokeActionState, button: revokeButton)
    }

    private func handle(error: String?) {
        if let error = error {
            errorCell.isVisible = true
            errorCell.bind(text: error)
        } else {
            errorCell.isVisible = false
        }

        onReload?()
    }

    private func handle(tradeViewItem: UniswapViewModel.TradeViewItem?) {
        if let viewItem = tradeViewItem?.executionPrice {
            buyPriceCell.isVisible = true
            buyPriceCell.value = viewItem
        } else {
            buyPriceCell.isVisible = false
        }
        if let viewItem = tradeViewItem?.executionPriceInverted {
            sellPriceCell.isVisible = true
            sellPriceCell.value = viewItem
        } else {
            sellPriceCell.isVisible = false
        }

        if let viewItem = tradeViewItem?.priceImpact {
            priceImpactCell.isVisible = true
            priceImpactCell.value = viewItem.value
            let index = viewItem.level.rawValue % UniswapDataSource.levelColors.count
            priceImpactCell.valueColor = UniswapDataSource.levelColors[index]
        } else {
            priceImpactCell.isVisible = false
        }

        if let viewItem = tradeViewItem?.guaranteedAmount {
            guaranteedAmountCell.isVisible = true
            guaranteedAmountCell.title = viewItem.title
            guaranteedAmountCell.value = viewItem.value
        } else {
            guaranteedAmountCell.isVisible = false
        }

        onReload?()
    }

    private func handle(settingsViewItem: UniswapViewModel.SettingsViewItem?) {
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

    private func handle(proceedActionState: UniswapViewModel.ActionState) {
        handle(actionState: proceedActionState, button: proceedButton)
    }

    private func handle(approveActionState: UniswapViewModel.ActionState) {
        handle(actionState: approveActionState, button: approveButton)
    }

    private func handle(actionState: UniswapViewModel.ActionState, button: PrimaryButton) {
        switch actionState {
        case .hidden:
            button.isHidden = true
        case .enabled(let title):
            button.isHidden = false
            button.isEnabled = true
            button.setTitle(title, for: .normal)
        case .disabled(let title):
            button.isHidden = false
            button.isEnabled = false
            button.setTitle(title, for: .normal)
        }
    }

    private func handle(approveStepState: SwapModule.ApproveStepState) {
        switch approveStepState {
        case .approveRequired, .approving:
            approveStepCell.isVisible = true
            approveStepCell.set(first: true)
        case .approved:
            approveStepCell.isVisible = true
            approveStepCell.set(first: false)
        case .notApproved, .revokeRequired, .revoking:
            approveStepCell.isVisible = false
        }

        onReload?()
    }

    @objc private func onTapRevokeButton() {
        viewModel.onTapRevoke()
    }

    @objc private func onTapApproveButton() {
        viewModel.onTapApprove()
    }

    @objc private func onTapProceedButton() {
        viewModel.onTapProceed()
    }

    private func openRevoke(approveData: SwapAllowanceService.ApproveData) {
        guard let viewController = SwapApproveConfirmationModule.revokeViewController(data: approveData, delegate: self) else {
            return
        }

        onOpen?(viewController, false)
    }

    private func openApprove(approveData: SwapAllowanceService.ApproveData) {
        guard let viewController = SwapApproveModule.instance(data: approveData, delegate: self) else {
            return
        }

        onOpen?(viewController, false)
    }

    private func openConfirm(sendData: SendEvmData) {
        guard let viewController = SwapConfirmationModule.viewController(sendData: sendData, dex: viewModel.service.dex) else {
            return
        }

        onOpen?(viewController, true)
    }

}

extension UniswapDataSource: ISwapDataSource {

    var state: SwapModule.DataSourceState {
        let exactIn = viewModel.tradeService.tradeType == .exactIn
        return SwapModule.DataSourceState(
                tokenFrom: viewModel.tradeService.tokenIn,
                tokenTo: viewModel.tradeService.tokenOut,
                amountFrom: viewModel.tradeService.amountIn,
                amountTo: viewModel.tradeService.amountOut,
                exactFrom: exactIn)
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(
                id: "main",
                headerState: .static(view: settingsHeaderView, height: TextDropDownAndSettingsView.height),
                rows: [
                    StaticRow(
                            cell: fromCoinCardCell,
                            id: "from-card",
                            height: fromCoinCardCell.cellHeight
                    ),
                    StaticRow(
                            cell: switchCell,
                            id: "price",
                            height: switchCell.cellHeight
                    ),
                    StaticRow(
                            cell: toCoinCardCell,
                            id: "to-card",
                            height: toCoinCardCell.cellHeight
                    )
                ]
        ))

        let cells = [
            buyPriceCell,
            sellPriceCell,
            allowanceCell,
            priceImpactCell,
            guaranteedAmountCell
        ]

        sections.append(Section(
                id: "info",
                rows: cells.enumerated().map { index, cell in
                    StaticRow(
                            cell: cell,
                            id: cell.title ?? "info-cell-\(index)",
                            height: cell.cellHeight
                    )
                }
        ))

        let showCells = !(cells.filter { $0.isVisible }.isEmpty)
        sections.append(Section(id: "error",
                headerState: .margin(height: showCells ? .margin12 : 0),
                rows: [
                    StaticRow(
                            cell: warningCell,
                            id: "warning",
                            dynamicHeight: { [weak self] width in
                                self?.warningCell.height(containerWidth: width) ?? 0
                            }
                    ),
                    StaticRow(
                            cell: errorCell,
                            id: "error",
                            dynamicHeight: { [weak self] width in
                                self?.errorCell.cellHeight(width: width) ?? 0
                            }
                    )
                ]
        ))

        let showApproveSteps = approveStepCell.isVisible
        sections.append(Section(
                id: "buttons",
                headerState: .margin(height: .margin24),
                footerState: .margin(height: showApproveSteps ? .margin24 : 0),
                rows: [
                    StaticRow(
                            cell: buttonStackCell,
                            id: "button",
                            height: .heightButton
                    )
                ]
        ))

        sections.append(Section(
                id: "approve-steps",
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                            cell: approveStepCell,
                            id: "steps",
                            height: approveStepCell.cellHeight
                    )
                ]
        ))

        return sections
    }

}

extension UniswapDataSource: IPresentDelegate {

    func present(viewController: UIViewController) {
        onOpen?(viewController, false)
    }

}

extension UniswapDataSource: ISwapApproveDelegate {

    func didApprove() {
        viewModel.didApprove()
    }

}

extension UniswapDataSource: IDynamicHeightCellDelegate {

    func onChangeHeight() {
        onReload?()
    }

}
