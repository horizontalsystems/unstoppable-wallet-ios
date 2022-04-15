import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class SendBitcoinViewController: ThemeViewController {
    private let viewModel: SendXViewModel
    private let disposeBag = DisposeBag()

    private let iconImageView = UIImageView()
    private let tableView = SectionsTableView(style: .grouped)

    private let confirmationFactory: ISendConfirmationFactory
    private let feeSettingsFactory: ISendFeeSettingsFactory

    private let amountCautionViewModel: AmountCautionViewModel
    private let feeWarningViewModel: SendXFeeWarningViewModel

    private let availableBalanceCell: SendAvailableBalanceCell

    private let amountCell: AmountInputCell
    private let amountCautionCell = FormCautionCell()

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private let feeCell: EditableFeeCell
    private let feeCautionCell = TitledHighlightedDescriptionCell()

    private let timeLockCell: SendXTimeLockCell?

    private let buttonCell = ButtonCell()

    private var isLoaded = false
    private var keyboardShown = false

    init(confirmationFactory: ISendConfirmationFactory,
         feeSettingsFactory: ISendFeeSettingsFactory,
         viewModel: SendXViewModel,
         availableBalanceViewModel: SendAvailableBalanceViewModel,
         amountInputViewModel: AmountInputViewModel,
         amountCautionViewModel: AmountCautionViewModel,
         recipientViewModel: RecipientAddressViewModel,
         feeViewModel: SendXFeeViewModel,
         feeWarningViewModel: SendXFeeWarningViewModel,
         timeLockViewModel: SendXTimeLockViewModel?
    ) {

        self.confirmationFactory = confirmationFactory
        self.feeSettingsFactory = feeSettingsFactory
        self.viewModel = viewModel
        self.amountCautionViewModel = amountCautionViewModel
        self.feeWarningViewModel = feeWarningViewModel

        availableBalanceCell = SendAvailableBalanceCell(viewModel: availableBalanceViewModel)

        amountCell = AmountInputCell(viewModel: amountInputViewModel)

        recipientCell = RecipientAddressInputCell(viewModel: recipientViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: recipientViewModel)

        feeCell = EditableFeeCell(viewModel: feeViewModel, isLast: timeLockViewModel == nil)
        timeLockCell = timeLockViewModel.map {
            SendXTimeLockCell(viewModel: $0)
        }

        super.init()

        timeLockCell?.sourceViewController = self
        timeLockCell?.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "send.title".localized(viewModel.platformCoin.coin.code)

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))

        iconImageView.setImage(withUrlString: viewModel.platformCoin.coin.imageUrl, placeholder: UIImage(named: viewModel.platformCoin.coinType.placeholderImageName))
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

        buttonCell.bind(style: .primaryYellow, title: "send.next_button".localized) { [weak self] in
            self?.didTapProceed()
        }

        subscribe(disposeBag, viewModel.proceedEnableDriver) { [weak self] in
            self?.buttonCell.isEnabled = $0
        }
        subscribe(disposeBag, amountCautionViewModel.amountCautionDriver) { [weak self] caution in
            self?.amountCell.set(cautionType: caution?.type)
            self?.amountCautionCell.set(caution: caution)
        }

        subscribe(disposeBag, feeWarningViewModel.cautionDriver) { [weak self] in
            self?.handle(caution: $0)
        }

        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] in
            self?.openConfirm()
        }

        tableView.buildSections()
        isLoaded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !keyboardShown {
            keyboardShown = true
            _ = amountCell.becomeFirstResponder()
        }
    }

    private func handle(caution: TitledCaution?) {
        feeCautionCell.isVisible = caution != nil

        if let caution = caution {
            feeCautionCell.bind(caution: caution)
        }

        reloadTable()
    }

    private func openFeeSettings() {
        let viewController = feeSettingsFactory.feeSettingsViewController

        present(ThemeNavigationController(rootViewController: viewController), animated: true)
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

    private func openConfirm() {
        do {
            let viewController = try confirmationFactory.confirmationViewController()

            navigationController?.pushViewController(viewController, animated: true)
        } catch {
            HudHelper.instance.showError(title: error.smartDescription)
        }
    }

}

extension SendBitcoinViewController: SectionsDataSource {

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
            ),
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
            ),
            Section(
                    id: "fee",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: feeCell,
                                id: "fee",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.openFeeSettings()
                                }
                        )
                    ]
            )
        ]

        if let cell = timeLockCell {
            sections.append(
                    Section(
                            id: "time-lock",
                            rows: [
                                StaticRow(
                                        cell: cell,
                                        id: "time_lock_cell",
                                        height: .heightSingleLineCell
                                )
                            ]
                    )
            )
        }

        sections.append(contentsOf:
        [
            Section(
                    id: "fee-warning",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: feeCautionCell,
                                id: "fee-warning",
                                dynamicHeight: { [weak self] containerWidth in
                                    self?.feeCautionCell.cellHeight(containerWidth: containerWidth) ?? 0
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
                                height: ButtonCell.height(style: .primaryYellow)
                        )
                    ]
            )
        ])

        return sections
    }

}
