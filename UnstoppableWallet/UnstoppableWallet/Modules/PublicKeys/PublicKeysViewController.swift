import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ThemeKit
import SectionsTableView
import ComponentKit

class PublicKeysViewController: ThemeViewController {
    private let viewModel: PublicKeysViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: PublicKeysViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "public_keys.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: EmptyCell.self)

        subscribe(disposeBag, viewModel.copySignal) { [weak self] in self?.copy(text: $0) }

        tableView.buildSections()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func copy(text: String) {
        CopyHelper.copyAndNotify(value: text)
    }

}

extension PublicKeysViewController: SectionsDataSource {

    private func marginRow(id: String, height: CGFloat) -> RowProtocol {
        Row<EmptyCell>(id: id, height: height)
    }

    private func copyRow(id: String, title: String, isFirst: Bool = false, isLast: Bool = false, onCopy: @escaping () -> ()) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = title
                    },
                    .secondaryCircleButton { component in
                        component.button.set(image: UIImage(named: "copy_20"))
                        component.onTap = onCopy
                    }
                ]),
                tableView: tableView,
                id: id,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "margin",
                    headerState: .margin(height: .margin12)
            ),
            Section(
                    id: "bitcoin",
                    headerState: tableView.sectionHeader(text: "Bitcoin"),
                    footerState: .margin(height: .margin24),
                    rows: [
                        copyRow(id: "bitcoin-bip-44", title: MnemonicDerivation.bip44.description, isFirst: true) { [weak self] in
                            self?.viewModel.onCopyBitcoin(derivation: .bip44)
                        },
                        copyRow(id: "bitcoin-bip-49", title: MnemonicDerivation.bip49.description) { [weak self] in
                            self?.viewModel.onCopyBitcoin(derivation: .bip49)
                        },
                        copyRow(id: "bitcoin-bip-84", title: MnemonicDerivation.bip84.description, isLast: true) { [weak self] in
                            self?.viewModel.onCopyBitcoin(derivation: .bip84)
                        }
                    ]
            ),
            Section(
                    id: "bitcoin-cash",
                    headerState: tableView.sectionHeader(text: "Bitcoin Cash"),
                    footerState: .margin(height: .margin24),
                    rows: [
                        copyRow(id: "bitcoin-cash-legacy", title: BitcoinCashCoinType.type0.title, isFirst: true) { [weak self] in
                            self?.viewModel.onCopyBitcoinCash(coinType: .type0)
                        },
                        copyRow(id: "bitcoin-cash-new", title: BitcoinCashCoinType.type145.title, isLast: true) { [weak self] in
                            self?.viewModel.onCopyBitcoinCash(coinType: .type145)
                        }
                    ]
            ),
            Section(
                    id: "litecoin",
                    headerState: tableView.sectionHeader(text: "Litecoin"),
                    footerState: .margin(height: .margin24),
                    rows: [
                        copyRow(id: "litecoin-bip-44", title: MnemonicDerivation.bip44.description, isFirst: true) { [weak self] in
                            self?.viewModel.onCopyLitecoin(derivation: .bip44)
                        },
                        copyRow(id: "litecoin-bip-49", title: MnemonicDerivation.bip49.description) { [weak self] in
                            self?.viewModel.onCopyLitecoin(derivation: .bip49)
                        },
                        copyRow(id: "litecoin-bip-84", title: MnemonicDerivation.bip84.description, isLast: true) { [weak self] in
                            self?.viewModel.onCopyLitecoin(derivation: .bip84)
                        }
                    ]
            ),
            Section(
                    id: "dash",
                    headerState: tableView.sectionHeader(text: "Dash"),
                    footerState: .margin(height: .margin32),
                    rows: [
                        copyRow(id: "dash-public-keys", title: "Public Keys", isFirst: true, isLast: true) { [weak self] in
                            self?.viewModel.onCopyDash()
                        }
                    ]
            )
        ]
    }

}
