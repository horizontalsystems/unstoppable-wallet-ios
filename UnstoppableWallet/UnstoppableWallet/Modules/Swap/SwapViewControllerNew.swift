import UIKit
import ThemeKit
import UniswapKit
import HUD
import RxSwift
import RxCocoa
import SectionsTableView

class SwapViewControllerNew: ThemeViewController {
    private static let levelColors: [UIColor] = [.themeGray, .themeRemus, .themeJacob, .themeLucian]

    private let disposeBag = DisposeBag()

    private let viewModel: SwapViewModelNew

    private let tableView = SectionsTableView(style: .grouped)

    private let fromCoinCardCell: SwapCoinCardCell
    private let priceCell = SwapPriceCell()
    private let toCoinCardCell: SwapCoinCardCell
    private let allowanceCell: SwapAllowanceCell

    private let feeCell: SendFeeCell
    private let feePriorityCell: SendFeePriorityCell

    private let buttonCell = ButtonCell()

    private var tradeViewItem: SwapViewModelNew.TradeViewItem?

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

        tableView.registerCell(forClass: AdditionalDataCell.self)
        tableView.registerCell(forClass: D1Cell.self)

        buttonCell.bind(style: .primaryYellow, title: "Proceed") {
            // todo
        }

        subscribeToViewModel()

        tableView.buildSections()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.isLoadingDriver) { [weak self] in self?.handle(loading: $0) }
        subscribe(disposeBag, viewModel.tradeViewItemDriver) { [weak self] in self?.handle(tradeViewItem: $0) }
        subscribe(disposeBag, viewModel.proceedAllowedDriver) { [weak self] in self?.handle(proceedAllowed: $0) }
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

    private func handle(tradeViewItem: SwapViewModelNew.TradeViewItem?) {
        priceCell.set(price: tradeViewItem?.executionPrice)
        self.tradeViewItem = tradeViewItem
        tableView.reload()
    }

    private func handle(proceedAllowed: Bool) {
        buttonCell.set(enabled: proceedAllowed)
    }

    @objc func onSettingsButtonTouchUp() {
        let viewController = SwapTradeOptionsModule.viewController(tradeService: viewModel.tradeService)
        present(viewController, animated: true)
    }

}

extension SwapViewControllerNew: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(
                id: "main",
                headerState: .margin(height: .margin3x),
                footerState: .margin(height: .margin3x),
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

        if allowanceCell.isVisible {
            sections.append(Section(
                    id: "allowance",
                    headerState: .margin(height: .margin3x),
                    footerState: .margin(height: .margin3x),
                    rows: [
                        StaticRow(
                                cell: allowanceCell,
                                id: "allowance",
                                height: SwapAllowanceCell.height
                        )
                    ]
            ))
        }

        if let tradeViewItem = tradeViewItem {
            sections.append(Section(
                    id: "trade",
                    headerState: .margin(height: .margin3x),
                    footerState: .margin(height: .margin3x),
                    rows: [
                        Row<AdditionalDataCell>(
                                id: "price-impact",
                                hash: tradeViewItem.priceImpact,
                                height: AdditionalDataCell.height,
                                bind: { cell, _ in
                                    cell.bind(title: "swap.price_impact".localized, value: tradeViewItem.priceImpact)

                                    let index = tradeViewItem.priceImpactLevel.rawValue % SwapViewControllerNew.levelColors.count
                                    cell.set(valueColor: SwapViewControllerNew.levelColors[index])
                                }
                        ),
                        Row<AdditionalDataCell>(
                                id: "guaranteed-amount",
                                hash: tradeViewItem.minMaxAmount,
                                height: AdditionalDataCell.height,
                                bind: { cell, _ in
                                    cell.bind(title: tradeViewItem.minMaxTitle, value: tradeViewItem.minMaxAmount)
                                    cell.set(valueColor: .themeGray)
                                }
                        )
                    ]
            ))
        }

        sections.append(Section(
                id: "fee",
                headerState: .margin(height: .margin3x),
                rows: [
                    StaticRow(
                            cell: feeCell,
                            id: "fee",
                            height: 29
                    ),
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
                                self?.onSettingsButtonTouchUp()
                            }
                    ),
                ]
        ))
        sections.append(Section(
                id: "button",
                rows: [
                    StaticRow(
                            cell: buttonCell,
                            id: "button",
                            height: ButtonCell.height(style: .primaryYellow)
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

extension SwapViewControllerNew: ISwapConfirmationDelegate {

    func onSwap() {
        viewModel.onSwap()
    }

    func onCancel() {
        navigationController?.popViewController(animated: true)
    }

}

extension SwapViewControllerNew: ISendFeePriorityCellDelegate {

    func open(viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func onChangeHeight() {
        tableView.reload()
    }

}
