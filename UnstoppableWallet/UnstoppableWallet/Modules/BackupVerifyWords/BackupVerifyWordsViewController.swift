import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit

class BackupVerifyWordsViewController: ThemeViewController {
    private let viewModel: BackupVerifyWordsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItem = BackupVerifyWordsViewModel.ViewItem(inputViewItems: [], wordViewItems: [])
    private var isLoaded = false
    private var didAppear = false

    init(viewModel: BackupVerifyWordsViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup_verify_words.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: EmptyCell.self)
        tableView.registerCell(forClass: BackupMnemonicWordsCell.self)

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] viewItem in
            self?.viewItem = viewItem
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.errorSignal) { HudHelper.instance.show(banner: .error(string: $0)) }
        subscribe(disposeBag, viewModel.openPassphraseSignal) { [weak self] in self?.openPassphrase(account: $0) }
        subscribe(disposeBag, viewModel.successSignal) { [weak self] in
            HudHelper.instance.show(banner: .success(string: "backup.verified".localized))
            self?.dismiss(animated: true)
        }

        tableView.buildSections()
        isLoaded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if didAppear {
            viewModel.onViewAppear()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        didAppear = true
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload()
    }

    private func openPassphrase(account: Account) {
        // may be implemented later
    }

}

extension BackupVerifyWordsViewController: SectionsDataSource {

    private func marginRow(id: String, height: CGFloat) -> RowProtocol {
        Row<EmptyCell>(id: id, height: height)
    }

    func buildSections() -> [SectionProtocol] {
        var rows = [RowProtocol]()

        for (index, viewItem) in viewItem.inputViewItems.enumerated() {
            let row = CellBuilderNew.row(
                    rootElement: .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = viewItem.text
                    },
                    tableView: tableView,
                    id: "input-\(index)",
                    height: .heightCell48,
                    bind: { cell in
                        cell.set(backgroundStyle: .bordered, isFirst: true, isLast: true)
                        cell.wrapperView.borderColor = viewItem.selected ? .themeYellow50 : .themeSteel20
                    }
            )

            rows.append(row)
            rows.append(marginRow(id: "margin-\(index)", height: .margin16))
        }

        let wordViewItems = viewItem.wordViewItems

        return [
            Section(
                    id: "description",
                    footerState: tableView.sectionFooter(text: "backup_verify_words.description".localized)
            ),
            Section(
                    id: "main",
                    footerState: .margin(height: .margin16),
                    rows: rows
            ),
            Section(
                    id: "suggestions",
                    footerState: .margin(height: .margin32),
                    rows: [
                        Row<BackupMnemonicWordsCell>(
                                id: "suggestions",
                                dynamicHeight: { width in
                                    BackupMnemonicWordsCell.height(containerWidth: width, viewItems: wordViewItems)
                                },
                                bind: { cell, _ in
                                    cell.set(viewItems: wordViewItems) { [weak self] index in
                                        self?.viewModel.onSelectWord(index: index)
                                    }
                                }
                        )
                    ]
            )
        ]
    }

}
