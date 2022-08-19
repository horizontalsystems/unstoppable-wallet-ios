import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import RxSwift
import RxCocoa
import HUD
import ComponentKit
import UIExtensions

protocol ICreateAccountListener: UIViewController {
    func handleCreateAccount()
}

class CreateAccountViewController: KeyboardAwareViewController {
    private let wrapperViewHeight: CGFloat = .heightButton + .margin32 + .margin16
    private let viewModel: CreateAccountViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let mnemonicCell = BaseSelectableThemeCell()
    private let wordListCell = BaseSelectableThemeCell()
    private let passphraseToggleCell = BaseThemeCell()
    private let passphraseCell = TextFieldCell()
    private let passphraseCautionCell = FormCautionCell()
    private let passphraseConfirmationCell = TextFieldCell()
    private let passphraseConfirmationCautionCell = FormCautionCell()

    private let gradientWrapperView = GradientView(gradientHeight: .margin16, fromColor: UIColor.themeTyler.withAlphaComponent(0), toColor: UIColor.themeTyler)
    private let createButton = PrimaryButton()

    private var inputsVisible = false
    private var isLoaded = false

    private weak var listener: ICreateAccountListener?

    init(viewModel: CreateAccountViewModel, listener: ICreateAccountListener?) {
        self.viewModel = viewModel
        self.listener = listener

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "create_wallet.title".localized
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "create_wallet.create_button".localized, style: .done, target: self, action: #selector(onTapCreate))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        view.addSubview(gradientWrapperView)
        gradientWrapperView.snp.makeConstraints { maker in
            maker.height.equalTo(wrapperViewHeight).priority(.high)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        gradientWrapperView.addSubview(createButton)
        createButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }

        createButton.set(style: .yellow)
        createButton.setTitle("create_wallet.create_button".localized, for: .normal)
        createButton.addTarget(self, action: #selector(onTapCreate), for: .touchUpInside)

        mnemonicCell.set(backgroundStyle: .lawrence, isFirst: true)
        wordListCell.set(backgroundStyle: .lawrence, isLast: true)

        passphraseToggleCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        CellBuilderNew.buildStatic(
                cell: passphraseToggleCell,
                rootElement: .hStack([
                    .image20 { component in
                        component.imageView.image = UIImage(named: "key_phrase_20")?.withTintColor(.themeGray)
                    },
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = "create_wallet.passphrase".localized
                    },
                    .switch { [weak self] component in
                        component.onSwitch = {
                            self?.viewModel.onTogglePassphrase(isOn: $0)
                        }
                    }
                ])
        )

        passphraseCell.isSecureTextEntry = true
        passphraseCell.inputPlaceholder = "create_wallet.input.passphrase".localized
        passphraseCell.onChangeText = { [weak self] in self?.viewModel.onChange(passphrase: $0 ?? "") }

        passphraseCautionCell.onChangeHeight = { [weak self] in self?.syncCellHeights() }

        passphraseConfirmationCell.isSecureTextEntry = true
        passphraseConfirmationCell.inputPlaceholder = "create_wallet.input.confirm".localized
        passphraseConfirmationCell.onChangeText = { [weak self] in self?.viewModel.onChange(passphraseConfirmation: $0 ?? "") }

        passphraseConfirmationCautionCell.onChangeHeight = { [weak self] in self?.syncCellHeights() }

        subscribe(disposeBag, viewModel.wordCountDriver) { [weak self] in self?.syncMnemonicCell(wordCount: $0) }
        subscribe(disposeBag, viewModel.wordListDriver) { [weak self] in self?.syncWordListCell(wordList: $0) }
        subscribe(disposeBag, viewModel.inputsVisibleDriver) { [weak self] in self?.sync(inputsVisible: $0) }
        subscribe(disposeBag, viewModel.passphraseCautionDriver) { [weak self] caution in
            self?.passphraseCell.set(cautionType: caution?.type)
            self?.passphraseCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.passphraseConfirmationCautionDriver) { [weak self] caution in
            self?.passphraseConfirmationCell.set(cautionType: caution?.type)
            self?.passphraseConfirmationCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.clearInputsSignal) { [weak self] in
            self?.passphraseCell.inputText = nil
            self?.passphraseConfirmationCell.inputText = nil
        }
        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.finish() }

