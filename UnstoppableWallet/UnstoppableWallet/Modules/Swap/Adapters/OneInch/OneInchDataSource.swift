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

    private let fromCoinCardCell: SwapCoinCardCell
    private let switchCell = SwapSwitchCell()
    private let toCoinCardCell: SwapCoinCardCell
    private let poweredByCell = AdditionalDataCellNew()
    private let priceCell = AdditionalDataCellNew()
    private let allowanceCell: SwapAllowanceCell

    private let errorCell = SendEthereumErrorCell()
    private let buttonStackCell = StackViewCell()
    private let approveButton = ThemeButton()
    private let proceedButton = ThemeButton()

    var onOpen: ((_ viewController: UIViewController,_ viaPush: Bool) -> ())? = nil
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

        initCells()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initCells() {
//        slippageCell.title = "swap.advanced_settings.slippage".localized
//        deadlineCell.title = "swap.advanced_settings.deadline".localized
//        recipientCell.title = "swap.advanced_settings.recipient_address".localized
        poweredByCell.title = "swap.powered_by".localized
        poweredByCell.value = viewModel.dexName

        priceCell.title = "swap.price".localized
        priceCell.isVisible = false
        allowanceCell.title = "swap.allowance".localized

        approveButton.apply(style: .primaryGray)
        approveButton.addTarget(self, action: #selector((onTapApproveButton)), for: .touchUpInside)
        buttonStackCell.add(view: approveButton)

        proceedButton.apply(style: .primaryYellow)
        proceedButton.addTarget(self, action: #selector((onTapProceedButton)), for: .touchUpInside)
        buttonStackCell.add(view: proceedButton)

        subscribeToViewModel()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] in self?.handle(loading: $0) }
        subscribe(disposeBag, viewModel.swapErrorDriver) { [weak self] in self?.handle(error: $0) }
        subscribe(disposeBag, viewModel.proceedActionDriver) { [weak self] in self?.handle(proceedActionState: $0) }
        subscribe(disposeBag, viewModel.approveActionDriver) { [weak self] in self?.handle(approveActionState: $0) }

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

    private func handle(proceedActionState: OneInchViewModel.ActionState) {
        handle(actionState: proceedActionState, button: proceedButton)
    }

    private func handle(approveActionState: OneInchViewModel.ActionState) {
        handle(actionState: approveActionState, button: approveButton)
    }

    private func handle(actionState: OneInchViewModel.ActionState, button: ThemeButton) {
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

    @objc private func onTapApproveButton() {
        viewModel.onTapApprove()
    }

    @objc private func onTapProceedButton() {
        viewModel.onTapProceed()
    }

    @objc func onTapAdvancedSettings() {
        onOpenSettings?()
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
                coinFrom: viewModel.tradeService.coinIn,
                coinTo: viewModel.tradeService.coinOut,
                amountFrom: viewModel.tradeService.amountIn,
                amountTo: viewModel.tradeService.amountOut,
                exactFrom: false)
    }

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
                headerState: .margin(height: 6),
                footerState: .margin(height: 6),
                rows: [
                    StaticRow(
                            cell: poweredByCell,
                            id: "powered_by",
                            height: poweredByCell.cellHeight
                    ),
                    StaticRow(
                            cell: priceCell,
                            id: "execution-price",
                            height: priceCell.cellHeight
                    ),
                    StaticRow(
                            cell: allowanceCell,
                            id: "allowance",
                            height: allowanceCell.cellHeight
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

extension OneInchDataSource: IPresentDelegate {

    func show(viewController: UIViewController) {
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
