import Foundation
import UIKit
import ThemeKit
import RxSwift
import RxCocoa
import SectionsTableView
import SnapKit
import ComponentKit
import UIExtensions

class RestoreViewController: KeyboardAwareViewController {
    private let advanced: Bool
    private let viewModel: RestoreViewModel
    private let mnemonicViewModel: RestoreMnemonicViewModel
    private let privateKeyViewModel: RestorePrivateKeyViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let nameCell = TextFieldCell()

    private let mnemonicInputCell = MnemonicInputCell()
    private let mnemonicCautionCell = FormCautionCell()
    private let wordListCell = BaseSelectableThemeCell()

    private let passphraseToggleCell = BaseThemeCell()
    private let passphraseCell = PasswordInputCell()
    private let passphraseCautionCell = FormCautionCell()
    private let passphraseDescriptionCell = HighlightedDescriptionCell()

    private let hintView = RestoreMnemonicHintView()

    private let privateKeyInputCell = TextInputCell()
    private let privateKeyCautionCell = FormCautionCell()

    private var restoreType: RestoreViewModel.RestoreType = .mnemonic
    private var inputsVisible = false
    private var isLoaded = false

    private weak var returnViewController: UIViewController?

    init(advanced: Bool, viewModel: RestoreViewModel, mnemonicViewModel: RestoreMnemonicViewModel, privateKeyViewModel: RestorePrivateKeyViewModel, returnViewController: UIViewController?) {
        self.advanced = advanced
        self.viewModel = viewModel
        self.mnemonicViewModel = mnemonicViewModel
        self.privateKeyViewModel = privateKeyViewModel
        self.returnViewController = returnViewController

        super.init(scrollViews: [tableView], accessoryView: hintView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .done, target: self, action: #selector(onTapNext))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        let gradientWrapperView = BottomGradientHolder()
        gradientWrapperView.add(to: self)

        let nextButton = PrimaryButton()
        gradientWrapperView.addSubview(nextButton)

        nextButton.set(style: .yellow)
        nextButton.setTitle("button.next".localized, for: .normal)
        nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)

        if !advanced {
            let advancedButton = PrimaryButton()
            gradientWrapperView.addSubview(advancedButton)

            advancedButton.set(style: .transparent)
            advancedButton.setTitle("restore.advanced".localized, for: .normal)
            advancedButton.addTarget(self, action: #selector(onTapAdvanced), for: .touchUpInside)
        }

        let namePlaceholder = viewModel.namePlaceholder
        nameCell.inputText = namePlaceholder
        nameCell.inputPlaceholder = namePlaceholder
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0 ?? "") }