        setInitialState(bottomPadding: wrapperViewHeight)

        tableView.buildSections()
        isLoaded = true
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapCreate() {
        viewModel.onTapCreate()
    }

    private func sync(inputsVisible: Bool) {
        self.inputsVisible = inputsVisible

        view.endEditing(true)
        reloadTable()
    }

    private func openWordCountSelector() {
        let alertController = AlertRouter.module(title: "create_wallet.mnemonic".localized, viewItems: viewModel.wordCountViewItems) { [weak self] index in
            self?.viewModel.onSelectWordCount(index: index)
        }

        present(alertController, animated: true)
    }

    private func openWordListSelector() {
        let alertController = AlertRouter.module(title: "create_wallet.word_list".localized, viewItems: viewModel.wordListViewItems) { [weak self] index in
            self?.viewModel.onSelectWordList(index: index)
        }

        present(alertController, animated: true)
    }

    private func show(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
    }

    private func finish() {
        HudHelper.instance.show(banner: .created)

        if let listener = listener {
            listener.handleCreateAccount()
        } else {
            dismiss(animated: true)
        }
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload()
    }

    private func syncCellHeights() {
        guard isLoaded else {
            return
        }

        tableView.buildSections()
        tableView.beginUpdates()
        tableView.endUpdates()
    }

}

extension CreateAccountViewController: SectionsDataSource {

    private func sync(cell: BaseThemeCell, image: UIImage?, title: String, value: String) {
        CellBuilderNew.buildStatic(
                cell: cell,
                rootElement: .hStack([
                    .image20 { component in
                        component.imageView.image = image?.withTintColor(.themeGray)
                    },
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                    },
                    .text { component in
                        component.font = .subhead1
                        component.textColor = .themeLeah
                        component.text = value
                    },
                    .margin8,
                    .image20 { component in
                        component.imageView.image = UIImage(named: "arrow_small_down_20")?.withTintColor(.themeGray)
                    }
                ])
        )
    }

    private func syncMnemonicCell(wordCount: String) {
        sync(
                cell: mnemonicCell,
                image: UIImage(named: "key_20"),
                title: "create_wallet.mnemonic".localized,
                value: wordCount
        )
    }

    private func syncWordListCell(wordList: String) {
        sync(
                cell: wordListCell,
                image: UIImage(named: "globe_20"),
                title: "create_wallet.word_list".localized,
                value: wordList
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "mnemonic",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: mnemonicCell,
                                id: "mnemonic",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.openWordCountSelector()
                                }
                        ),
                        StaticRow(
                                cell: wordListCell,
                                id: "word-list",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.openWordListSelector()
                                }
                        )
                    ]
            ),
            Section(
                    id: "passphrase-toggle",
                    footerState: .margin(height: inputsVisible ? .margin24 : .margin32),
                    rows: [
                        StaticRow(
                                cell: passphraseToggleCell,
                                id: "passphrase-toggle",
                                height: .heightCell48
                        )
                    ]
            )
        ]

        if inputsVisible {
            let inputSections: [SectionProtocol] = [
                Section(
                        id: "passphrase",
                        footerState: .margin(height: .margin16),
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
                ),
                Section(
                        id: "passphrase-confirmation",
                        footerState: tableView.sectionFooter(text: "create_wallet.passphrase_description".localized),
                        rows: [
                            StaticRow(
                                    cell: passphraseConfirmationCell,
                                    id: "passphrase-confirmation",
                                    height: .heightSingleLineCell
                            ),
                            StaticRow(
                                    cell: passphraseConfirmationCautionCell,
                                    id: "passphrase-confirmation-caution",
                                    dynamicHeight: { [weak self] width in
                                        self?.passphraseConfirmationCautionCell.height(containerWidth: width) ?? 0
                                    }
                            )
                        ]
                )
            ]

            sections.append(contentsOf: inputSections)
        }

        return sections
    }

}
