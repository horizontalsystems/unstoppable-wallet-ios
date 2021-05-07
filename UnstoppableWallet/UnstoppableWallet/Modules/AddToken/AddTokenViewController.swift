import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class AddTokenViewController: ThemeViewController {
    private let viewModel: AddTokenViewModel
    private let pageTitle: String
    private let referenceTitle: String

    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let inputCell = AddressInputCell()
    private let inputCautionCell = FormCautionCell()
    private let coinNameCell = AdditionalDataCellNew()
    private let symbolCell = AdditionalDataCellNew()
    private let decimalsCell = AdditionalDataCellNew()
    private let buttonCell = ButtonCell()

    init(viewModel: AddTokenViewModel, pageTitle: String, referenceTitle: String) {
        self.viewModel = viewModel
        self.pageTitle = pageTitle
        self.referenceTitle = referenceTitle

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = pageTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        inputCell.isEditable = false
        inputCell.inputPlaceholder = referenceTitle
        inputCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        inputCell.onChangeText = { [weak self] in self?.viewModel.onEnter(reference: $0) }
        inputCell.onFetchText = { [weak self] in
            self?.viewModel.onEnter(reference: $0)
            self?.inputCell.inputText = $0
        }
        inputCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        inputCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        coinNameCell.title = "add_token.coin_name".localized
        symbolCell.title = "add_token.symbol".localized
        decimalsCell.title = "add_token.decimals".localized

        buttonCell.bind(style: .primaryYellow, title: "button.add".localized) { [weak self] in
            self?.viewModel.onTapButton()
        }

        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.inputCell.set(isLoading: loading)
        }
        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] viewItem in
            self?.coinNameCell.value = viewItem?.coinName ?? "..."
            self?.symbolCell.value = viewItem?.symbol ?? "..."
            self?.decimalsCell.value = viewItem.map { "\($0.decimals)" } ?? "..."
        }
        subscribe(disposeBag, viewModel.buttonVisibleDriver) { [weak self] visible in
            self?.buttonCell.isEnabled = visible
        }
        subscribe(disposeBag, viewModel.cautionDriver) { [weak self] caution in
            self?.inputCell.set(cautionType: caution?.type)
            self?.inputCautionCell.set(caution: caution)
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            HudHelper.instance.showSuccess()
            self?.dismiss(animated: true)
        }

        tableView.buildSections()
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    private func reloadTable() {
        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

}

extension AddTokenViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "input",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: inputCell,
                                id: "input",
                                dynamicHeight: { [weak self] width in
                                    self?.inputCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: inputCautionCell,
                                id: "input-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.inputCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),

            Section(
                    id: "main",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: coinNameCell,
                                id: "coin-name",
                                dynamicHeight: { [weak self] width in
                                    self?.coinNameCell.cellHeight ?? 0
                                }
                        ),
                        StaticRow(
                                cell: symbolCell,
                                id: "symbol",
                                dynamicHeight: { [weak self] width in
                                    self?.symbolCell.cellHeight ?? 0
                                }
                        ),
                        StaticRow(
                                cell: decimalsCell,
                                id: "decimals",
                                dynamicHeight: { [weak self] width in
                                    self?.decimalsCell.cellHeight ?? 0
                                }
                        ),
                        StaticRow(
                                cell: buttonCell,
                                id: "button",
                                height: ButtonCell.height(style: .primaryYellow)
                        )
                    ]
            )
        ]
    }

}