        mnemonicInputCell.set(placeholderText: "restore.mnemonic.placeholder".localized)
        mnemonicInputCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        mnemonicInputCell.onChangeMnemonicText = { [weak self] in self?.mnemonicViewModel.onChange(text: $0, cursorOffset: $1) }
        mnemonicInputCell.onChangeTextViewCaret = { [weak self] in self?.syncContentOffsetIfRequired(textView: $0) }
        mnemonicInputCell.onChangeEntering = { [weak self] in self?.syncHintView() }
        mnemonicInputCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        mnemonicCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        wordListCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: false)
        passphraseToggleCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
        CellBuilderNew.buildStatic(
                cell: passphraseToggleCell,
                rootElement: .hStack(
                        tableView.universalImage24Elements(
                                image: .local(UIImage(named: "key_phrase_24")?.withTintColor(.themeGray)),
                                title: .body("restore.passphrase".localized),
                                accessoryType: .switch { [weak self] in
                                    self?.mnemonicViewModel.onTogglePassphrase(isOn: $0)
                                }
                        )
                )
        )

        passphraseCell.set(textSecure: true)
        passphraseCell.onTextSecurityChange = { [weak self] in self?.passphraseCell.set(textSecure: $0) }
        passphraseCell.inputPlaceholder = "restore.input.passphrase".localized
        passphraseCell.onChangeText = { [weak self] in self?.mnemonicViewModel.onChange(passphrase: $0 ?? "") }

        passphraseCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        passphraseDescriptionCell.descriptionText = "restore.passphrase_description".localized

        view.addSubview(hintView)
        hintView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell).priority(.high)
        }

        hintView.onSelectWord = { [weak self] word in
            self?.mnemonicViewModel.onSelect(word: word)
        }

        privateKeyInputCell.set(placeholderText: "restore.private_key.placeholder".localized)
        privateKeyInputCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        privateKeyInputCell.onChangeText = { [weak self] in self?.privateKeyViewModel.onChange(text: $0) }
        privateKeyInputCell.onChangeTextViewCaret = { [weak self] in self?.syncContentOffsetIfRequired(textView: $0) }
        privateKeyInputCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        privateKeyCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        subscribe(disposeBag, viewModel.restoreTypeDriver) { [weak self] restoreType in
            self?.restoreType = restoreType
            self?.tableView.reload()
        }
        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] in self?.openSelectCoins(accountName: $0, accountType: $1) }
        subscribe(disposeBag, mnemonicViewModel.possibleWordsDriver) { [weak self] in
            self?.hintView.set(words: $0)
            self?.syncHintView()
        }
        subscribe(disposeBag, mnemonicViewModel.invalidRangesDriver) { [weak self] in self?.mnemonicInputCell.set(invalidRanges: $0) }
        subscribe(disposeBag, mnemonicViewModel.replaceWordSignal) { [weak self] in self?.mnemonicInputCell.replaceWord(range: $0, word: $1) }
        subscribe(disposeBag, mnemonicViewModel.inputsVisibleDriver) { [weak self] in self?.sync(inputsVisible: $0) }
        subscribe(disposeBag, mnemonicViewModel.wordListLanguageDriver) { [weak self] in self?.syncWordListLanguageCell(wordListLanguage: $0) }
        subscribe(disposeBag, mnemonicViewModel.passphraseCautionDriver) { [weak self] caution in
            self?.passphraseCell.set(cautionType: caution?.type)
            self?.passphraseCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, mnemonicViewModel.mnemonicCautionDriver) { [weak self] caution in
            self?.mnemonicInputCell.set(cautionType: caution?.type)
            self?.mnemonicCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, mnemonicViewModel.clearInputsSignal) { [weak self] in self?.passphraseCell.inputText = nil }
        subscribe(disposeBag, privateKeyViewModel.cautionDriver) { [weak self] caution in
            self?.privateKeyInputCell.set(cautionType: caution?.type)
            self?.privateKeyCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, keyboardVisibilityDriver) { [weak self] in self?.update(keyboardVisibility: $0) }

        showDefaultWords()

        tableView.buildSections()
        isLoaded = true
    }

    private func update(keyboardVisibility: CGFloat) {
        hintView.alpha = keyboardVisibility
    }

    @objc private func onTapNext() {
        viewModel.onTapProceed()
    }

    @objc private func onTapAdvanced() {
        let module = RestoreModule.viewController(advanced: true, returnViewController: returnViewController)
        navigationController?.pushViewController(module, animated: true)
    }

    private func syncHintView() {
        let hideHint = !mnemonicInputCell.entering

        showAccessoryView = !hideHint
        hintView.isHidden = hideHint
        setInitialState(bottomPadding: hideHint ? 0 : hintView.height)
    }

    private func sync(inputsVisible: Bool) {
        self.inputsVisible = inputsVisible

        passphraseCell.endEditing(true)
        reloadTable()
    }

    private func syncWordListLanguageCell(wordListLanguage: String) {
        CellBuilderNew.buildStatic(
                cell: wordListCell,
                rootElement: .hStack(
                        tableView.universalImage24Elements(
                                image: .local(UIImage(named: "globe_24")?.withTintColor(.themeGray)),
                                title: .body("create_wallet.word_list".localized),
                                value: .subhead1(wordListLanguage),
                                accessoryType: .dropdown
                        )
                )
        )

        mnemonicInputCell.set(text: mnemonicInputCell.textView.text)
    }

    private func showDefaultWords() {
        let text = AppConfig.defaultWords
        mnemonicInputCell.set(text: text)
    }

    private func openSelectCoins(accountName: String, accountType: AccountType) {
        let viewController = RestoreSelectModule.viewController(accountName: accountName, accountType: accountType, returnViewController: returnViewController)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openWordListSelector() {
        let alertController = AlertRouter.module(title: "create_wallet.word_list".localized, viewItems: mnemonicViewModel.wordListViewItems) { [weak self] index in
            self?.mnemonicViewModel.onSelectWordList(index: index)
        }

        present(alertController, animated: true)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.buildSections()
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func onTapRestoreType() {
        let alertController = AlertRouter.module(
                title: "restore.import_by".localized,
                viewItems: RestoreViewModel.RestoreType.allCases.enumerated().map { index, restoreType in
                    AlertViewItem(
                            text: restoreType.title,
                            selected: self.restoreType == restoreType
                    )
                }
        ) { [weak self] index in
            self?.viewModel.onSelect(restoreType: RestoreViewModel.RestoreType.allCases[index])
        }

        present(alertController, animated: true)
    }

    private func onTapNonStandardRestore() {
        let viewController = RestoreNonStandardModule.viewController(sourceViewController: self, returnViewController: returnViewController)
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension RestoreViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "margin",
                    headerState: .margin(height: .margin12)
            ),
            Section(
                    id: "name",
                    headerState: tableView.sectionHeader(text: "create_wallet.name".localized),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: nameCell,
                                id: "name",
                                height: .heightSingleLineCell
                        )
                    ]
            )
        ]

        if advanced {
            sections.append(
                    Section(
                            id: "restore-type",
                            footerState: .margin(height: .margin32),
                            rows: [
                                tableView.universalRow48(
                                        id: "restore_type",
                                        title: .body("restore.import_by".localized),
                                        value: .subhead1(restoreType.title),
                                        accessoryType: .dropdown,
                                        autoDeselect: true,
                                        isFirst: true,
                                        isLast: true
                                ) { [weak self] in
                                    self?.onTapRestoreType()
                                }
                            ]
                    )
            )
        }

        switch restoreType {
        case .mnemonic:
            sections.append(
                    Section(
                            id: "mnemonic-input",
                            footerState: .margin(height: .margin32),
                            rows: [
                                StaticRow(
                                        cell: mnemonicInputCell,
                                        id: "mnemonic-input",
                                        dynamicHeight: { [weak self] width in
                                            self?.mnemonicInputCell.cellHeight(containerWidth: width) ?? 0
                                        }
                                ),
                                StaticRow(
                                        cell: mnemonicCautionCell,
                                        id: "mnemonic-caution",
                                        dynamicHeight: { [weak self] width in
                                            self?.mnemonicCautionCell.height(containerWidth: width) ?? 0
                                        }
                                )
                            ]
                    )
            )

            if advanced {
                let advancedSections: [SectionProtocol] = [
                    Section(
                            id: "wordlist-passphrase-toggle",
                            footerState: .margin(height: .margin32),
                            rows: [
                                StaticRow(
                                        cell: wordListCell,
                                        id: "word-list",
                                        height: .heightCell48,
                                        autoDeselect: true,
                                        action: { [weak self] in
                                            self?.openWordListSelector()
                                        }
                                ),
                                StaticRow(
                                        cell: passphraseToggleCell,
                                        id: "passphrase-toggle",
                                        height: .heightCell48
                                )
                            ]
                    ),
                    Section(
                            id: "passphrase",
                            footerState: inputsVisible ? .margin(height: .margin32) : .margin(height: 0),
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
                                ),
                                StaticRow(
                                       cell: passphraseDescriptionCell,
                                       id: "passphrase-description",
                                       dynamicHeight: { [weak self] width in
                                           self.flatMap { $0.inputsVisible ? $0.passphraseDescriptionCell.height(containerWidth: width) : 0 } ?? 0
                                       }
                                )
                            ]
                    ),
                    Section(
                            id: "non-standard-restore",
                            footerState: .margin(height: .margin32),
                            rows: [
                                tableView.universalRow48(
                                        id: "non-standard_restore",
                                        title: .body("restore.non_standard_import".localized),
                                        accessoryType: .disclosure,
                                        autoDeselect: true,
                                        isFirst: true,
                                        isLast: true,
                                        action: { [weak self] in
                                            self?.onTapNonStandardRestore()
                                        }
                                )
                            ]
                    )
                ]

                sections.append(contentsOf: advancedSections)
            }
        case .privateKey:
            sections.append(
                    Section(
                            id: "private-key-input",
                            footerState: .margin(height: .margin32),
                            rows: [
                                StaticRow(
                                        cell: privateKeyInputCell,
                                        id: "private-key-input",
                                        dynamicHeight: { [weak self] width in
                                            self?.privateKeyInputCell.cellHeight(containerWidth: width) ?? 0
                                        }
                                ),
                                StaticRow(
                                        cell: privateKeyCautionCell,
                                        id: "private-key-caution",
                                        dynamicHeight: { [weak self] width in
                                            self?.privateKeyCautionCell.height(containerWidth: width) ?? 0
                                        }
                                )
                            ]
                    )
            )
        }

        return sections
    }

}
