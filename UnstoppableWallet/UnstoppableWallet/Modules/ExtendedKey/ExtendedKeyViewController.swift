import ComponentKit
import RxCocoa
import RxSwift
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class ExtendedKeyViewController: ThemeViewController {
    private let viewModel: ExtendedKeyViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItem: ExtendedKeyViewModel.ViewItem = .empty
    private var keyHidden = false
    private var loaded = false

    init(viewModel: ExtendedKeyViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

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

        let buttonsHolder = BottomGradientHolder()

        buttonsHolder.add(to: self, under: tableView)
        let copyButton = PrimaryButton()

        buttonsHolder.addSubview(copyButton)

        copyButton.set(style: .yellow)
        copyButton.setTitle("button.copy".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }

        tableView.buildSections()
        loaded = true
    }

    @objc private func onTapInfo() {
        guard let url = FaqUrlHelper.privateKeysUrl else {
            return
        }

        let module = MarkdownModule.viewController(url: url, handleRelativeUrl: false)
        present(ThemeNavigationController(rootViewController: module), animated: true)
        stat(page: viewModel.statPage, event: .open(page: .info))
    }

    @objc private func onTapCopy() {
        let statPage = viewModel.statPage

        if viewItem.keyIsPrivate {
            let viewController = BottomSheetModule.copyConfirmation(value: viewItem.key) {
                stat(page: statPage, event: .copy(entity: .key))
            }
            present(viewController, animated: true)
        } else {
            UIPasteboard.general.string = viewItem.key
            HudHelper.instance.show(banner: .copied)
            stat(page: statPage, event: .copy(entity: .key))
        }
    }

    private func sync(viewItem: ExtendedKeyViewModel.ViewItem) {
        self.viewItem = viewItem
        keyHidden = viewItem.keyIsPrivate
        reloadTable()
    }

    private func toggleKeyHidden() {
        keyHidden = !keyHidden
        tableView.reload()
        stat(page: viewModel.statPage, event: .toggleHidden)
    }

    private func reloadTable() {
        if loaded {
            tableView.reload()
        }
    }

    private func onTapDerivation() {
        let alertController = AlertRouter.module(
            title: "extended_key.purpose".localized,
            viewItems: viewModel.derivationViewItems
        ) { [weak self] index in
            self?.viewModel.onSelectDerivation(index: index)
        }

        present(alertController, animated: true)
    }

    private func onTapBlockchain() {
        let alertController = AlertRouter.module(
            title: "extended_key.blockchain".localized,
            viewItems: viewModel.blockchainViewItems
        ) { [weak self] index in
            self?.viewModel.onSelectBlockchain(index: index)
        }

        present(alertController, animated: true)
    }

    private func onTapAccount() {
        let alertController = AlertRouter.module(
            title: "extended_key.account".localized,
            viewItems: viewModel.accountViewItems
        ) { [weak self] index in
            self?.viewModel.onSelectAccount(index: index)
        }

        present(alertController, animated: true)
    }

    private func openInfo(title: String, description: String) {
        let viewController = BottomSheetModule.description(title: title, text: description)
        present(viewController, animated: true)
    }
}

extension ExtendedKeyViewController: SectionsDataSource {
    private func controlRow(item: ControlItem, isFirst: Bool = false, isLast: Bool = false) -> RowProtocol {
        var elements = [CellBuilderNew.CellElement]()

        if let description = item.description {
            elements.append(contentsOf: [
                .secondaryButton { [weak self] component in
                    component.button.set(style: .transparent2, image: UIImage(named: "circle_information_20"))
                    component.button.setTitle(item.title, for: .normal)
                    component.button.setTitleColor(.themeLeah, for: .normal)
                    component.button.titleLabel?.font = .body

                    component.button.snp.makeConstraints { maker in
                        maker.edges.equalToSuperview()
                        maker.centerY.equalToSuperview()
                    }

                    component.onTap = { [weak self] in
                        self?.openInfo(title: item.title, description: description)
                    }
                },
                .margin0,
                .text { _ in },
            ])
        } else {
            elements.append(.textElement(text: .body(item.title)))
        }

        elements.append(.textElement(text: .subhead1(item.value, color: .themeGray), parameters: .allCompression))
        elements.append(contentsOf: CellBuilderNew.CellElement.accessoryElements(item.action == nil ? .none : .dropdown))

        return CellBuilderNew.row(
            rootElement: .hStack(elements),
            tableView: tableView,
            id: item.id,
            height: .heightCell48,
            autoDeselect: true,
            bind: { cell in
                cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
            },
            action: item.action
        )
    }

    func buildSections() -> [SectionProtocol] {
        var controlItems: [ControlItem] = [
            ControlItem(
                id: "derivation",
                title: "extended_key.purpose".localized,
                value: viewItem.derivation,
                description: nil,
                action: viewItem.derivationSwitchable ? { [weak self] in
                    self?.onTapDerivation()
                } : nil
            ),
        ]

        if let blockchain = viewItem.blockchain {
            controlItems.append(
                ControlItem(
                    id: "blockchain",
                    title: "extended_key.blockchain".localized,
                    value: blockchain,
                    description: nil,
                    action: viewItem.blockchainSwitchable ? { [weak self] in
                        self?.onTapBlockchain()
                    } : nil
                )
            )
        }

        if let account = viewItem.account {
            controlItems.append(
                ControlItem(
                    id: "account",
                    title: "extended_key.account".localized,
                    value: account,
                    description: "extended_key.account.description".localized,
                    action: { [weak self] in
                        self?.onTapAccount()
                    }
                )
            )
        }

        let key = viewItem.key
        let keyHidden = keyHidden

        let backgroundStyle: BaseThemeCell.BackgroundStyle = .bordered
        let textFont: UIFont = .subhead1

        var sections = [SectionProtocol]()

        if viewItem.keyIsPrivate {
            sections.append(
                Section(
                    id: "warning",
                    rows: [
                        tableView.highlightedDescriptionRow(
                            id: "warning",
                            text: "recovery_phrase.warning".localized(AppConfig.appName)
                        ),
                    ]
                )
            )
        }

        sections.append(contentsOf: [
            Section(
                id: "controls",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: controlItems.enumerated().map { index, item in
                    controlRow(item: item, isFirst: index == 0, isLast: index == controlItems.count - 1)
                }
            ),
            Section(
                id: "key",
                footerState: .margin(height: .margin32),
                rows: [
                    CellBuilderNew.row(
                        rootElement: .text { component in
                            component.font = keyHidden ? .subhead2 : textFont
                            component.textColor = keyHidden ? .themeGray : .themeLeah
                            component.text = keyHidden ? "extended_key.tap_to_show".localized : key
                            component.textAlignment = keyHidden ? .center : .left
                            component.numberOfLines = 0
                        },
                        layoutMargins: UIEdgeInsets(top: 0, left: .margin24, bottom: 0, right: .margin24),
                        tableView: tableView,
                        id: "key",
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
                        action: viewItem.keyIsPrivate ? { [weak self] in
                            self?.toggleKeyHidden()
                        } : nil
                    ),
                ]
            ),
        ])

        return sections
    }
}

extension ExtendedKeyViewController {
    struct ControlItem {
        let id: String
        let title: String
        let value: String
        let description: String?
        var action: (() -> Void)?
    }
}
