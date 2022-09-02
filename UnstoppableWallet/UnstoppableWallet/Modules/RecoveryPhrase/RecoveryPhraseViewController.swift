import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit

class RecoveryPhraseViewController: ThemeViewController {
    private let viewModel: RecoveryPhraseViewModel

    private let tableView = SectionsTableView(style: .grouped)

    private var visible = false

    init(viewModel: RecoveryPhraseViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "recovery_phrase.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: EmptyCell.self)
        tableView.registerCell(forClass: MnemonicPhraseCell.self)

        let buttonsHolder = BottomGradientHolder()

        view.addSubview(buttonsHolder)
        buttonsHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        let copyButton = PrimaryButton()

        buttonsHolder.addSubview(copyButton)
        copyButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin24)
        }

        copyButton.set(style: .yellow)
        copyButton.setTitle("button.copy".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)

        tableView.buildSections()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    @objc private func onTapCopy() {
        let viewController = InformationModule.copyConfirmation(value: viewModel.words.joined(separator: " "))
        present(viewController, animated: true)
    }

    private func toggle() {
        visible = !visible
        tableView.reload()
    }

}

extension RecoveryPhraseViewController: SectionsDataSource {

    private func marginRow(id: String, height: CGFloat) -> RowProtocol {
        Row<EmptyCell>(id: id, height: height)
    }

    func buildSections() -> [SectionProtocol] {
        let words = viewModel.words
        let state: MnemonicPhraseCell.State = visible ? .visible(words: words) : .hidden(hint: "recovery_phrase.tap_to_show".localized)

        var rows: [RowProtocol] = [
            tableView.highlightedDescriptionRow(
                    id: "warning",
                    text: "recovery_phrase.warning".localized
            ),
            marginRow(id: "warning-bottom-margin", height: .margin12),
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
            )
        ]

        let visible = visible

        if let passphrase = viewModel.passphrase {
            let passphraseRow = CellBuilderNew.row(
                    rootElement: .hStack([
                        .image20 { component in
                            component.imageView.image = UIImage(named: "key_phrase_20")?.withTintColor(.themeGray)
                        },
                        .text { component in
                            component.font = .subhead2
                            component.textColor = .themeGray
                            component.text = "recovery_phrase.passphrase".localized
                        },
                        .secondaryButton { component in
                            component.button.set(style: .default)
                            component.button.setTitle(visible ? passphrase : "*****", for: .normal)
                            component.onTap = {
                                CopyHelper.copyAndNotify(value: passphrase)
                            }
                        }
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
                    id: "main",
                    footerState: .margin(height: .margin32),
                    rows: rows
            )
        ]
    }

}
