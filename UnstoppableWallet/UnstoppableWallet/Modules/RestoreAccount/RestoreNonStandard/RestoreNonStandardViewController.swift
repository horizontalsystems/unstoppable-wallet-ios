import Foundation
import UIKit
import ThemeKit
import RxSwift
import RxCocoa
import SectionsTableView
import SnapKit
import ComponentKit
import UIExtensions

class RestoreNonStandardViewController: KeyboardAwareViewController {
    private let viewModel: RestoreNonStandardViewModel
    private let mnemonicViewModel: RestoreMnemonicNonStandardViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let gradientWrapperView = BottomGradientHolder()
    private let nextButton = PrimaryButton()

    private let nameCell = TextFieldCell()

    private let mnemonicInputCell = MnemonicInputCell()
    private let mnemonicCautionCell = FormCautionCell()
    private let wordListCell = BaseSelectableThemeCell()

    private let passphraseToggleCell = BaseThemeCell()
    private let passphraseCell = PasswordInputCell()
    private let passphraseCautionCell = FormCautionCell()
    private let passphraseDescriptionCell = HighlightedDescriptionCell()

    private let hintView = RestoreMnemonicHintView()

    private var inputsVisible = false
    private var isLoaded = false

    private weak var returnViewController: UIViewController?

    init(viewModel: RestoreNonStandardViewModel, mnemonicViewModel: RestoreMnemonicNonStandardViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.mnemonicViewModel = mnemonicViewModel
        self.returnViewController = returnViewController

        super.init(scrollViews: [tableView], accessoryView: hintView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.non_standard_import".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .done, target: self, action: #selector(onTapNext))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: DescriptionCell.self)

        gradientWrapperView.add(to: self)
        gradientWrapperView.addSubview(nextButton)

        nextButton.set(style: .yellow)
        nextButton.setTitle("button.next".localized, for: .normal)
        nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)

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
                            value: .subhead1(wordListLanguage, color: .themeGray),
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

}

extension RestoreNonStandardViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let descriptionText = "restore.non_standard_import.description".localized(AppConfig.appName, AppConfig.appName)
        var sections: [SectionProtocol] = [
            Section(
                    id: "description",
                    headerState: .margin(height: 3),
                    footerState: .margin(height: .margin32),
                    rows: [
                        Row<DescriptionCell>(
                                id: "description",
                                dynamicHeight: { containerWidth in
                                    DescriptionCell.height(containerWidth: containerWidth, text: descriptionText, font: .subhead2, ignoreBottomMargin: true)
                                },
                                bind: { cell, _ in
                                    cell.label.text = descriptionText
                                    cell.label.font = .subhead2
                                    cell.label.textColor = .themeGray
                                }
                        )
                    ]
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

        let mnemonicSections: [SectionProtocol] = [
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
            ),
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
                    footerState: inputsVisible ? .margin(height: .margin24) : .margin(height: 0),
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
            )
        ]

        sections.append(contentsOf: mnemonicSections)

        return sections
    }

}
