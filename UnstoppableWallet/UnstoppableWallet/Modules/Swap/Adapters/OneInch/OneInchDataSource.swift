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
    private let allowanceViewModel: SwapAllowanceViewModel

    private let settingsHeaderView = TextDropDownAndSettingsHeaderView()

    private let inputCell: SwapInputCell

    private let buyPriceCell = SwapPriceCell()
    private let allowanceCell = BaseThemeCell()
    private let availableBalanceCell = BaseThemeCell()
    private let priceImpactCell = BaseThemeCell()

    private let warningCell = HighlightedDescriptionCell(showVerticalMargin: false)
    private let errorCell = TitledHighlightedDescriptionCell()
    private let buttonStackCell = StackViewCell()
    private let revokeButton = PrimaryButton()
    private let approve1Button = PrimaryButton()
    private let proceedButton = PrimaryButton()
    private let proceed2Button = PrimaryButton()

    var onOpen: ((_ viewController: UIViewController, _ viaPush: Bool) -> ())? = nil
    var onOpenSelectProvider: (() -> ())? = nil
    var onOpenSettings: (() -> ())? = nil
    var onClose: (() -> ())? = nil
    var onReload: (() -> ())? = nil

    weak var tableView: UITableView?

    private var emptyAmountIn: Bool = true

    private var lastBuyPrice: SwapPriceCell.PriceViewItem?
    private var lastAllowance: String?
    private var lastAvailableBalance: String?
    private var lastPriceImpact: String?
    private var error: String?

    init(viewModel: OneInchViewModel, allowanceViewModel: SwapAllowanceViewModel) {
        self.viewModel = viewModel
        self.allowanceViewModel = allowanceViewModel

        inputCell = SwapInputModule.cell(service: viewModel.service, tradeService: viewModel.tradeService, switchService: viewModel.switchService)
        inputCell.presentDelegate = self
        inputCell.onSwitch = { [weak self] in
            self?.viewModel.onTapSwitch()
        }

        settingsHeaderView.bind(dropdownTitle: viewModel.dexName)
        settingsHeaderView.onTapDropDown = { [weak self] in self?.onOpenSelectProvider?() }
        settingsHeaderView.onTapSettings = { [weak self] in self?.onOpenSettings?() }

        settingsHeaderView.onTapSelector = { [weak self] in self?.onChangeAmountType(index: $0) }
        settingsHeaderView.setSelector(items: viewModel.amountTypeSelectorItems)

        initCells()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initCells() {
        revokeButton.set(style: .yellow)
        revokeButton.addTarget(self, action: #selector((onTapRevokeButton)), for: .touchUpInside)
        buttonStackCell.add(view: revokeButton)

        approve1Button.addTarget(self, action: #selector((onTapApproveButton)), for: .touchUpInside)
        buttonStackCell.add(view: approve1Button)

        errorCell.set(backgroundStyle: .transparent, isFirst: true)

        proceedButton.set(style: .yellow)
        proceedButton.addTarget(self, action: #selector((onTapProceedButton)), for: .touchUpInside)
        buttonStackCell.add(view: proceedButton)

        proceed2Button.set(style: .yellow, accessoryType: .icon(image: UIImage(named: "numbers_2_24")))
        proceed2Button.addTarget(self, action: #selector((onTapProceedButton)), for: .touchUpInside)
        buttonStackCell.add(view: proceed2Button)

        subscribeToViewModel()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.availableBalanceDriver) { [weak self] in self?.handle(balance: $0) }
        subscribe(disposeBag, viewModel.buyPriceDriver) { [weak self] in self?.handle(buyPrice: $0) }
        subscribe(disposeBag, viewModel.countdownTimerDriver) { [weak self] in self?.handle(countDownTimer: $0) }
        subscribe(disposeBag, viewModel.amountInDriver) { [weak self] in self?.handle(amountIn: $0) }
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
        subscribe(disposeBag, viewModel.amountTypeIndexDriver) { [weak self] in self?.settingsHeaderView.setSelector(index: $0) }
        subscribe(disposeBag, viewModel.isAmountTypeAvailableDriver) { [weak self] in self?.settingsHeaderView.setSelector(isEnabled: $0) }

        subscribe(disposeBag, allowanceViewModel.allowanceDriver) { [weak self] in self?.handle(allowance: $0)  }
    }

    func viewDidAppear() {
        _ = inputCell.becomeFirstResponder()
    }

    private func handle(balance: String?) {
        lastAvailableBalance = balance

        CellBuilderNew.buildStatic(cell: availableBalanceCell, rootElement: .hStack([
            .textElement(text: .subhead2("send.available_balance".localized), parameters: .highHugging),
            .textElement(text: .subhead2(balance, color: .themeLeah), parameters: .rightAlignment)
        ]))

        onReload?()
    }

    private func handle(buyPrice: SwapPriceCell.PriceViewItem?) {
        lastBuyPrice = buyPrice
        buyPriceCell.set(item: buyPrice)

        onReload?()
    }

    private func handle(countDownTimer: Float) {
        buyPriceCell.set(progress: countDownTimer)
    }

    private func handle(allowance: String?) {
        lastAllowance = allowance

        CellBuilderNew.buildStatic(cell: allowanceCell, rootElement: .hStack([
            .secondaryButton { [weak self] component in
                component.button.set(style: .transparent2, image: UIImage(named: "circle_information_20"))
                component.button.setTitle("swap.allowance".localized, for: .normal)
                component.onTap = {
                    self?.showInfo(description: InfoDescription(title: "swap.allowance".localized, text: "swap.dex_info.content_allowance".localized))
                }
            },
            .textElement(text: .subhead2(allowance, color: .themeLucian), parameters: .rightAlignment)
        ]))

        onReload?()
    }

    private func handle(amountIn: Decimal) {
        emptyAmountIn = amountIn.isZero

        onReload?()
    }

    private func handle(loading: Bool) {
        buyPriceCell.priceButton.isEnabled = !loading
    }

    private func handle(error: String?) {
        self.error = error

        if let error = error {
            errorCell.isVisible = true
            errorCell.bind(caution: TitledCaution(title: "alert.error".localized, text: error, type: .error))
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
        handle(actionState: proceedActionState, button: proceed2Button)
    }

    private func handle(approveActionState: OneInchViewModel.ActionState) {
        handle(actionState: approveActionState, button: approve1Button)
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
        let isApproving = approveStepState == .approving

        approve1Button.set(style: .gray, accessoryType: isApproving ? .spinner : .icon(image: UIImage(named: "numbers_1_24")))

        switch approveStepState {
        case .notApproved, .revokeRequired, .revoking:
            proceedButton.isHidden = false
            proceed2Button.isHidden = true
        default:
            proceedButton.isHidden = true
            proceed2Button.isHidden = false
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

    private func onChangeAmountType(index: Int) {
        viewModel.onChangeAmountType(index: index)
    }

    private var infoSection: SectionProtocol {
        let noAlerts = warningCell.descriptionText == nil && error == nil

        let cellViewItems = [
            InfoCellViewItem(
                    id: "buy-price",
                    cell: buyPriceCell,
                    isVisible: noAlerts && lastBuyPrice != nil),
            InfoCellViewItem(
                    id: "allowance",
                    cell: allowanceCell,
                    isVisible: noAlerts && lastAllowance != nil),
            InfoCellViewItem(
                    id: "available-balance",
                    cell: availableBalanceCell,
                    isVisible: noAlerts && lastAvailableBalance != nil && lastBuyPrice == nil && lastAllowance == nil),
            InfoCellViewItem(
                    id: "price-impact",
                    cell: priceImpactCell,
                    isVisible: noAlerts && lastPriceImpact != nil && lastAllowance == nil),
        ]

        let firstIndex = cellViewItems.firstIndex(where: { $0.isVisible }) ?? -1
        let lastIndex = cellViewItems.lastIndex(where: { $0.isVisible }) ?? -1


        let rows = cellViewItems.enumerated().map { index, viewItem in
            viewItem.cell.set(backgroundStyle: .externalBorderOnly, isFirst: firstIndex == index, isLast: lastIndex == index)
            return StaticRow(
                    cell: viewItem.cell,
                    id: viewItem.id,
                    height: viewItem.isVisible ? .heightSingleLineCell : 0
            )
        }


        return Section(
                id: "info",
                headerState: .margin(height: noAlerts ? .margin12 : 0),
                rows: rows
        )
    }

    private func showInfo(description: InfoDescription) {
        let viewController = BottomSheetModule.description(title: description.title, text: description.text)
        onOpen?(viewController, false)
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

    var buildSections: [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(
                id: "header",
                headerState: .static(view: settingsHeaderView, height: TextDropDownAndSettingsHeaderView.height),
                rows: [
                ]
        ))

        sections.append(Section(
                id: "main",
                headerState: .margin(height: .margin8),
                rows: [
                    StaticRow(
                            cell: inputCell,
                            id: "input-card",
                            height: SwapInputCell.cellHeight
                    )
                ]
        ))

        sections.append(infoSection)

        let hasAlert = warningCell.descriptionText != nil || error != nil
        sections.append(Section(id: "error",
                headerState: .margin(height: hasAlert ? .margin12 : 0),
                rows: [
                    StaticRow(
                            cell: warningCell,
                            id: "warning",
                            dynamicHeight: { [weak self] width in
                                if self?.error != nil {
                                    return 0
                                }
                                return self?.warningCell.height(containerWidth: width) ?? 0
                            }
                    ),
                    StaticRow(
                            cell: errorCell,
                            id: "error",
                            dynamicHeight: { [weak self] width in
                                self?.errorCell.cellHeight(containerWidth: width) ?? 0
                            }
                    )
                ]
        ))
        sections.append(Section(
                id: "buttons",
                headerState: .margin(height: .margin16),
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                            cell: buttonStackCell,
                            id: "button",
                            height: .heightButton
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

extension OneInchDataSource {

    struct InfoCellViewItem {
        let id: String
        let cell: BaseThemeCell
        let isVisible: Bool
    }

    struct InfoDescription {
        let title: String
        let text: String
    }

}
