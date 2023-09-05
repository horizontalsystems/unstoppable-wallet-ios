import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import TronKit

class SendTronViewController: ThemeViewController {
    private let tronKitWrapper: TronKitWrapper
    private let viewModel: SendTronViewModel
    private let disposeBag = DisposeBag()

    private let iconImageView = UIImageView()
    private let tableView = SectionsTableView(style: .grouped)

    private let availableBalanceCell: SendAvailableBalanceCell

    private let amountCell: AmountInputCell
    private let amountCautionCell = FormCautionCell()

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private let buttonCell = PrimaryButtonCell()

    private var isLoaded = false
    private var keyboardShown = false

    init(tronKitWrapper: TronKitWrapper, viewModel: SendTronViewModel, availableBalanceViewModel: ISendAvailableBalanceViewModel, amountViewModel: AmountInputViewModel, recipientViewModel: RecipientAddressViewModel) {
        self.tronKitWrapper = tronKitWrapper
        self.viewModel = viewModel

        availableBalanceCell = SendAvailableBalanceCell(viewModel: availableBalanceViewModel)

        amountCell = AmountInputCell(viewModel: amountViewModel)

        recipientCell = RecipientAddressInputCell(viewModel: recipientViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: recipientViewModel)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

        if (navigationController?.viewControllers.count ?? 0) == 1 {
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.iconSize24)
        }
        iconImageView.setImage(withUrlString: viewModel.token.coin.imageUrl, placeholder: UIImage(named: viewModel.token.placeholderImageName))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionDataSource = self

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        amountCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        recipientCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        recipientCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        recipientCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        buttonCell.set(style: .yellow)
        buttonCell.title = "send.next_button".localized
        buttonCell.onTap = { [weak self] in
            self?.didTapProceed()
        }

        subscribe(disposeBag, viewModel.proceedEnableDriver) { [weak self] in self?.buttonCell.isEnabled = $0 }
        subscribe(disposeBag, viewModel.amountCautionDriver) { [weak self] caution in
            self?.amountCell.set(cautionType: caution?.type)
            self?.amountCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.addressCautionDriver) { [weak self] caution in
            self?.recipientCell.set(cautionType: caution?.type)
            self?.recipientCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] in self?.openConfirm(contract: $0) }

        tableView.buildSections()
        isLoaded = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !keyboardShown {
            keyboardShown = true
            _ = amountCell.becomeFirstResponder()
        }
    }

    @objc private func didTapProceed() {
        viewModel.didTapProceed()
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    private func openConfirm(contract: Contract) {
        guard let viewController = SendTronConfirmationModule.viewController(tronKitWrapper: tronKitWrapper, contract: contract) else {
            return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension SendTronViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [
            Section(
                id: "available-balance",
                headerState: .margin(height: .margin12),
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
                headerState: .margin(height: .margin16),
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
        if viewModel.showAddress {
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
