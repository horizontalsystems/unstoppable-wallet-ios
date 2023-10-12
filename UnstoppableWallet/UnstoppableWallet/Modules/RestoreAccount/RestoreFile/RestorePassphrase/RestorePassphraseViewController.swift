import Combine
import ComponentKit
import SectionsTableView
import SnapKit
import ThemeKit
import UIExtensions
import UIKit

class RestorePassphraseViewController: KeyboardAwareViewController {
    private let viewModel: RestorePassphraseViewModel
    private var cancellables = Set<AnyCancellable>()

    private weak var returnViewController: UIViewController?

    private let tableView = SectionsTableView(style: .grouped)

    private let passphraseCell = PasswordInputCell()
    private let passphraseCautionCell = FormCautionCell()

    private let gradientWrapperView = BottomGradientHolder()
    private let nextButton = PrimaryButton()

    private var keyboardShown = false
    private var isLoaded = false

    init(viewModel: RestorePassphraseViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.returnViewController = returnViewController

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder _: NSCoder) {
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

        gradientWrapperView.add(to: self)
        gradientWrapperView.addSubview(nextButton)

        show(processing: false)
        nextButton.setTitle(viewModel.buttonTitle, for: .normal)
        nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)

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
            .sink { [weak self] account in
                self?.openSelectCoins(
                    accountName: account.name,
                    accountType: account.type,
                    isManualBackedUp: account.backedUp,
                    isFileBackedUp: account.fileBackedUp
                )
            }
            .store(in: &cancellables)

        viewModel.openConfigurationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.openConfiguration(rawBackup: $0) }
            .store(in: &cancellables)

        viewModel.successPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                HudHelper.instance.show(banner: .imported)
                (self?.returnViewController ?? self)?.dismiss(animated: true)
            }
            .store(in: &cancellables)

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
    }

    private func showDefaultPassphrase() {
        let text = AppConfig.defaultPassphrase
        guard !text.isEmpty else {
            return
        }

        passphraseCell.inputText = text
        viewModel.onChange(passphrase: text)
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapNext() {
        viewModel.onTapNext()
    }

    private func show(processing: Bool) {
        if processing {
            nextButton.set(style: .yellow, accessoryType: .spinner)
            nextButton.isEnabled = false
        } else {
            nextButton.set(style: .yellow)
            nextButton.isEnabled = true
        }
    }

    private func show(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
    }

    private func openSelectCoins(accountName: String, accountType: AccountType, isManualBackedUp: Bool, isFileBackedUp: Bool) {
        let viewController = RestoreSelectModule.viewController(
            accountName: accountName,
            accountType: accountType,
            isManualBackedUp: isManualBackedUp,
            isFileBackedUp: isFileBackedUp,
            returnViewController: returnViewController
        )
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openConfiguration(rawBackup: RawFullBackup) {
        let viewController = RestoreFileConfigurationModule.viewController(rawBackup: rawBackup, returnViewController: returnViewController)
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension RestorePassphraseViewController: SectionsDataSource {
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
                    ),
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
                    ),
                ]
            ),
        ]
    }
}

extension RestorePassphraseViewController: IDynamicHeightCellDelegate {
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
