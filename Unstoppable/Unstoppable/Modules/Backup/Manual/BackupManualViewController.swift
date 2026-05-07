
import SectionsTableView
import SnapKit
import SwiftUI
import UIKit

class BackupManualViewController: ThemeViewController {
    private let viewModel: BackupManualViewModel
    var onComplete: (() -> Void)?

    private let tableView = SectionsTableView(style: .grouped)

    private var visible = false

    init(viewModel: BackupManualViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.title".localized

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "circle_information_24"), style: .plain, target: self, action: #selector(onTapInfo))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: EmptyCell.self)
        tableView.registerCell(forClass: MnemonicPhraseCell.self)

        let backupButtonHolder = BottomGradientHolder()

        backupButtonHolder.add(to: self, under: tableView)

        let verifyButton = PrimaryButton()
        backupButtonHolder.addSubview(verifyButton)

        verifyButton.set(style: .yellow)
        verifyButton.setTitle("backup.verify".localized, for: .normal)
        verifyButton.addTarget(self, action: #selector(onTapVerify), for: .touchUpInside)

        tableView.buildSections()
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapInfo() {
        guard let url = FaqUrlHelper.privateKeysUrl else {
            return
        }

        let module = MarkdownModule.viewController(url: url, handleRelativeUrl: false)
        present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    @objc private func onTapVerify() {
        guard let viewController = BackupVerifyWordsModule.viewController(account: viewModel.account, onComplete: onComplete) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func toggle() {
        visible = !visible
        tableView.reload()
    }
}

extension BackupManualViewController: SectionsDataSource {
    private func marginRow(id: String, height: CGFloat) -> RowProtocol {
        Row<EmptyCell>(id: id, height: height)
    }

    func buildSections() -> [SectionProtocol] {
        let words = viewModel.words
        let state: MnemonicPhraseCell.State = visible ? .visible(words: words) : .hidden(hint: "backup.tap_to_show".localized)

        var rows: [RowProtocol] = [
            Row<MnemonicPhraseCell>(
                id: "mnemonic",
                dynamicHeight: { width in
                    MnemonicPhraseCell.height(containerWidth: width, words: words)
                },
                bind: { cell, _ in
                    cell.set(state: state)
                },
                action: { [weak self] _ in
                    self?.toggle()
                }
            ),
        ]

        let visible = visible

        if let passphrase = viewModel.passphrase {
            let passphraseRow = CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { component in
                        component.imageView.image = UIImage(named: "key_phrase_24")?.withTintColor(.themeGray)
                    },
                    .text { component in
                        component.font = .subhead2
                        component.textColor = .themeGray
                        component.text = "backup.passphrase".localized
                    },
                    .secondaryButton { component in
                        component.button.set(style: .default)
                        component.button.setTitle(visible ? passphrase : BalanceHiddenManager.placeholder, for: .normal)
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: passphrase)
                        }
                    },
                ]),
                tableView: tableView,
                id: "passphrase",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                }
            )

            rows.append(marginRow(id: "passphrase-margin", height: .margin24))
            rows.append(passphraseRow)
        }

        return [
            Section(
                id: "description",
                footerState: tableView.sectionFooter(text: "backup.description".localized)
            ),
            Section(
                id: "main",
                footerState: .margin(height: .margin32),
                rows: rows
            ),
        ]
    }
}

extension BackupManualViewController {
    static func instance(account: Account, onComplete: (() -> Void)? = nil) -> UIViewController? {
        guard let service = BackupManualService(account: account) else {
            return nil
        }
        let viewModel = BackupManualViewModel(service: service)
        let viewController = BackupManualViewController(viewModel: viewModel)
        viewController.onComplete = onComplete

        return ThemeNavigationController(rootViewController: viewController)
    }
}

struct BackupManualView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    private let account: Account
    private let onComplete: (() -> Void)?

    init(account: Account, onComplete: (() -> Void)? = nil) {
        self.account = account
        self.onComplete = onComplete
    }

    func makeUIViewController(context _: Context) -> UIViewController {
        BackupManualViewController.instance(account: account, onComplete: onComplete) ?? UIViewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
