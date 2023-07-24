import Foundation
import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class AddTokenViewController: ThemeViewController {
    private let viewModel: AddTokenViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let inputCell = AddressInputCell()
    private let inputCautionCell = FormCautionCell()

    private let addButtonHolder = BottomGradientHolder()
    private let addButton = PrimaryButton()

    private var blockchain: String = ""
    private var viewItem: AddTokenViewModel.ViewItem?
    private var isLoaded = false

    init(viewModel: AddTokenViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "add_token.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        inputCell.isEditable = false
        inputCell.onChangeHeight = { [weak self] in self?.reloadHeights() }
        inputCell.onChangeText = { [weak self] in self?.viewModel.onEnter(reference: $0) }
        inputCell.onFetchText = { [weak self] in
            self?.viewModel.onEnter(reference: $0)
            self?.inputCell.inputText = $0
        }
        inputCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        inputCautionCell.onChangeHeight = { [weak self] in self?.reloadHeights() }

        addButtonHolder.add(to: self, under: tableView)
        addButtonHolder.addSubview(addButton)

        addButton.set(style: .yellow)
        addButton.setTitle("button.add".localized, for: .normal)
        addButton.addTarget(self, action: #selector(onTapAddButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.blockchainDriver) { [weak self] blockchain in
            self?.blockchain = blockchain
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.inputCell.set(isLoading: loading)
        }
        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] viewItem in
            self?.viewItem = viewItem
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.buttonEnabledDriver) { [weak self] enabled in
            self?.addButton.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.placeholderDriver) { [weak self] placeholder in
            self?.inputCell.inputPlaceholder = placeholder
        }
        subscribe(disposeBag, viewModel.cautionDriver) { [weak self] caution in
            self?.inputCell.set(cautionType: caution?.type)
            self?.inputCautionCell.set(caution: caution)
            self?.reloadHeights()
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            HudHelper.instance.show(banner: .addedToWallet)
            self?.dismiss(animated: true)
        }

        tableView.buildSections()

        isLoaded = true
    }

    @objc private func onTapAddButton() {
        viewModel.onTapButton()
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    private func reloadHeights() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload(animated: true)
    }

    private func openBlockchainSelector() {
        let viewController = SelectorModule.singleSelectorViewController(
                title: "add_token.blockchain".localized,
                viewItems: viewModel.blockchainViewItems,
                onSelect: { [weak self] index in
                    self?.viewModel.onSelectBlockchain(index: index)
                }
        )

        present(viewController, animated: true)
    }

}

extension AddTokenViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "blockchain",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.universalRow48(
                                id: "blockchain",
                                image: .local(UIImage(named: "blocks_24")?.withTintColor(.themeGray)),
                                title: .body("add_token.blockchain".localized),
                                value: .subhead1(blockchain, color: .themeGray),
                                accessoryType: .dropdown,
                                hash: blockchain,
                                autoDeselect: true,
                                isFirst: true,
                                isLast: true,
                                action: { [weak self] in
                                    self?.openBlockchainSelector()
                                }
                        )
                    ]
            ),
            Section(
                    id: "input",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: inputCell,
                                id: "input",
                                dynamicHeight: { [weak self] width in
                                    self?.inputCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: inputCautionCell,
                                id: "input-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.inputCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )
        ]

        if let viewItem = viewItem {
            sections.append(
                    Section(
                            id: "token-info",
                            footerState: .margin(height: .margin32),
                            rows: [
                                tableView.universalRow48(
                                        id: "coin-name",
                                        title: .subhead2("add_token.coin_name".localized),
                                        value: .subhead1(viewItem.name),
                                        isFirst: true
                                ),
                                tableView.universalRow48(
                                        id: "coin-name",
                                        title: .subhead2("add_token.symbol".localized),
                                        value: .subhead1(viewItem.code)
                                ),
                                tableView.universalRow48(
                                        id: "coin-name",
                                        title: .subhead2("add_token.decimals".localized),
                                        value: .subhead1(viewItem.decimals),
                                        isLast: true
                                )
                            ]
                    )
            )
        }

        return sections
    }

}
