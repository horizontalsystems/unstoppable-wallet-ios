import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView

class CexWithdrawConfirmViewController: ThemeViewController {
    private let viewModel: CexWithdrawConfirmViewModel
    private let handler: ICexWithdrawHandler
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private let withdrawButton = PrimaryButton()
    private let withdrawingButton = PrimaryButton()

    private var sectionViewItems = [CexWithdrawConfirmViewModel.SectionViewItem]()

    init(viewModel: CexWithdrawConfirmViewModel, handler: ICexWithdrawHandler) {
        self.viewModel = viewModel
        self.handler = handler

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
        buttonsHolder.add(to: self, under: tableView)

        buttonsHolder.addSubview(withdrawButton)

        withdrawButton.set(style: .yellow)
        withdrawButton.setTitle("cex_withdraw_confirm.withdraw".localized, for: .normal)
        withdrawButton.addTarget(self, action: #selector(onTapWithdraw), for: .touchUpInside)

        buttonsHolder.addSubview(withdrawingButton)

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
                .sink { [weak self] in self?.confirmWithdraw(result: $0) }
                .store(in: &cancellables)

        viewModel.errorPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.show(error: $0) }
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

    private func confirmWithdraw(result: Any) {
        handler.handle(result: result, viewController: self)
    }

    private func show(error: String) {
        let viewController = BottomSheetModule.viewController(
            image: .local(image: UIImage(named: "warning_2_24")?.withTintColor(.themeLucian)),
            title: "cex_withdraw_confirm.withdraw_failed".localized,
            items: [
                .highlightedDescription(text: error, style: .red)
            ],
            buttons: [
                .init(style: .yellow, title: "button.ok".localized)
            ]
        )

        present(viewController, animated: true)
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
        case let .feeValue(title, coinAmount, currencyAmount):
            return CellComponent.doubleAmountRow(
                tableView: tableView, rowInfo: rowInfo, title: title,
                coinValue: coinAmount,
                currencyValue: currencyAmount
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
