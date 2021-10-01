import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit

class BackupConfirmKeyViewController: KeyboardAwareViewController {
    private let viewModel: BackupConfirmKeyViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let firstWordCell = IndexedTextFieldCell()
    private let firstWordCautionCell = FormCautionCell()
    private let secondWordCell = IndexedTextFieldCell()
    private let secondWordCautionCell = FormCautionCell()

    private let passphraseCell = TextFieldCell()
    private let passphraseCautionCell = FormCautionCell()

    private var isLoaded = false
    private var isFirstShownKeyboard = false

    init(viewModel: BackupConfirmKeyViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.confirmation.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        firstWordCell.returnKeyType = .next
        firstWordCell.onChangeText = { [weak self] in self?.viewModel.onChange(firstWord: $0 ?? "") }
        firstWordCell.onReturn = { [weak self] in
            _ = self?.secondWordCell.becomeFirstResponder()
        }

        firstWordCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        secondWordCell.returnKeyType = viewModel.passphraseVisible ? .next : .done
        secondWordCell.onChangeText = { [weak self] in self?.viewModel.onChange(secondWord: $0 ?? "") }
        secondWordCell.onReturn = { [weak self] in
            self?.onReturnSecondWord()
        }

        secondWordCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        passphraseCell.inputPlaceholder = "backup_key.confirmation.passphrase".localized
        passphraseCell.returnKeyType = .done
        passphraseCell.isSecureTextEntry = true
        passphraseCell.onChangeText = { [weak self] in self?.viewModel.onChange(passphrase: $0 ?? "") }
        passphraseCell.onReturn = { [weak self] in
            self?.onTapDoneButton()
        }

        passphraseCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        subscribe(disposeBag, viewModel.indexViewItemDriver) { [weak self] in self?.sync(indexViewItem: $0) }
        subscribe(disposeBag, viewModel.firstWordCautionDriver) { [weak self] caution in
            self?.firstWordCell.set(cautionType: caution?.type)
            self?.firstWordCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.secondWordCautionDriver) { [weak self] caution in
            self?.secondWordCell.set(cautionType: caution?.type)
            self?.secondWordCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.passphraseCautionDriver) { [weak self] caution in
            self?.passphraseCell.set(cautionType: caution?.type)
            self?.passphraseCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.clearInputsSignal) { [weak self] in
            self?.firstWordCell.inputText = nil
            self?.secondWordCell.inputText = nil
            self?.passphraseCell.inputText = nil
        }
        subscribe(disposeBag, viewModel.successSignal) { [weak self] in
            HudHelper.instance.showSuccess()
            self?.dismiss(animated: true)
        }

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.onViewAppear()

        isLoaded = true

        if !isFirstShownKeyboard {
            _ = firstWordCell.becomeFirstResponder()
            isFirstShownKeyboard = true
        }
    }

    @objc private func onTapDoneButton() {
        viewModel.onTapDone()
    }

    private func onReturnSecondWord() {
        if viewModel.passphraseVisible {
            _ = passphraseCell.becomeFirstResponder()
        } else {
            onTapDoneButton()
        }
    }

    private func sync(indexViewItem: BackupConfirmKeyViewModel.IndexViewItem) {
        firstWordCell.set(index: indexViewItem.first)
        secondWordCell.set(index: indexViewItem.second)
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

extension BackupConfirmKeyViewController: SectionsDataSource {

    private func footer(text: String) -> ViewState<BottomDescriptionHeaderFooterView> {
        .cellType(
                hash: "bottom_description",
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { width in
                    BottomDescriptionHeaderFooterView.height(containerWidth: width, text: text)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "first-word",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin16),
                    rows: [
                        StaticRow(
                                cell: firstWordCell,
                                id: "first-word",
                                height: .heightSingleLineCell
                        ),
                        StaticRow(
                                cell: firstWordCautionCell,
                                id: "first-word-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.firstWordCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),
            Section(
                    id: "second-word",
                    footerState: footer(text: "backup_key.confirmation.description".localized),
                    rows: [
                        StaticRow(
                                cell: secondWordCell,
                                id: "second-word",
                                height: .heightSingleLineCell
                        ),
                        StaticRow(
                                cell: secondWordCautionCell,
                                id: "second-word-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.secondWordCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )
        ]

        if viewModel.passphraseVisible {
            let passphraseSection = Section(
                    id: "passphrase",
                    footerState: footer(text: "backup_key.confirmation.passphrase_description".localized),
                    rows: [
                        StaticRow(
                                cell: passphraseCell,
                                id: "passphrase",
                                height: .heightSingleLineCell
                        ),
                        StaticRow(
                                cell: passphraseCautionCell,
                                id: "passphrase-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.passphraseCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )

            sections.append(passphraseSection)
        }

        return sections
    }

}
