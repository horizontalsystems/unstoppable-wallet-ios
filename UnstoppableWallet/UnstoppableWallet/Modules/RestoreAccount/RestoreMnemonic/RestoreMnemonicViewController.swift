import ThemeKit
import RxSwift
import RxCocoa
import SectionsTableView
import SnapKit
import ComponentKit

class RestoreMnemonicViewController: KeyboardAwareViewController {
    private let viewModel: RestoreMnemonicViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let mnemonicInputCell = MnemonicInputCell()
    private let passphraseToggleCell = A11Cell()
    private let passphraseCell = TextFieldCell()
    private let passphraseCautionCell = FormCautionCell()

    private var inputsVisible = false
    private var isLoaded = false
    private var isFirstShownKeyboard = false

    init(viewModel: RestoreMnemonicViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.enter_key".localized
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .done, target: self, action: #selector(onTapProceedButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        mnemonicInputCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        mnemonicInputCell.onChangeText = { [weak self] in self?.viewModel.onChange(text: $0, cursorOffset: $1) }
        mnemonicInputCell.onChangeTextViewCaret = { [weak self] in self?.syncContentOffsetIfRequired(textView: $0) }

        passphraseToggleCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        passphraseToggleCell.titleImage = UIImage(named: "key_phrase_20")
        passphraseToggleCell.title = "restore.passphrase".localized
        passphraseToggleCell.onToggle = { [weak self] in self?.viewModel.onTogglePassphrase(isOn: $0) }

        passphraseCell.inputPlaceholder = "restore.input.passphrase".localized
        passphraseCell.onChangeText = { [weak self] in self?.viewModel.onChange(passphrase: $0 ?? "") }
        passphraseCell.isValidText = { [weak self] in self?.viewModel.validatePassphrase(text: $0) ?? true }

        passphraseCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        subscribe(disposeBag, viewModel.invalidRangesDriver) { [weak self] in self?.mnemonicInputCell.set(invalidRanges: $0) }
        subscribe(disposeBag, viewModel.showErrorSignal) { HudHelper.instance.showError(title: $0) }
        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] in self?.openSelectCoins(accountType: $0) }
        subscribe(disposeBag, viewModel.inputsVisibleDriver) { [weak self] in self?.sync(inputsVisible: $0) }
        subscribe(disposeBag, viewModel.passphraseCautionDriver) { [weak self] caution in
            self?.passphraseCell.set(cautionType: caution?.type)
            self?.passphraseCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.clearInputsSignal) { [weak self] in self?.passphraseCell.inputText = nil }

        showDefaultWords()

        tableView.buildSections()
        isLoaded = true
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !isFirstShownKeyboard {
            DispatchQueue.main.async  {
                _ = self.mnemonicInputCell.becomeFirstResponder()
            }

            isFirstShownKeyboard = true
        }
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    @objc private func onTapProceedButton() {
        viewModel.onTapProceed()
    }

    private func sync(inputsVisible: Bool) {
        self.inputsVisible = inputsVisible

        passphraseCell.endEditing(true)
        reloadTable()
    }

    private func showDefaultWords() {
        let text = App.shared.appConfigProvider.defaultWords
        mnemonicInputCell.set(text: text)
    }

    private func openSelectCoins(accountType: AccountType) {
        let viewController = RestoreSelectModule.viewController(accountType: accountType)
        navigationController?.pushViewController(viewController, animated: true)
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

extension RestoreMnemonicViewController: SectionsDataSource {

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
        [
            Section(
                    id: "mnemonic-input",
                    headerState: .margin(height: .margin12),
                    footerState: footer(text: "restore.mnemonic.description".localized),
                    rows: [
                        StaticRow(
                                cell: mnemonicInputCell,
                                id: "mnemonic-input",
                                dynamicHeight: { [weak self] width in
                                    self?.mnemonicInputCell.cellHeight(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),
            Section(
                    id: "passphrase-toggle",
                    footerState: .margin(height: .margin24),
                    rows: [
                        StaticRow(
                                cell: passphraseToggleCell,
                                id: "passphrase-toggle",
                                height: .heightCell48
                        )
                    ]
            ),
            Section(
                    id: "passphrase",
                    footerState: inputsVisible ? footer(text: "restore.passphrase_description".localized) : .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: passphraseCell,
                                id: "passphrase",
                                height: inputsVisible ? .heightSingleLineCell : 0
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
        ]
    }

}
