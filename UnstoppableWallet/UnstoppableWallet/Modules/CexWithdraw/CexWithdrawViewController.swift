import UIKit
import ThemeKit
import SectionsTableView
import Combine

class CexWithdrawViewController: ThemeViewController {
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
    private var selectedNetwork: String? = nil

    init(viewModel: CexWithdrawViewModel, availableBalanceViewModel: ISendAvailableBalanceViewModel, amountViewModel: AmountInputViewModel, recipientViewModel: RecipientAddressViewModel) {
        self.viewModel = viewModel

        availableBalanceCell = SendAvailableBalanceCell(viewModel: availableBalanceViewModel)
        amountCell = AmountInputCell(viewModel: amountViewModel)
        recipientCell = RecipientAddressInputCell(viewModel: recipientViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: recipientViewModel)
        selectedNetwork = viewModel.selectedNetwork

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
        iconImageView.setImage(withUrlString: viewModel.coinImageUrl, placeholder: UIImage(named: viewModel.placeholderImageName))

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

        amountCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        recipientCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        recipientCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }
        recipientCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

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
        subscribe(&cancellables, viewModel.$proceedEnable) { [weak self] in self?.buttonCell.isEnabled = $0 }
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
        let viewModel = CexWithdrawNetworkSelectViewModel(service: viewModel.networkService)
        let viewController = CexWithdrawNetworkSelectViewController(viewModel: viewModel)

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }

    private func openConfirm(sendData: CexWithdrawModule.SendData) {
        guard let viewController = CexWithdrawConfirmModule.viewController(
            cexAsset: sendData.cexAsset, network: sendData.network, address: sendData.address, amount: sendData.amount
        ) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

}


extension CexWithdrawViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [
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
            )
        ]

        if let network = selectedNetwork {
            sections.append(
                Section(
                    id: "network",
                    headerState: .margin(height: .margin16),
                    rows: [
                        tableView.universalRow48(
                            id: "networks",
                            title: .subhead2("cex_withdraw.network".localized, color: .themeGray),
                            value: .body(network, color: .themeLeah),
                            accessoryType: .dropdown,
                            hash: network,
                            autoDeselect: true,
                            isFirst: true,
                            isLast: true,
                            action: { [weak self] in
                                self?.openNetworkSelect()
                            }
                        )
                    ]
                )
            )
        }

        sections.append(
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
            )
        )

        if selectedNetwork != nil {
            sections.append(
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
                )
            )
        }

        sections.append(
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
        )

        return sections
    }

}
