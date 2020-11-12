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
    private let recipientCell: RecipientInputCell
    private let buttonCell = ButtonCell(style: .default, reuseIdentifier: nil)

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


        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(closeDidTap))
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
        tableView.keyboardDismissMode = .onDrag

        buttonCell.bind(style: .primaryYellow, title: "button.apply".localized) { [weak self] in
            self?.doneDidTap()
        }

        tableView.buildSections()
    }

    private func subscribeToViewModel() {
        subscribe(disposeBag, viewModel.validStateDriver) { [weak self] in
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

    private var slippageSection: SectionProtocol {
        let slippageRow = StaticRow(
                cell: slippageCell,
                id: "slippage",
                dynamicHeight: { [weak self] width in
                    self?.slippageCell.height(containerWidth: width) ?? .heightSingleLineCell
                })

        return Section(
                id: "slippage",
                headerState: header(hash: "slippage_header", text: "swap.advanced_settings.slippage".localized),
                footerState: footer(hash: "slippage_footer", text: "swap.advanced_settings.slippage.footer".localized),
                rows: [slippageRow]
        )
    }

    private var deadlineSection: SectionProtocol {
        let deadlineRow = StaticRow(
                cell: deadlineCell,
                id: "deadline",
                dynamicHeight: { [weak self] width in
                    self?.deadlineCell.height(containerWidth: width) ?? .heightSingleLineCell
                })

        return Section(
                id: "deadline",
                headerState: header(hash: "deadline_header", text: "swap.advanced_settings.deadline".localized),
                footerState: footer(hash: "deadline_footer", text: "swap.advanced_settings.deadline.footer".localized),
                rows: [deadlineRow]
        )
    }

    private var recipientSection: SectionProtocol {

        let addressRow = StaticRow(cell: recipientCell,
                        id: "recipient_address",
                        dynamicHeight: { [weak self] width in
                            self?.recipientCell.height(containerWidth: width) ?? .heightSingleLineCell
                        })

        return Section(
                id: "recipient_address",
                headerState: header(hash: "recipient_header", text: "swap.advanced_settings.recipient_address".localized),
                footerState: footer(hash: "recipient_footer", text: "swap.advanced_settings.recipient.footer".localized),
                rows: [addressRow]
        )
    }

    private var buttonSection: SectionProtocol {
        let buttonRow = StaticRow(cell: buttonCell,
                id: "done",
                height: ButtonCell.height(style: .primaryYellow))

        return Section(id: "button_section",
                rows: [buttonRow])
    }

    @objc func doneDidTap() {
        if viewModel.doneDidTap() {
            dismiss(animated: true)
        } else {
            HudHelper.instance.showError(title: "alert.unknown_error".localized)
        }
    }

    @objc func closeDidTap() {
        dismiss(animated: true)
    }

}

extension SwapTradeOptionsView: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(slippageSection)
        sections.append(deadlineSection)
        sections.append(recipientSection)
        sections.append(buttonSection)

        return sections
    }

}

extension SwapTradeOptionsView: IDynamicHeightCellDelegate {

    func onChangeHeight() {
        UIView.performWithoutAnimation { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
    }

}

extension SwapTradeOptionsView: IPresentControllerDelegate {

    func open(viewController: UIViewController) {
        present(viewController, animated: true)
    }

}
