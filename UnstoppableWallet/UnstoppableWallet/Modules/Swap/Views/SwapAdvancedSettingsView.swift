import ThemeKit
import RxSwift
import RxCocoa
import SectionsTableView
import CurrencyKit
import HUD

class SwapAdvancedSettingsView: ThemeViewController {
    private let disposeBag = DisposeBag()

//    private let feeViewModel: EthereumFeeViewModel
    private let slippageViewModel: SlippageViewModel

    private let tableView = SectionsTableView(style: .grouped)
//    private let feeCell: SendFeeCell
//    private let feePriorityCell: SendFeePriorityCell

    private let slippageCell: VerifiedInputCell

    init(slippageViewModel: SlippageViewModel) {//feeViewModel: EthereumFeeViewModel) {
//        self.feeViewModel = feeViewModel
        self.slippageViewModel = slippageViewModel

//        feeCell = SendFeeCell(viewModel: feeViewModel)
//        feePriorityCell = SendFeePriorityCell(viewModel: feeViewModel)
        slippageCell = VerifiedInputCell(viewModel: slippageViewModel)

        super.init()

        subscribe(disposeBag, slippageViewModel.changeHeight) { [weak self] _ in
            self?.tableView.reload()
            _ = self?.slippageCell.becomeFirstResponder()
        }

        subscribe(disposeBag, slippageViewModel.errorDriver) { [weak self] _ in
            self?.tableView.reload()
        }

//        feePriorityCell.delegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "swap.advanced_settings".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: VerifiedInputCell.self)

        tableView.sectionDataSource = self
        tableView.allowsSelection = false

        tableView.buildSections()
    }

}

extension SwapAdvancedSettingsView: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let height = VerifiedInputCell
                .height(containerWidth: view.width,
                text: slippageCell.inputText,
                buttonItems: slippageViewModel.buttonItems,
                maximumNumberOfLines: slippageViewModel.maximumNumberOfLines,
                error: slippageViewModel.error)

        let slippageRow = StaticRow(
                cell: slippageCell,
                id: "slippage_\(height.description)",
                height: height)

//        var feeRows = [RowProtocol]()
//
//        feeRows.append(
//                StaticRow(
//                        cell: feeCell,
//                        id: "fee",
//                        height: 29
//                )
//        )
//
//        feeRows.append(
//                StaticRow(
//                        cell: feePriorityCell,
//                        id: "fee-priority",
//                        height: feePriorityCell.currentHeight
//                )
//        )
//
//        if let error = error {
//            feeRows.append(errorRow(error: error))
//        }

        return [
            Section(
                    id: "slippage",
                    footerState: .margin(height: CGFloat.margin3x),
                    rows: [slippageRow]
            ),
//            Section(
//                    id: "fee",
//                    rows: feeRows
//            )
        ]
    }

}
