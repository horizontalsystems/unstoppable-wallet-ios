import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import PinKit
import SectionsTableView
import ComponentKit

class ShowKeyViewController: ThemeViewController {
    private let animationDuration: TimeInterval = 0.2

    private let viewModel: ShowKeyViewModel
    private let disposeBag = DisposeBag()

    private let descriptionView = HighlightedDescriptionView()
    private let showButton = ThemeButton()

    private let tableView = SectionsTableView(style: .plain)
    private let filterHeaderView = FilterHeaderView(buttonStyle: .tab)
    private let mnemonicPhraseCell = MnemonicPhraseCell()

    private let closeButtonHolder = BottomGradientHolder()
    private let closeButton = ThemeButton()

    private var currentTab: Tab = .mnemonicPhrase

    init(viewModel: ShowKeyViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "show_key.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapCloseButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.isHidden = true
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: DCell.self)
        tableView.registerCell(forClass: Cell9.self)
        tableView.registerCell(forClass: EmptyCell.self)
        tableView.registerCell(forClass: C9Cell.self)

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(CGFloat.margin12)
        }

        descriptionView.text = "show_key.description".localized

        view.addSubview(showButton)
        showButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        showButton.apply(style: .primaryYellow)
        showButton.setTitle("show_key.button_show".localized, for: .normal)
        showButton.addTarget(self, action: #selector(onTapShowButton), for: .touchUpInside)

        filterHeaderView.reload(filters: Tab.allCases.map { .item(title: $0.title) })
        filterHeaderView.onSelect = { [weak self] index in
            if let tab = Tab(rawValue: index) {
                self?.currentTab = tab
                self?.tableView.reload()
            }
        }

        view.addSubview(closeButtonHolder)
        closeButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        closeButtonHolder.isHidden = true

        closeButtonHolder.addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview().inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        closeButton.apply(style: .primaryYellow)
        closeButton.setTitle("button.close".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(onTapCloseButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.openUnlockSignal) { [weak self] in self?.openUnlock() }
        subscribe(disposeBag, viewModel.showKeySignal) { [weak self] in self?.showKey() }

        tableView.buildSections()
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

    @objc private func onTapShowButton() {
        viewModel.onTapShow()
    }

    private func openUnlock() {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: .margin48, right: 0)
        let viewController = App.shared.pinKit.unlockPinModule(delegate: self, biometryUnlockMode: .disabled, insets: insets, cancellable: true, autoDismiss: true)
        present(viewController, animated: true)
    }

    private func showKey() {
        navigationItem.rightBarButtonItem = nil

        showButton.set(hidden: true, animated: true, duration: animationDuration)
        descriptionView.set(hidden: true, animated: true, duration: animationDuration)

        tableView.set(hidden: false, animated: true, duration: animationDuration)
        closeButtonHolder.set(hidden: false, animated: true, duration: animationDuration)
    }

    private func handleTap(viewItem: CopyableSecondaryButton.ViewItem) {
        let viewController = PrivateKeyCopyConfirmationViewController(privateKey: viewItem.value())

        present(viewController.toBottomSheet, animated: true)
    }

    private func marginRow(id: String, height: CGFloat) -> RowProtocol {
        Row<EmptyCell>(id: id, height: height)
    }

    private func rows(privateKey: ShowKeyViewModel.PrivateKey) -> [RowProtocol] {
        let viewItem = CopyableSecondaryButton.ViewItem(type: .raw, value: { privateKey.value })

        return [
            marginRow(
                    id: "\(privateKey.blockchain)-margin",
                    height: .margin12
            ),
            Row<DCell>(
                    id: "\(privateKey.blockchain)-title",
                    height: .heightCell48,
                    bind: { cell, _ in
                        cell.set(backgroundStyle: .lawrence, isFirst: true)
                        cell.title = privateKey.blockchain
                    }
            ),
            Row<Cell9>(
                    id: "\(privateKey.blockchain)-value",
                    dynamicHeight: { width in
                        Cell9.height(containerWidth: width, backgroundStyle: .lawrence, viewItem: viewItem)
                    },
                    bind: { [weak self] cell, _ in
                        cell.set(backgroundStyle: .lawrence, isLast: true)
                        cell.viewItem = viewItem
                        cell.handler = { self?.handleTap(viewItem: $0) }
                    }
            )
        ]
    }

}

extension ShowKeyViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var rows = [RowProtocol]()

        switch currentTab {
        case .mnemonicPhrase:
            let words = viewModel.words

            let phraseRow = StaticRow(
                    cell: mnemonicPhraseCell,
                    id: "mnemonic-phrase",
                    height: MnemonicPhraseCell.height(wordCount: words.count),
                    onReady: { [weak self] in
                        self?.mnemonicPhraseCell.set(words: words)
                    }
            )

            rows.append(marginRow(id: "top-margin", height: .margin12))
            rows.append(phraseRow)

            if let passphrase = viewModel.passphrase {
                let passphraseRow = Row<C9Cell>(
                        id: "passphrase",
                        height: .heightCell48,
                        bind: { cell, _ in
                            cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                            cell.title = "show_key.passphrase".localized
                            cell.titleImage = UIImage(named: "key_phrase_20")
                            cell.viewItem = .init(type: .raw, value: { passphrase })
                        }
                )

                rows.append(marginRow(id: "passphrase-margin", height: .margin32))
                rows.append(passphraseRow)
            }
        case .privateKeys:
            for privateKey in viewModel.privateKeys {
                rows.append(contentsOf: self.rows(privateKey: privateKey))
            }
        }

        return [
            Section(
                    id: "main",
                    headerState: .static(view: filterHeaderView, height: filterHeaderView.headerHeight),
                    footerState: .marginColor(height: .margin32, color: .clear),
                    rows: rows
            )
        ]
    }

}

extension ShowKeyViewController: IUnlockDelegate {

    func onUnlock() {
        viewModel.onUnlock()
    }

    func onCancelUnlock() {
    }

}

extension ShowKeyViewController {

    enum Tab: Int, CaseIterable {
        case mnemonicPhrase
        case privateKeys

        var title: String {
            switch self {
            case .mnemonicPhrase: return "show_key.tab.recovery_phrase".localized
            case .privateKeys: return "show_key.tab.private_keys".localized
            }
        }
    }

}
