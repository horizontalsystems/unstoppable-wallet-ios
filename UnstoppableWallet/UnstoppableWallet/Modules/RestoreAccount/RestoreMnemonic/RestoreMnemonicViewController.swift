import Foundation
import UIKit
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
    private let mnemonicCautionCell = FormCautionCell()

    private let passphraseToggleCell = BaseThemeCell()
    private let passphraseCell = TextFieldCell()
    private let passphraseCautionCell = FormCautionCell()

    private let hintView = RestoreMnemonicHintView()

    private var inputsVisible = false
    private var isLoaded = false
    private var isFirstShownKeyboard = false

    private weak var returnViewController: UIViewController?

    init(viewModel: RestoreMnemonicViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .done, target: self, action: #selector(onTapProceedButton))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        mnemonicInputCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        mnemonicInputCell.onChangeText = { [weak self] in self?.viewModel.onChange(text: $0, cursorOffset: $1, language: $2) }
        mnemonicInputCell.onChangeTextViewCaret = { [weak self] in self?.syncContentOffsetIfRequired(textView: $0) }
        mnemonicInputCell.onChangeEntering = { [weak self] in self?.syncHintView() }

        mnemonicCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        passphraseToggleCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        CellBuilder.build(cell: passphraseToggleCell, elements: [.image20, .text, .switch])
        passphraseToggleCell.bind(index: 0) { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "key_phrase_20")
        }
        passphraseToggleCell.bind(index: 1) { (component: TextComponent) in
            component.font = .body
            component.textColor = .themeLeah
            component.text = "restore.passphrase".localized
        }
        passphraseToggleCell.bind(index: 2) { (component: SwitchComponent) in
            component.onSwitch = { [weak self] in
                self?.viewModel.onTogglePassphrase(isOn: $0)
            }
        }

        passphraseCell.isSecureTextEntry = true
        passphraseCell.inputPlaceholder = "restore.input.passphrase".localized
        passphraseCell.onChangeText = { [weak self] in self?.viewModel.onChange(passphrase: $0 ?? "") }

        passphraseCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        view.addSubview(hintView)
        hintView.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell).priority(.high)
        }

        hintView.onSelectWord = { [weak self] word in
            self?.viewModel.onSelect(word: word)
        }

        subscribe(disposeBag, viewModel.possibleWordsDriver) { [weak self] in
            self?.hintView.set(words: $0)
            self?.syncHintView()
        }
        subscribe(disposeBag, viewModel.invalidRangesDriver) { [weak self] in self?.mnemonicInputCell.set(invalidRanges: $0) }
        subscribe(disposeBag, viewModel.replaceWordSignal) { [weak self] in self?.mnemonicInputCell.replaceWord(range: $0, word: $1) }
        subscribe(disposeBag, viewModel.showErrorSignal) { HudHelper.instance.show(banner: .error(string: $0)) }
        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] in self?.openSelectCoins(accountType: $0) }
        subscribe(disposeBag, viewModel.inputsVisibleDriver) { [weak self] in self?.sync(inputsVisible: $0) }
        subscribe(disposeBag, viewModel.passphraseCautionDriver) { [weak self] caution in
            self?.passphraseCell.set(cautionType: caution?.type)
            self?.passphraseCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.mnemonicCautionDriver) { [weak self] caution in
            self?.mnemonicInputCell.set(cautionType: caution?.type)
            self?.mnemonicCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.clearInputsSignal) { [weak self] in self?.passphraseCell.inputText = nil }
        subscribe(disposeBag, keyboardVisibilityDriver) { [weak self] in self?.update(keyboardVisibility: $0) }

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

    private func update(keyboardVisibility: CGFloat) {
        hintView.alpha = keyboardVisibility
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    @objc private func onTapProceedButton() {
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

    private func showDefaultWords() {
        let text = App.shared.appConfigProvider.defaultWords + " "
        mnemonicInputCell.set(text: text)
    }

    private func openSelectCoins(accountType: AccountType) {
        let viewController = RestoreSelectModule.viewController(accountType: accountType, returnViewController: returnViewController)
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

    func buildSections() -> [SectionProtocol] {
        [
            Section(id: "top-margin", headerState: .margin(height: .margin12)),
            Section(
                    id: "mnemonic-input",
                    headerState: tableView.sectionHeader(text: "restore.mnemonic.key".localized),
                    footerState: tableView.sectionFooter(text: "restore.mnemonic.description".localized),
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
                    footerState: inputsVisible ? tableView.sectionFooter(text: "restore.passphrase_description".localized) : .margin(height: 0),
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
