import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import RxSwift
import RxCocoa
import HUD
import ComponentKit

class CreateAccountViewController: KeyboardAwareViewController {
    private let viewModel: CreateAccountViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let mnemonicCell = BaseSelectableThemeCell()
    private let passphraseToggleCell = BaseSelectableThemeCell()
    private let passphraseCell = TextFieldCell()
    private let passphraseCautionCell = FormCautionCell()
    private let passphraseConfirmationCell = TextFieldCell()
    private let passphraseConfirmationCautionCell = FormCautionCell()

    private var inputsVisible = false
    private var isLoaded = false

    init(viewModel: CreateAccountViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView])
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
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)

        mnemonicCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        CellBuilder.build(cell: mnemonicCell, elements: [.image20, .text, .text, .image20])
        mnemonicCell.bind(index: 0) { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "key_20")
        }
        mnemonicCell.bind(index: 1) { (component: TextComponent) in
            component.set(style: .b2)
            component.text = "create_wallet.mnemonic".localized
        }
        mnemonicCell.bind(index: 2) { (component: TextComponent) in
            component.set(style: .c2)
        }
        mnemonicCell.bind(index: 3) { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "arrow_small_down_20")
        }

        passphraseToggleCell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
        CellBuilder.build(cell: passphraseToggleCell, elements: [.image20, .text, .switch])
        passphraseToggleCell.bind(index: 0) { (component: ImageComponent) in
            component.imageView.image = UIImage(named: "key_phrase_20")
        }
        passphraseToggleCell.bind(index: 1) { (component: TextComponent) in
            component.set(style: .b2)
            component.text = "create_wallet.passphrase".localized
        }
        passphraseToggleCell.bind(index: 2) { (component: SwitchComponent) in
            component.onSwitch = { [weak self] in
                self?.viewModel.onTogglePassphrase(isOn: $0)
            }
        }

        passphraseCell.inputPlaceholder = "create_wallet.input.passphrase".localized
        passphraseCell.onChangeText = { [weak self] in self?.viewModel.onChange(passphrase: $0 ?? "") }
        passphraseCell.isValidText = { [weak self] in self?.viewModel.validatePassphrase(text: $0) ?? true }

        passphraseCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        passphraseConfirmationCell.inputPlaceholder = "create_wallet.input.confirm".localized
        passphraseConfirmationCell.onChangeText = { [weak self] in self?.viewModel.onChange(passphraseConfirmation: $0 ?? "") }
        passphraseConfirmationCell.isValidText = { [weak self] in self?.viewModel.validatePassphraseConfirmation(text: $0) ?? true }

        passphraseConfirmationCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        subscribe(disposeBag, viewModel.kindDriver) { [weak self] kind in
            self?.mnemonicCell.bind(index: 2) { (component: TextComponent) in
                component.text = kind
            }
        }
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
        subscribe(disposeBag, viewModel.openSelectKindSignal) { [weak self] in self?.openSelectKind(viewItems: $0) }
        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.finish() }

        tableView.buildSections()
        isLoaded = true
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    @objc private func onTapCreateButton() {
        viewModel.onTapCreate()
    }

    private func sync(inputsVisible: Bool) {
        self.inputsVisible = inputsVisible

        view.endEditing(true)
        reloadTable()
    }

    private func openSelectKind(viewItems: [AlertViewItem]) {
        let alertController = AlertRouter.module(title: "create_wallet.mnemonic".localized, viewItems: viewItems) { [weak self] index in
            self?.viewModel.onSelectKind(index: index)
        }

        present(alertController, animated: true)
    }

    private func show(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
    }

    private func finish() {
        HudHelper.instance.show(banner: .created)
        dismiss(animated: true)
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

extension CreateAccountViewController: SectionsDataSource {

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
                    id: "mnemonic",
                    headerState: .margin(height: .margin12),
                    rows: [
                        StaticRow(
                                cell: mnemonicCell,
                                id: "mnemonic",
                                height: .heightCell48,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.viewModel.onTapKind()
                                }
                        )
                    ]
            ),
            Section(
                    id: "passphrase-toggle",
                    headerState: .margin(height: .margin32),
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
                    footerState: .margin(height: inputsVisible ? .margin16 : .margin12),
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
            ),
            Section(
                    id: "passphrase-confirmation",
                    footerState: inputsVisible ? footer(text: "create_wallet.passphrase_description".localized) : .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: passphraseConfirmationCell,
                                id: "passphrase-confirmation",
                                height: inputsVisible ? .heightSingleLineCell : 0
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
    }

}
