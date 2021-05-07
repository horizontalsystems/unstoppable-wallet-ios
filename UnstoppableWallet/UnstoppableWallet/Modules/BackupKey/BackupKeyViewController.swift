import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import PinKit
import SectionsTableView
import ComponentKit

class BackupKeyViewController: ThemeViewController {
    private let animationDuration: TimeInterval = 0.2

    private let viewModel: BackupKeyViewModel
    private let disposeBag = DisposeBag()

    private let descriptionView = HighlightedDescriptionView()
    private let showButton = ThemeButton()

    private let tableView = SectionsTableView(style: .grouped)

    private let backupButtonHolder = BottomGradientHolder()
    private let backupButton = ThemeButton()

    private let mnemonicPhraseCell = MnemonicPhraseCell()

    init(viewModel: BackupKeyViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup_key.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }

        tableView.isHidden = true
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: C9Cell.self)

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(CGFloat.margin12)
        }

        descriptionView.text = "backup_key.description".localized

        view.addSubview(showButton)
        showButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        showButton.apply(style: .primaryYellow)
        showButton.setTitle("backup_key.button_show".localized, for: .normal)
        showButton.addTarget(self, action: #selector(onTapShowButton), for: .touchUpInside)

        view.addSubview(backupButtonHolder)
        backupButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        backupButtonHolder.isHidden = true

        backupButtonHolder.addSubview(backupButton)
        backupButton.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview().inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        backupButton.apply(style: .primaryYellow)
        backupButton.setTitle("backup_key.button_backup".localized, for: .normal)
        backupButton.addTarget(self, action: #selector(onTapBackupButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.openUnlockSignal) { [weak self] in self?.openUnlock() }
        subscribe(disposeBag, viewModel.showKeySignal) { [weak self] in self?.showKey() }
        subscribe(disposeBag, viewModel.openConfirmSignal) { [weak self] in self?.openConfirm(account: $0) }

        tableView.buildSections()
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    @objc private func onTapShowButton() {
        viewModel.onTapShow()
    }

    @objc private func onTapBackupButton() {
        viewModel.onTapBackup()
    }

    private func openUnlock() {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: .margin48, right: 0)
        let viewController = App.shared.pinKit.unlockPinModule(delegate: self, biometryUnlockMode: .disabled, insets: insets, cancellable: true, autoDismiss: true)
        present(viewController, animated: true)
    }

    private func showKey() {
        showButton.set(hidden: true, animated: true, duration: animationDuration)
        descriptionView.set(hidden: true, animated: true, duration: animationDuration)

        tableView.set(hidden: false, animated: true, duration: animationDuration)
        backupButtonHolder.set(hidden: false, animated: true, duration: animationDuration)
    }

    private func openConfirm(account: Account) {
        guard let viewController = BackupConfirmKeyModule.viewController(account: account) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension BackupKeyViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let words = viewModel.words

        var sections: [SectionProtocol] = [
            Section(
                    id: "main",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: mnemonicPhraseCell,
                                id: "mnemonic-phrase",
                                height: MnemonicPhraseCell.height(wordCount: words.count),
                                onReady: { [weak self] in
                                    self?.mnemonicPhraseCell.set(words: words)
                                }
                        )
                    ]
            )
        ]

        if let passphrase = viewModel.passphrase {
            let passphraseSection = Section(
                    id: "passphrase",
                    footerState: .margin(height: .margin32),
                    rows: [
                        Row<C9Cell>(
                                id: "passphrase",
                                height: .heightCell48,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                                    cell.title = "backup_key.passphrase".localized
                                    cell.titleImage = UIImage(named: "key_phrase_20")
                                    cell.viewItem = .init(value: passphrase)
                                }
                        )
                    ]
            )

            sections.append(passphraseSection)
        }

        return sections
    }

}

extension BackupKeyViewController: IUnlockDelegate {

    func onUnlock() {
        viewModel.onUnlock()
    }

    func onCancelUnlock() {
    }

}
