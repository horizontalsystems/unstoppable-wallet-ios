import UIKit
import ThemeKit
import OneInchKit
import HUD
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit

class OneInchDataSource {
    private static let levelColors: [UIColor] = [.themeRemus, .themeJacob, .themeLucian]

    private let disposeBag = DisposeBag()

    private let viewModel: OneInchViewModel

    private let settingsHeaderView = TextDropDownAndSettingsView()

    private let fromCoinCardCell: SwapCoinCardCell
    private let switchCell = SwapSwitchCell()
    private let toCoinCardCell: SwapCoinCardCell
    private let buyPriceCell = AdditionalDataCellNew()
    private let allowanceCell: SwapAllowanceCell

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

    init(viewModel: OneInchViewModel, allowanceViewModel: SwapAllowanceViewModel) {
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
        allowanceCell.title = "swap.allowance".localized

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
        subscribe(disposeBag, viewModel.proceedActionDriver) { [weak self] in self?.handle(proceedActionState: $0) }
        subscribe(disposeBag, viewModel.revokeWarningDriver) { [weak self] in self?.handle(revokeWarning: $0) }
        subscribe(disposeBag, viewModel.revokeActionDriver) { [weak self] in self?.handle(revokeActionState: $0) }
        subscribe(disposeBag, viewModel.approveActionDriver) { [weak self] in self?.handle(approveActionState: $0) }
        subscribe(disposeBag, viewModel.approveStepDriver) { [weak self] in self?.handle(approveStepState: $0) }

        subscribe(disposeBag, viewModel.openRevokeSignal) { [weak self] in self?.openRevoke(approveData: $0) }
        subscribe(disposeBag, viewModel.openApproveSignal) { [weak self] in self?.openApprove(approveData: $0) }
        subscribe(disposeBag, viewModel.openConfirmSignal) { [weak self] in self?.openConfirm(parameters: $0) }
    }

//    @objc func onClose() {
//        dismiss(animated: true)
//    }

    private func handle(loading: Bool) {
        switchCell.set(loading: loading)
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

    private func handle(revokeWarning: String?) {
        warningCell.descriptionText = revokeWarning

        onReload?()
    }

    private func handle(revokeActionState: OneInchViewModel.ActionState) {
        handle(actionState: revokeActionState, button: revokeButton)
    }

    private func handle(proceedActionState: OneInchViewModel.ActionState) {
        handle(actionState: proceedActionState, button: proceedButton)
    }

    private func handle(approveActionState: OneInchViewModel.ActionState) {
        handle(actionState: approveActionState, button: approveButton)
    }

    private func handle(actionState: OneInchViewModel.ActionState, button: PrimaryButton) {
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

    private func openConfirm(parameters: OneInchSwapParameters) {
        guard let viewController = SwapConfirmationModule.viewController(parameters: parameters, dex: viewModel.service.dex) else {
            return
        }

        onOpen?(viewController, true)
    }

}

extension OneInchDataSource: ISwapDataSource {

    var state: SwapModule.DataSourceState {
        SwapModule.DataSourceState(
                tokenFrom: viewModel.tradeService.tokenIn,
                tokenTo: viewModel.tradeService.tokenOut,
                amountFrom: viewModel.tradeService.amountIn,
                amountTo: viewModel.tradeService.amountOut,
                exactFrom: false)
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

        sections.append(Section(
                id: "info",
                rows: [
                    StaticRow(
                            cell: buyPriceCell,
                            id: "execution-price",
                            height: buyPriceCell.cellHeight
                    ),
                    StaticRow(
                            cell: allowanceCell,
                            id: "allowance",
                            height: allowanceCell.cellHeight
                    ),
                ]
        ))

        let showCells = (buyPriceCell.isVisible || allowanceCell.isVisible) && (warningCell.descriptionText != nil || errorCell.isVisible)
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

extension OneInchDataSource: IPresentDelegate {

    func present(viewController: UIViewController) {
        onOpen?(viewController, false)
    }

}

extension OneInchDataSource: ISwapApproveDelegate {

    func didApprove() {
        viewModel.didApprove()
    }

}

extension OneInchDataSource: IDynamicHeightCellDelegate {

    func onChangeHeight() {
        onReload?()
    }

}
