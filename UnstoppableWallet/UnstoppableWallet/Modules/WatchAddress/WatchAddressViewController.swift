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
    private let watchButton = ThemeButton()

    private let nameCell = TextFieldCell()

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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "watch_address.watch".localized, style: .done, target: self, action: #selector(onTapWatch))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)

        view.addSubview(watchButton)
        watchButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        watchButton.apply(style: .primaryYellow)
        watchButton.setTitle("watch_address.watch".localized, for: .normal)
        watchButton.addTarget(self, action: #selector(onTapWatch), for: .touchUpInside)

        nameCell.inputPlaceholder = viewModel.namePlaceholder
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0) }

        addressCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        addressCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        addressCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        subscribe(disposeBag, viewModel.nameDriver) { [weak self] name in
            self?.nameCell.inputText = name
        }
        subscribe(disposeBag, viewModel.watchEnabledDriver) { [weak self] enabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
            self?.watchButton.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.dismiss(animated: true)
        }

        tableView.buildSections()
        isLoaded = true
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
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

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { $0.bind(text: text) },
                dynamicHeight: { _ in SubtitleHeaderFooterView.height }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "name",
                    headerState: header(text: "watch_address.name".localized),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: nameCell,
                                id: "name",
                                height: .heightSingleLineCell
                        )
                    ]
            ),
            Section(
                    id: "address",
                    headerState: header(text: "watch_address.address".localized),
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
            ),
        ]
    }

}
