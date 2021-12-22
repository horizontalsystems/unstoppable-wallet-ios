import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit
import RxSwift
import RxCocoa

class WatchAddressViewController: KeyboardAwareViewController {
    private let viewModel: WatchAddressViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let addressCell: RecipientAddressInputCell
    private let addressCautionCell: RecipientAddressCautionCell

    private var isLoaded = false

    init(viewModel: WatchAddressViewModel, addressViewModel: RecipientAddressViewModel) {
        self.viewModel = viewModel

        addressCell = RecipientAddressInputCell(viewModel: addressViewModel)
        addressCautionCell = RecipientAddressCautionCell(viewModel: addressViewModel)

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "watch_address.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "watch_address.watch".localized, style: .done, target: self, action: #selector(onTapWatch))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        addressCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        addressCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        addressCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        subscribe(disposeBag, viewModel.watchEnabledDriver) { [weak self] enabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.dismiss(animated: true)
        }

        tableView.buildSections()
        isLoaded = true
    }

    @objc private func onTapWatch() {
        viewModel.onTapWatch()
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.buildSections()
        tableView.beginUpdates()
        tableView.endUpdates()
    }

}

extension WatchAddressViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "address",
                    headerState: .margin(height: .margin16),
                    rows: [
                        StaticRow(
                                cell: addressCell,
                                id: "address-input",
                                dynamicHeight: { [weak self] width in
                                    self?.addressCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: addressCautionCell,
                                id: "address-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.addressCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )
        ]
    }

}
