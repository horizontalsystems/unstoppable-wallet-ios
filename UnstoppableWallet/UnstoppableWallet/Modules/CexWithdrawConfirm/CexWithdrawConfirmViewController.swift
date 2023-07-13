import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD

class CexWithdrawConfirmViewController: ThemeViewController {
    private let viewModel: CexWithdrawConfirmViewModel
    private let cex: Cex
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private let withdrawButton = PrimaryButton()
    private let withdrawingButton = PrimaryButton()

    private var sectionViewItems = [CexWithdrawConfirmViewModel.SectionViewItem]()

    init(viewModel: CexWithdrawConfirmViewModel, cex: Cex) {
        self.viewModel = viewModel
        self.cex = cex

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "confirm".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        let buttonsHolder = BottomGradientHolder()
        view.addSubview(buttonsHolder)
        buttonsHolder.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let stackView = UIStackView()
        buttonsHolder.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(CGFloat.margin24)
        }

        stackView.axis = .vertical
        stackView.spacing = .margin16

        stackView.addArrangedSubview(withdrawButton)

        withdrawButton.set(style: .yellow)
        withdrawButton.setTitle("cex_withdraw_confirm.withdraw".localized, for: .normal)
        withdrawButton.addTarget(self, action: #selector(onTapWithdraw), for: .touchUpInside)

        stackView.addArrangedSubview(withdrawingButton)

        withdrawingButton.set(style: .yellow, accessoryType: .spinner)
        withdrawingButton.isEnabled = false
        withdrawingButton.setTitle("cex_withdraw_confirm.withdraw".localized, for: .normal)

        viewModel.$sectionViewItems
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.sync(sectionViewItems: $0) }
                .store(in: &cancellables)

        viewModel.$withdrawing
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.sync(withdrawing: $0) }
                .store(in: &cancellables)

        viewModel.confirmWithdrawPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.confirmWithdraw(id: $0) }
                .store(in: &cancellables)

        viewModel.errorPublisher
                .receive(on: DispatchQueue.main)
                .sink { text in HudHelper.instance.showErrorBanner(title: text) }
                .store(in: &cancellables)
    }

    private func sync(sectionViewItems: [CexWithdrawConfirmViewModel.SectionViewItem]) {
        self.sectionViewItems = sectionViewItems
        tableView.reload()
    }

    private func sync(withdrawing: Bool) {
        withdrawButton.isHidden = withdrawing
        withdrawingButton.isHidden = !withdrawing
    }

    private func confirmWithdraw(id: String) {
        switch cex {
        case .coinzix:
            guard let orderId = Int(id), let viewController = CoinzixVerifyWithdrawModule.viewController(orderId: orderId) else {
                return
            }

            navigationController?.pushViewController(viewController, animated: true)
        case .binance: ()
        }
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapWithdraw() {
        viewModel.onTapWithdraw()
    }

}

extension CexWithdrawConfirmViewController: SectionsDataSource {

    private func row(viewItem: CexWithdrawConfirmViewModel.ViewItem, rowInfo: RowInfo) -> RowProtocol {
        switch viewItem {
        case let .subhead(iconName, title, value):
            return CellComponent.actionTitleRow(tableView: tableView, rowInfo: rowInfo, iconName: iconName, iconDimmed: true, title: title, value: value)
        case let .amount(iconUrl, iconPlaceholderImageName, coinAmount, currencyAmount, type):
            return CellComponent.amountRow(tableView: tableView, rowInfo: rowInfo, iconUrl: iconUrl, iconPlaceholderImageName: iconPlaceholderImageName, coinAmount: coinAmount, currencyAmount: currencyAmount, type: type)
        case let .address(title, value, contactAddress):
            var onAddToContact: (() -> ())? = nil
            if let contactAddress {
                onAddToContact = { [weak self] in
                    ContactBookModule.showAddition(contactAddress: contactAddress, parentViewController: self)
                }
            }
            return CellComponent.fromToRow(tableView: tableView, rowInfo: rowInfo, title: title, value: value, valueTitle: nil, onAddToContact: onAddToContact)
        case let .value(title, value, type):
            return CellComponent.valueRow(tableView: tableView, rowInfo: rowInfo, iconName: nil, title: title, value: value, type: type)
        case let .feeValue(title, value):
            return CellComponent.doubleAmountRow(
                tableView: tableView, rowInfo: rowInfo, title: title,
                coinValue: ValueFormatter.instance.formatShort(coinValue: value.coinValue) ?? "n/a".localized,
                currencyValue: value.currencyValue.flatMap { ValueFormatter.instance.formatShort(currencyValue: $0) }
            )
        }
    }

    func buildSections() -> [SectionProtocol] {
        viewModel.sectionViewItems.enumerated().map { index, sectionViewItem in
            Section(
                    id: "section_\(index)",
                    headerState: .margin(height: index == 0 ? .margin12 : .margin16),
                    rows: sectionViewItem.viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, rowInfo: RowInfo(index: index, isFirst: index == 0, isLast: index == sectionViewItem.viewItems.count - 1))
                    }
            )
        }
    }

}
