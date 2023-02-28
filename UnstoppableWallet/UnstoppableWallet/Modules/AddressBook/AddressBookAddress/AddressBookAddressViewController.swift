import UIKit
import Foundation
import RxSwift
import RxCocoa
import SectionsTableView
import ComponentKit
import ThemeKit

class AddressBookAddressViewController: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: AddressBookAddressViewModel

    private let tableView = SectionsTableView(style: .grouped)
    private var isLoaded = false

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private var blockchainName: String = ""
    private var addAddressEnabled: Bool = true

    init(viewModel: AddressBookAddressViewModel, addressViewModel: RecipientAddressViewModel) {
        self.viewModel = viewModel
        recipientCell = RecipientAddressInputCell(viewModel: addressViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: addressViewModel)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.save".localized, style: .done, target: self, action: #selector(onTapSaveButton))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .done, target: self, action: #selector(onTapCancelButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self
        tableView.keyboardDismissMode = .interactive

        tableView.buildSections()

        recipientCell.inputText = viewModel.initialAddress

        recipientCell.onChangeHeight = { [weak self] in
            self?.onChangeHeight()
        }
        recipientCell.onOpenViewController = { [weak self] in
            self?.present($0, animated: true)
        }

        recipientCautionCell.onChangeHeight = { [weak self] in self?.onChangeHeight() }

        subscribe(disposeBag, viewModel.saveEnabledDriver) { [weak self] enabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.blockchainNameDriver) { [weak self] name in
            self?.blockchainName = name
            self?.tableView.reload()
        }

        isLoaded = true
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    @objc private func onTapSaveButton() {
        //
    }

    private func onTapBlockchain() {
        let viewController = SelectorModule.singleSelectorViewController(
                title: "market.advanced_search.blockchains".localized,
                viewItems: viewModel.blockchainViewItems,
                onSelect: { [weak self] in
                    print($0)
                    self?.viewModel.setBlockchain(index: $0)
                }
        )

        present(viewController, animated: true)
    }

    private var blockchainRow: RowProtocol {
        tableView.universalRow48(
            id: "blockchain",
            title: .subhead2("Blockchain"),
            value: .subhead1(blockchainName),
            accessoryType: viewModel.readonly ? .none : .dropdown,
            autoDeselect: true,
            isFirst: true,
            isLast: true,
            action: viewModel.readonly ? nil : { [weak self] in self?.onTapBlockchain() })
    }
}

extension AddressBookAddressViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(id: "actions",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: [blockchainRow]),
            Section(
                    id: "name",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: recipientCell,
                                id: "name",
                                dynamicHeight: { [weak self] width in
                                    self?.recipientCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: recipientCautionCell,
                                id: "name-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.recipientCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )
        ]
    }

}

extension AddressBookAddressViewController: IDynamicHeightCellDelegate {

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
