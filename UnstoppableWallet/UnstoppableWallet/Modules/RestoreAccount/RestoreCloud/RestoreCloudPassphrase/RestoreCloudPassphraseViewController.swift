import Combine
import SnapKit
import ThemeKit
import UIKit
import ComponentKit
import SectionsTableView
import UIExtensions

class RestoreCloudPassphraseViewController: KeyboardAwareViewController {
    private let wrapperViewHeight: CGFloat = .margin16 + .heightButton + .margin32

    private let viewModel: RestoreCloudPassphraseViewModel
    private var cancellables = Set<AnyCancellable>()

    private weak var returnViewController: UIViewController?

    private let tableView = SectionsTableView(style: .grouped)

    private let passphraseCell = PasswordInputCell()
    private let passphraseCautionCell = FormCautionCell()

    private let gradientWrapperView = GradientView(gradientHeight: .margin16, fromColor: UIColor.themeTyler.withAlphaComponent(0), toColor: UIColor.themeTyler)
    private let importButton = PrimaryButton()

    private var keyboardShown = false
    private var isLoaded = false

    init(viewModel: RestoreCloudPassphraseViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.returnViewController = returnViewController

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.cloud.password.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancel))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.largeTitleDisplayMode = .never

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

        gradientWrapperView.addSubview(importButton)
        importButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }

        show(processing: false)
        importButton.setTitle("button.import".localized, for: .normal)
        importButton.addTarget(self, action: #selector(onTapCreate), for: .touchUpInside)

        passphraseCell.set(textSecure: true)
        passphraseCell.onTextSecurityChange = { [weak self] in self?.passphraseCell.set(textSecure: $0) }
        passphraseCell.inputPlaceholder = "restore.cloud.password.placeholder".localized
        passphraseCell.onChangeText = { [weak self] in self?.viewModel.onChange(passphrase: $0 ?? "") }
        passphraseCell.isValidText = { [weak self] in self?.viewModel.validatePassphrase(text: $0) ?? true }

        passphraseCautionCell.onChangeHeight = { [weak self] in self?.onChangeHeight() }

        viewModel.$passphraseCaution
                .receive(on: DispatchQueue.main)
                .sink { [weak self] caution in
                    self?.passphraseCell.set(cautionType: caution?.type)
                    self?.passphraseCautionCell.set(caution: caution)
                }
                .store(in: &cancellables)

        viewModel.$processing
                .receive(on: DispatchQueue.main)
                .sink { [weak self] processing in
                    self?.show(processing: processing)
                }
                .store(in: &cancellables)

        viewModel.clearInputsPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.passphraseCell.inputText = nil
                }
                .store(in: &cancellables)

        viewModel.showErrorPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.show(error: $0)
                }
                .store(in: &cancellables)

        viewModel.openSelectCoinsPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] backupAccount in
                    self?.openSelectCoins(accountName: backupAccount.name, accountType: backupAccount.accountType, isManualBackedUp: backupAccount.isManualBackedUp)
                }
                .store(in: &cancellables)

        viewModel.successPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    HudHelper.instance.show(banner: .imported)
                    (self?.returnViewController ?? self)?.dismiss(animated: true)
                }
                .store(in: &cancellables)

        additionalContentInsets = UIEdgeInsets(top: 0, left: 0, bottom: wrapperViewHeight - .margin16, right: 0)

        showDefaultPassphrase()

        tableView.buildSections()
        isLoaded = true
    }

    override func viewDidAppear(_ animated: Bool) {
        if !keyboardShown {
            keyboardShown = true
            _ = passphraseCell.becomeFirstResponder()
        }

        super.viewDidAppear(animated)

        setInitialState(bottomPadding: gradientWrapperView.height)
    }

    private func showDefaultPassphrase() {
        let text = App.shared.appConfigProvider.defaultPassphrase
        guard !text.isEmpty else {
            return
        }

        passphraseCell.inputText = text
        viewModel.onChange(passphrase: text)
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapCreate() {
        viewModel.onTapImport()
    }

    private func show(processing: Bool) {
        if processing {
            importButton.set(style: .yellow, accessoryType: .spinner)
            importButton.isEnabled = false
        } else {
            importButton.set(style: .yellow)
            importButton.isEnabled = true
        }
    }

    private func show(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
    }

    private func openSelectCoins(accountName: String, accountType: AccountType, isManualBackedUp: Bool) {
        let viewController = RestoreSelectModule.viewController(
                accountName: accountName,
                accountType: accountType,
                isManualBackedUp: isManualBackedUp,
                returnViewController: returnViewController
        )
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension RestoreCloudPassphraseViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description-section",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.descriptionRow(
                                id: "description",
                                text: "restore.cloud.password.description".localized,
                                font: .subhead2,
                                textColor: .gray,
                                ignoreBottomMargin: true
                        )
                    ]
            ),
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
        ]
    }

}

extension RestoreCloudPassphraseViewController: IDynamicHeightCellDelegate {

    func onChangeHeight() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.endUpdates()
        }
    }

}
