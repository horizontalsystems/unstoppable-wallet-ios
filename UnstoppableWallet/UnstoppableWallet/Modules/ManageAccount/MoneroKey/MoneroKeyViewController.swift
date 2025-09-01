import RxSwift
import SectionsTableView
import SnapKit

import UIKit

class MoneroKeyViewController: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: MoneroKeyViewModel
    private let tableView = SectionsTableView(style: .grouped)
    private var visible = false
    private var loaded = false

    init(viewModel: MoneroKeyViewModel) {
        self.viewModel = viewModel
        super.init()

        subscribe(disposeBag, viewModel.keyTypeChangedDriver) { [weak self] in self?.sync() }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.showingPrivateKeys ? "monero_private_key.title".localized : "monero_public_key.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "circle_information_24"), style: .plain, target: self, action: #selector(onTapInfo))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.sectionHeaderTopPadding = 0
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: EmptyCell.self)

        let buttonsHolder = BottomGradientHolder()

        buttonsHolder.add(to: self, under: tableView)
        buttonsHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        let copyButton = PrimaryButton()
        buttonsHolder.addSubview(copyButton)

        copyButton.set(style: .yellow)
        copyButton.setTitle("button.copy".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)

        tableView.buildSections()
        loaded = true
    }

    @objc private func onTapInfo() {
        guard let url = FaqUrlHelper.privateKeysUrl else {
            return
        }

        let module = MarkdownModule.viewController(url: url, handleRelativeUrl: false)
        present(ThemeNavigationController(rootViewController: module), animated: true)
        stat(page: viewModel.showingPrivateKeys ? .moneroPrivateKeys : .moneroPublicKeys, event: .open(page: .info))
    }

    @objc private func onTapCopy() {
        let viewController = BottomSheetModule.copyConfirmation(value: viewModel.key) { [weak self] in
            if let showingPrivateKeys = self?.viewModel.showingPrivateKeys {
                stat(page: showingPrivateKeys ? .moneroPrivateKeys : .moneroPublicKeys, event: .copy(entity: .moneroKey))
            }
        }
        present(viewController, animated: true)
    }

    private func toggle() {
        visible = !visible
        tableView.reload()
        stat(page: viewModel.showingPrivateKeys ? .moneroPrivateKeys : .moneroPublicKeys, event: .toggleHidden)
    }

    private func onTapKeyType() {
        let alertController = AlertRouter.module(
            title: "monero.key_types".localized,
            viewItems: viewModel.keyTypeViewItems
        ) { [weak self] index in
            self?.viewModel.onSelectKeyType(index: index)
        }

        present(alertController, animated: true)
    }

    private func sync() {
        if loaded {
            tableView.reload()
        }
    }
}

extension MoneroKeyViewController: SectionsDataSource {
    private func marginRow(id: String, height: CGFloat) -> RowProtocol {
        Row<EmptyCell>(id: id, height: height)
    }

    private func keyTypesRow(title: String, value: MoneroKeyViewModel.KeyType) -> RowProtocol {
        var elements = [CellBuilderNew.CellElement]()
        elements.append(.textElement(text: .body(title)))

        elements.append(.textElement(text: .subhead1("monero.key_types.\(value.rawValue)".localized, color: .themeGray), parameters: .allCompression))
        elements.append(contentsOf: CellBuilderNew.CellElement.accessoryElements(.dropdown))

        return CellBuilderNew.row(
            rootElement: .hStack(elements),
            tableView: tableView,
            id: "key-types",
            height: .heightCell48,
            autoDeselect: true,
            bind: { cell in
                cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
            },
            action: onTapKeyType
        )
    }

    func buildSections() -> [SectionProtocol] {
        let key = viewModel.key
        let showingPrivateKeys = viewModel.showingPrivateKeys
        let visible = showingPrivateKeys ? visible : true
        let tapToShowText = "monero_private_key.tap_to_show".localized

        let backgroundStyle: BaseThemeCell.BackgroundStyle = .bordered
        let textFont: UIFont = .subhead1

        let warningRows = !showingPrivateKeys ? [] : [tableView.highlightedDescriptionRow(
            id: "warning",
            text: "recovery_phrase.warning".localized(AppConfig.appName)
        )]

        return [
            Section(
                id: "controls",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin12),
                rows: [keyTypesRow(title: "monero.key_types".localized, value: viewModel.keyType)]
            ),
            Section(
                id: "main",
                footerState: .margin(height: .margin24),
                rows: warningRows + [
                    marginRow(id: "warning-bottom-margin", height: .margin12),
                    CellBuilderNew.row(
                        rootElement: .text { component in
                            component.font = visible ? textFont : .subhead2
                            component.textColor = visible ? .themeLeah : .themeGray
                            component.text = visible ? key : tapToShowText
                            component.textAlignment = .center
                            component.numberOfLines = 0
                        },
                        layoutMargins: UIEdgeInsets(top: 0, left: .margin24, bottom: 0, right: .margin24),
                        tableView: tableView,
                        id: "monero-key",
                        dynamicHeight: { width in
                            CellBuilderNew.height(
                                containerWidth: width,
                                backgroundStyle: backgroundStyle,
                                text: key,
                                font: textFont,
                                verticalPadding: .margin24,
                                elements: [.multiline]
                            )
                        },
                        bind: { cell in
                            cell.set(backgroundStyle: backgroundStyle, cornerRadius: .cornerRadius24, isFirst: true, isLast: true)
                            cell.selectionStyle = .none
                        },
                        action: { [weak self] in
                            self?.toggle()
                        }
                    ),
                ]
            ),
        ]
    }
}

extension MoneroKeyViewController {
    static func instance(accountType: AccountType, mode: MoneroKeyViewModel.Mode) -> UIViewController? {
        guard let viewModel = MoneroKeyViewModel(accountType: accountType, mode: mode) else {
            return nil
        }

        return MoneroKeyViewController(viewModel: viewModel)
    }
}
