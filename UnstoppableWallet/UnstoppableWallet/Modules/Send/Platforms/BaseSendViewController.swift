import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class BaseSendViewController: ThemeViewController, SectionsDataSource {
    private let disposeBag = DisposeBag()
    private let viewModel: SendViewModel

    private let iconImageView = UIImageView()
    private let tableView = SectionsTableView(style: .grouped)

    private let confirmationFactory: ISendConfirmationFactory

    private let amountCautionViewModel: SendAmountCautionViewModel

    private let availableBalanceCell: SendAvailableBalanceCell

    private let amountCell: AmountInputCell
    private let amountCautionCell = FormCautionCell()

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private let buttonCell = PrimaryButtonCell()

    private var isLoaded = false
    private var keyboardShown = false

    init(confirmationFactory: ISendConfirmationFactory,
         viewModel: SendViewModel,
         availableBalanceViewModel: SendAvailableBalanceViewModel,
         amountInputViewModel: AmountInputViewModel,
         amountCautionViewModel: SendAmountCautionViewModel,
         recipientViewModel: RecipientAddressViewModel
    ) {

        self.confirmationFactory = confirmationFactory

        self.viewModel = viewModel
        self.amountCautionViewModel = amountCautionViewModel

        availableBalanceCell = SendAvailableBalanceCell(viewModel: availableBalanceViewModel)

        amountCell = AmountInputCell(viewModel: amountInputViewModel)

        recipientCell = RecipientAddressInputCell(viewModel: recipientViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: recipientViewModel)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "send.title".localized(viewModel.token.coin.code)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.iconSize24)
        }
        iconImageView.setImage(withUrlString: viewModel.token.coin.imageUrl, placeholder: UIImage(named: viewModel.token.placeholderImageName))
        iconImageView.tintColor = .themeGray

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionDataSource = self

        amountCautionCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }

        recipientCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }
        recipientCell.onOpenViewController = { [weak self] in
            self?.present($0, animated: true)
        }

        recipientCautionCell.onChangeHeight = { [weak self] in
            self?.reloadTable()
        }

        buttonCell.set(style: .yellow)
        buttonCell.title = "send.next_button".localized
        buttonCell.onTap = { [weak self] in
            self?.didTapProceed()
        }

        subscribe(disposeBag, viewModel.proceedEnableDriver) { [weak self] in
            self?.buttonCell.isEnabled = $0
        }
        subscribe(disposeBag, amountCautionViewModel.amountCautionDriver) { [weak self] caution in
            self?.amountCell.set(cautionType: caution?.type)
            self?.amountCautionCell.set(caution: caution)
        }

        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] in
            self?.openConfirm()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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

    private func openConfirm() {
        do {
            let viewController = try confirmationFactory.confirmationViewController()

            navigationController?.pushViewController(viewController, animated: true)
        } catch {
            HudHelper.instance.show(banner: .error(string: error.smartDescription))
        }
    }

    func buildSections() -> [SectionProtocol] {
        [availableBalanceSection, amountSection, recipientSection, buttonSection]
    }

}

extension BaseSendViewController {

    func didLoad() {
        tableView.buildSections()
        isLoaded = true
    }

    func reloadTable() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    var availableBalanceSection: SectionProtocol {
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
        )
    }

    var amountSection: SectionProtocol {
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
    }

    var recipientSection: SectionProtocol {
        Section(
                id: "recipient",
                headerState: .margin(height: .margin12),
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
    }

    var buttonSection: SectionProtocol {
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
    }

}
