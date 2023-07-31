import UIKit
import ThemeKit
import SectionsTableView
import Combine
import ComponentKit

class CexWithdrawViewController: ThemeViewController, ICexWithdrawNetworkSelectDelegate {
    private var cancellables = Set<AnyCancellable>()
    private let viewModel: CexWithdrawViewModel

    private let iconImageView = UIImageView()
    private let tableView = SectionsTableView(style: .grouped)

    private let availableBalanceCell: SendAvailableBalanceCell
    private let amountCell: AmountInputCell
    private let amountCautionCell = FormCautionCell()

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private let warningCell = HighlightedDescriptionCell(showVerticalMargin: false)

    private let buttonCell = PrimaryButtonCell()
    private var isLoaded = false
    private var selectedNetwork: String
    private var fee: CexWithdrawViewModel.FeeAmount?

    init(viewModel: CexWithdrawViewModel, availableBalanceViewModel: ISendAvailableBalanceViewModel, amountViewModel: AmountInputViewModel, recipientViewModel: RecipientAddressViewModel) {
        self.viewModel = viewModel

        availableBalanceCell = SendAvailableBalanceCell(viewModel: availableBalanceViewModel)
        amountCell = AmountInputCell(viewModel: amountViewModel)
        recipientCell = RecipientAddressInputCell(viewModel: recipientViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: recipientViewModel)
        selectedNetwork = viewModel.selectedNetwork
        fee = viewModel.fee

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "send.title".localized(viewModel.coinCode)

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.iconSize24)
        }
        iconImageView.setImage(withUrlString: viewModel.coinImageUrl, placeholder: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionDataSource = self

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        amountCautionCell.onChangeHeight = { [weak self] in self?.reloadHeights() }

        recipientCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        recipientCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }
        recipientCautionCell.onChangeHeight = { [weak self] in self?.reloadHeights() }

        warningCell.descriptionText = "cex_withdraw.network_warning".localized

        buttonCell.set(style: .yellow)
        buttonCell.title = "send.next_button".localized
        buttonCell.onTap = { [weak self] in
            self?.didTapProceed()
        }

        subscribe(&cancellables, viewModel.$selectedNetwork) { [weak self] in
            self?.selectedNetwork = $0
            self?.reloadTable()
        }
        subscribe(&cancellables, viewModel.$fee) { [weak self] in
            self?.fee = $0
            self?.reloadTable()
        }
        subscribe(&cancellables, viewModel.$amountCaution) { [weak self] caution in
            self?.amountCell.set(cautionType: caution?.type)
            self?.amountCautionCell.set(caution: caution)
        }
        subscribe(&cancellables, viewModel.proceedPublisher) { [weak self] in self?.openConfirm(sendData: $0) }

        tableView.buildSections()
        isLoaded = true
    }

    @objc private func didTapProceed() {
        viewModel.didTapProceed()
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    private func openNetworkSelect() {
        let viewController = CexWithdrawNetworkSelectViewController(viewItems: viewModel.networkViewItems, selectedNetworkIndex: viewModel.selectedNetworkIndex)
        viewController.delegate = self

        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func reloadHeights() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }

    func onSelect(index: Int) {
        viewModel.onSelectNetwork(index: index)
    }

    private func onChange(feeFromAmount: Bool) {
        viewModel.onChange(feeFromAmount: feeFromAmount)
    }

    private func openConfirm(sendData: CexWithdrawModule.SendData) {
        guard let viewController = CexWithdrawConfirmModule.viewController(sendData: sendData) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

}


extension CexWithdrawViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                id: "available-balance",
                headerState: .margin(height: .margin4),
                rows: [
                    StaticRow(
                        cell: availableBalanceCell,
                        id: "available-balance",
                        height: availableBalanceCell.cellHeight
                    )
                ]
            ),
            Section(
                id: "amount",
                headerState: .margin(height: .margin8),
                rows: [
                    StaticRow(
                        cell: amountCell,
                        id: "amount-input",
                        height: amountCell.cellHeight
                    ),
                    StaticRow(
                        cell: amountCautionCell,
                        id: "amount-caution",
                        dynamicHeight: { [weak self] width in
                            self?.amountCautionCell.height(containerWidth: width) ?? 0
                        }
                    )
                ]
            ),
            Section(
                id: "network",
                headerState: .margin(height: .margin16),
                rows: [
                    tableView.universalRow48(
                        id: "networks",
                        title: .subhead2("cex_withdraw.network".localized, color: .themeGray),
                        value: .body(selectedNetwork, color: .themeLeah),
                        accessoryType: viewModel.networkViewItems.count > 1 ? .dropdown : .none,
                        hash: selectedNetwork,
                        autoDeselect: true,
                        isFirst: true,
                        isLast: true,
                        action: viewModel.networkViewItems.count > 1 ? { [weak self] in self?.openNetworkSelect() } : nil
                    )
                ]
            ),
            Section(
                id: "recipient",
                headerState: .margin(height: .margin16),
                rows: [
                    StaticRow(
                        cell: recipientCell,
                        id: "recipient-input",
                        dynamicHeight: { [weak self] width in
                            self?.recipientCell.height(containerWidth: width) ?? 0
                        }
                    ),
                    StaticRow(
                        cell: recipientCautionCell,
                        id: "recipient-caution",
                        dynamicHeight: { [weak self] width in
                            self?.recipientCautionCell.height(containerWidth: width) ?? 0
                        }
                    )
                ]
            ),
            Section(
                id: "fee",
                headerState: .margin(height: .margin16),
                rows: [
                    CellBuilderNew.row(
                        rootElement: .hStack([
                            .text { component in
                                component.font = .subhead2
                                component.textColor = .themeGray
                                component.textAlignment = .left
                                component.text = "cex_withdraw.fee".localized
                            },
                            .margin0,
                            .text { _ in },
                            .vStackCentered([
                                .text { [weak self] (component: TextComponent) -> () in
                                    component.font = .subhead2
                                    component.textColor = .themeLeah
                                    component.textAlignment = .right
                                    component.text = self?.fee?.coinAmount
                                },
                                .margin(1),
                                .text { [weak self] (component: TextComponent) -> () in
                                    component.font = .caption
                                    component.textColor = .themeGray
                                    component.textAlignment = .right
                                    component.text = self?.fee?.currencyAmount
                                }
                            ])
                        ]),
                        tableView: tableView,
                        id: "fee-value",
                        hash: "fee-value-\(fee?.coinAmount ?? "-")",
                        height: .heightDoubleLineCell,
                        bind: { cell in
                            cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
                        }
                    ),
                    CellBuilderNew.row(
                        rootElement: .hStack([
                            .text { component in
                                component.font = .subhead2
                                component.textColor = .themeGray
                                component.textAlignment = .left
                                component.text = "cex_withdraw.fee_from_amount".localized
                            },
                            .margin0,
                            .text { _ in },
                            .switch { component in
                                component.switchView.isOn = false
                                component.onSwitch = { [weak self] in self?.onChange(feeFromAmount: $0) }
                            }
                        ]),
                        tableView: tableView,
                        id: "fee-from-amount",
                        hash: "fee-from-amount",
                        height: .heightCell48,
                        bind: { cell in
                            cell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
                        }
                    ),
                ]
            ),
            Section(
                id: "warning",
                headerState: .margin(height: .margin16),
                rows: [
                    StaticRow(
                        cell: warningCell,
                        id: "warning-cell",
                        dynamicHeight: { [weak self] width in
                            self?.warningCell.height(containerWidth: width) ?? 0
                        }
                    )
                ]
            ),
            Section(
                id: "button",
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                        cell: buttonCell,
                        id: "button",
                        height: PrimaryButtonCell.height
                    )
                ]
            )
        ]
    }

}

