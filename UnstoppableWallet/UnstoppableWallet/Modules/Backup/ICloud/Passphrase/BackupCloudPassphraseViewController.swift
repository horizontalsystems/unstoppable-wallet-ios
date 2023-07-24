import Combine
import SnapKit
import ThemeKit
import UIKit
import ComponentKit
import SectionsTableView
import UIExtensions

class BackupCloudPassphraseViewController: KeyboardAwareViewController {
    private let viewModel: BackupCloudPassphraseViewModel
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)

    private let passphraseCell = PasswordInputCell()
    private let passphraseCautionCell = FormCautionCell()

    private let passphraseConfirmationCell = PasswordInputCell()
    private let passphraseConfirmationCautionCell = FormCautionCell()

    private let passphraseDescriptionCell = HighlightedDescriptionCell()

    private let gradientWrapperView = BottomGradientHolder()
    private let saveButton = PrimaryButton()

    private var keyboardShown = false
    private var isLoaded = false

    init(viewModel: BackupCloudPassphraseViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.cloud.password.title".localized
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
        gradientWrapperView.addSubview(saveButton)

        show(processing: false)
        saveButton.setTitle("backup.cloud.password.save".localized, for: .normal)
        saveButton.addTarget(self, action: #selector(onTapCreate), for: .touchUpInside)

        passphraseCell.set(textSecure: true)
        passphraseCell.onTextSecurityChange = { [weak self] in self?.passphraseCell.set(textSecure: $0) }
        passphraseCell.inputPlaceholder = "backup.cloud.password.placeholder".localized
        passphraseCell.onChangeText = { [weak self] in self?.viewModel.onChange(passphrase: $0 ?? "") }
        passphraseCell.isValidText = { [weak self] in self?.viewModel.validatePassphrase(text: $0) ?? true }

        passphraseConfirmationCell.set(textSecure: true)
        passphraseConfirmationCell.onTextSecurityChange = { [weak self] in self?.passphraseConfirmationCell.set(textSecure: $0) }
        passphraseConfirmationCell.inputPlaceholder = "backup.cloud.password.confirm.placeholder".localized
        passphraseConfirmationCell.onChangeText = { [weak self] in self?.viewModel.onChange(passphraseConfirmation: $0 ?? "") }
        passphraseConfirmationCell.isValidText = { [weak self] in self?.viewModel.validatePassphraseConfirmation(text: $0) ?? true }

        passphraseCautionCell.onChangeHeight = { [weak self] in self?.onChangeHeight() }
        passphraseConfirmationCautionCell.onChangeHeight = { [weak self] in self?.onChangeHeight() }

        passphraseDescriptionCell.descriptionText = "restore.passphrase_description".localized

        viewModel.$passphraseCaution
                .receive(on: DispatchQueue.main)
                .sink { [weak self] caution in
                    self?.passphraseCell.set(cautionType: caution?.type)
                    self?.passphraseCautionCell.set(caution: caution)
                }
                .store(in: &cancellables)

        viewModel.$passphraseConfirmationCaution
                .receive(on: DispatchQueue.main)
                .sink { [weak self] caution in
                    self?.passphraseConfirmationCell.set(cautionType: caution?.type)
                    self?.passphraseConfirmationCautionCell.set(caution: caution)
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
                    self?.passphraseConfirmationCell.inputText = nil
                }
                .store(in: &cancellables)

        viewModel.showErrorPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.show(error: $0)
                }
                .store(in: &cancellables)

        viewModel.finishPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.finish()
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
        passphraseConfirmationCell.inputText = text
        viewModel.onChange(passphraseConfirmation: text)
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapCreate() {
        viewModel.onTapCreate()
    }

    private func show(processing: Bool) {
        if processing {
            saveButton.set(style: .yellow, accessoryType: .spinner)
            saveButton.isEnabled = false
        } else {
            saveButton.set(style: .yellow)
            saveButton.isEnabled = true
        }
    }

    private func show(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
    }

    private func finish() {
        HudHelper.instance.show(banner: .savedToCloud)

        dismiss(animated: true)
    }

}

extension BackupCloudPassphraseViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "description-section",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.descriptionRow(
                                id: "description",
                                text: "backup.cloud.password.description".localized,
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
            Section(
                    id: "confirm",
                    footerState: .margin(height: 20),
                    rows: [
                        StaticRow(
                                cell: passphraseConfirmationCell,
                                id: "confirm",
                                height: .heightSingleLineCell
                        ),
                        StaticRow(
                                cell: passphraseConfirmationCautionCell,
                                id: "confirm-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.passphraseConfirmationCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),
            Section(
                    id: "highlighted-description",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: passphraseDescriptionCell,
                                id: "passphrase-description",
                                dynamicHeight: { [weak self] width in
                                    self?.passphraseDescriptionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),
        ]
    }

}

extension BackupCloudPassphraseViewController: IDynamicHeightCellDelegate {

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
