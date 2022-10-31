import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ThemeKit
import SectionsTableView
import ComponentKit

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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title

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

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }

        tableView.buildSections()
        loaded = true
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    @objc private func onTapCopy() {
        if viewItem.keyIsPrivate {
            let viewController = InformationModule.copyConfirmation(value: viewItem.key)
            present(viewController, animated: true)
        } else {
            UIPasteboard.general.string = viewItem.key
            HudHelper.instance.show(banner: .copied)
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

}

extension ExtendedKeyViewController: SectionsDataSource {

    private func controlRow(item: ControlItem, isFirst: Bool = false, isLast: Bool = false) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = .body
                        component.textColor = .themeLeah
                        component.text = item.title
                    },
                    .text { component in
                        component.font = .subhead1
                        component.textColor = .themeGray
                        component.text = item.value
                    },
                    .margin8,
                    .image20 { component in
                        component.isHidden = item.action == nil
                        component.imageView.image = UIImage(named: "arrow_small_down_20")?.withTintColor(.themeGray)
                    }
                ]),
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
                    action: viewItem.derivationSwitchable ? { [weak self] in
                        self?.onTapDerivation()
                    } : nil
            )
        ]

        if let blockchain = viewItem.blockchain {
            controlItems.append(
                    ControlItem(
                            id: "blockchain",
                            title: "extended_key.blockchain".localized,
                            value: blockchain,
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

        return [
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
                        )
                    ]
            )
        ]
    }

}

extension ExtendedKeyViewController {

    struct ControlItem {
        let id: String
        let title: String
        let value: String
        var action: (() -> ())?
    }

}
