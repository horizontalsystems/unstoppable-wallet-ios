import ThemeKit
import RxSwift
import RxCocoa
import SectionsTableView
import CurrencyKit
import HUD

class SwapTradeOptionsView: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: SwapTradeOptionsViewModel

    private let tableView = SectionsTableView(style: .grouped)

    private let slippageCell: VerifiedInputCell
    private let deadlineCell: VerifiedInputCell
    private let buttonCell = ButtonCell(style: .default, reuseIdentifier: nil)
    private let toggleCell = ToggleCell(style: .default, reuseIdentifier: nil)
    private let recipientCell: RecipientInputCell

    private var error: String?

    init(viewModel: SwapTradeOptionsViewModel) {
        self.viewModel = viewModel

        slippageCell = VerifiedInputCell(viewModel: viewModel.slippageViewModel)
        deadlineCell = VerifiedInputCell(viewModel: viewModel.deadlineViewModel)
        recipientCell = RecipientInputCell(viewModel: viewModel.recipientViewModel)

        super.init()

        slippageCell.delegate = self
        deadlineCell.delegate = self
        recipientCell.delegate = self
        recipientCell.openDelegate = self

        subscribeToViewModel()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()


        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(closeDidTap))
        title = "swap.advanced_settings".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.registerCell(forClass: VerifiedInputCell.self)
        tableView.registerCell(forClass: ButtonCell.self)
        tableView.registerCell(forClass: ToggleCell.self)

        tableView.sectionDataSource = self
        tableView.allowsSelection = false

        buttonCell.bind(style: .primaryYellow, title: "button.done".localized) { [weak self] in
            self?.doneDidTap()
        }
        toggleCell.bind(title: "swap.advanced_settings.recipient_address".localized, isOn: false) { [weak self] _ in
            self?.tableView.reload(animated: true)
        }

        tableView.buildSections()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.applyEnabledDriver) { [weak self] in
            self?.buttonCell.isEnabled = $0
        }
    }

    private func header(hash: String, text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

    private func footer(hash: String, text: String) -> ViewState<BottomDescriptionHeaderFooterView> {
        .cellType(
                hash: hash,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { width in
                    BottomDescriptionHeaderFooterView.height(containerWidth: width, text: text)
                }
        )
    }

    @objc func doneDidTap() {
        navigationController?.popViewController(animated: true)
    }

    @objc func closeDidTap() {
        navigationController?.popViewController(animated: true)
    }

}

extension SwapTradeOptionsView: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let slippageRow = StaticRow(
                cell: slippageCell,
                id: "slippage",
                dynamicHeight: { [weak self] width in
                    self?.slippageCell.height(containerWidth: width) ?? .heightSingleLineCell
                })

        let deadlineRow = StaticRow(
                cell: deadlineCell,
                id: "deadline",
                dynamicHeight: { [weak self] width in
                    self?.deadlineCell.height(containerWidth: width) ?? .heightSingleLineCell
                })

        var recipientRows = [RowProtocol]()
        let toggleRow = StaticRow(cell: toggleCell,
                id: "toggle_recipient",
                height: .heightSingleLineCell)

        recipientRows.append(toggleRow)

        if toggleCell.isOn {
            let recipientAddressRow = StaticRow(cell: recipientCell,
                    id: "recipient_address",
                    dynamicHeight: { [weak self] width in
                        self?.recipientCell.height(containerWidth: width) ?? .heightSingleLineCell
                    })
            recipientRows.append(recipientAddressRow)
        }

        let buttonRow = StaticRow(cell: buttonCell,
                id: "done",
                height: ButtonCell.height(style: .primaryYellow))

        return [
            Section(
                    id: "slippage",
                    headerState: header(hash: "slippage_header".localized, text: "swap.advanced_settings.slippage.header".localized),
                    footerState: footer(hash: "slippage_footer".localized, text: "swap.advanced_settings.slippage.footer".localized),
                    rows: [slippageRow]
            ),
            Section(
                    id: "deadline",
                    headerState: header(hash: "deadline_header".localized, text: "swap.advanced_settings.deadline.header".localized),
                    footerState: footer(hash: "deadline_footer".localized, text: "swap.advanced_settings.deadline.footer".localized),
                    rows: [deadlineRow]
            ),
            Section(
                    id: "recipient",
                    footerState: footer(hash: "recipient_footer".localized, text: "swap.advanced_settings.recipient.footer".localized),
                    rows: recipientRows
            ),
            Section(id: "button_section",
                    rows: [buttonRow])
        ]
    }

}

extension SwapTradeOptionsView: ISendFeePriorityCellDelegate {

    func open(viewController: UIViewController) {
        present(viewController, animated: true)
    }

    func onChangeHeight() {
        UIView.performWithoutAnimation { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
    }

}

extension SwapTradeOptionsView: IOpenControllerDelegate {

    func open(controller: UIViewController) {
        present(controller, animated: true)
    }

}