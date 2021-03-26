import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import RxSwift
import RxCocoa
import HUD

class CreateAccountViewController: ThemeViewController {
    private let viewModel: CreateAccountViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let mnemonicCell = A5Cell()

    init(viewModel: CreateAccountViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "create_wallet.title".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "create_wallet.create_button".localized, style: .done, target: self, action: #selector(onTapCreateButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        mnemonicCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        mnemonicCell.titleImage = UIImage(named: "key_20")
        mnemonicCell.title = "create_wallet.mnemonic".localized
        mnemonicCell.valueAction = { [weak self] in self?.viewModel.onTapKind() }

        subscribe(disposeBag, viewModel.kindDriver) { [weak self] in self?.mnemonicCell.value = $0 }
        subscribe(disposeBag, viewModel.openSelectKindSignal) { [weak self] in self?.openSelectKind(viewItems: $0) }
        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.finish() }

        tableView.buildSections()
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    @objc private func onTapCreateButton() {
        viewModel.onTapCreate()
    }

    private func openSelectKind(viewItems: [AlertViewItem]) {
        let alertController = AlertRouter.module(title: "create_wallet.mnemonic".localized, viewItems: viewItems) { [weak self] index in
            self?.viewModel.onSelectKind(index: index)
        }

        present(alertController, animated: true)
    }

    private func show(error: String) {
        HudHelper.instance.showError(title: error)
    }

    private func finish() {
        HudHelper.instance.showSuccess()
        dismiss(animated: true)
    }

}

extension CreateAccountViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: mnemonicCell,
                                id: "mnemonic",
                                height: .heightCell48
                        )
                    ]
            )
        ]
    }

}
