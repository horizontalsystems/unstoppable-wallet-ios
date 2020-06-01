import UIKit
import SectionsTableView
import SnapKit
import ThemeKit

class AddErc20TokenViewController: ThemeViewController {
    private let delegate: IAddErc20TokenViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var address: String?

    init(delegate: IAddErc20TokenViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "add_erc20_token.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: AddressInputFieldCell.self)
        tableView.sectionDataSource = self

        tableView.buildSections()
    }

    @objc func onTapCancelButton() {
        delegate.onTapCancel()
    }

    private func inputFieldRow(address: String?) -> RowProtocol {
        Row<AddressInputFieldCell>(
                id: "input_field",
                hash: address,
                dynamicHeight: { containerWidth in
                    AddressInputFieldCell.height(containerWidth: containerWidth, address: address, error: nil)
                },
                bind: { cell, _ in
                    cell.bind(
                            placeholder: "add_erc20_token.contract_address".localized,
                            canEdit: false,
                            lineBreakMode: .byTruncatingMiddle,
                            address: address,
                            error: nil,
                            onPaste: { [weak self] in
                                self?.delegate.onTapPasteAddress()
                            },
                            onDelete: { [weak self] in
                                self?.delegate.onTapDeleteAddress()
                            }
                    )
                }
        )

    }

}

extension AddErc20TokenViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: [
                        inputFieldRow(address: address)
                    ]
            )
        ]
    }

}

extension AddErc20TokenViewController: IAddErc20TokenView {

    func set(address: String?) {
        self.address = address
        tableView.reload()
    }

}
