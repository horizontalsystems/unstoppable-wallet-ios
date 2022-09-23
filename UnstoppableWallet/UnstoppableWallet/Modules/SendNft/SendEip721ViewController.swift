import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import RxSwift
import RxCocoa
import EthereumKit

class SendEip721ViewController: ThemeViewController {
    private let evmKitWrapper: EvmKitWrapper
    private let viewModel: SendEip721ViewModel
    private let disposeBag = DisposeBag()

    private let iconImageView = UIImageView()
    private let tableView = SectionsTableView(style: .grouped)

    private let recipientCell: RecipientAddressInputCell
    private let recipientCautionCell: RecipientAddressCautionCell

    private let buttonCell = PrimaryButtonCell()

    private var isLoaded = false
    private var keyboardShown = false

    init(evmKitWrapper: EvmKitWrapper, viewModel: SendEip721ViewModel, recipientViewModel: RecipientAddressViewModel) {
        self.evmKitWrapper = evmKitWrapper
        self.viewModel = viewModel

        recipientCell = RecipientAddressInputCell(viewModel: recipientViewModel)
        recipientCautionCell = RecipientAddressCautionCell(viewModel: recipientViewModel)

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "send.title".localized(viewModel.nftRecord.tokenName ?? "NFT")

        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(didTapCancel))

        iconImageView.setImage(withUrlString: "need url strnig", placeholder: UIImage(named: "nft_placeholder")) //!!!!!!!!!!!!

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.keyboardDismissMode = .onDrag
        tableView.sectionDataSource = self

        recipientCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        recipientCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        recipientCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        buttonCell.set(style: .yellow)
        buttonCell.title = "send.next_button".localized
        buttonCell.onTap = { [weak self] in
            self?.didTapProceed()
        }

        subscribe(disposeBag, viewModel.proceedEnableDriver) { [weak self] in self?.buttonCell.isEnabled = $0 }
        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] in self?.openConfirm(sendData: $0) }

        tableView.buildSections()
        isLoaded = true
    }

    @objc private func didTapProceed() {
        viewModel.didTapProceed()
    }

    @objc private func didTapCancel() {
        dismiss(animated: true)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        UIView.animate(withDuration: 0.2) {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }

    private func openConfirm(sendData: SendEvmData) {
        guard let viewController = SendEvmConfirmationModule.viewController(evmKitWrapper: evmKitWrapper, sendData: sendData) else {
            return
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension SendEip721ViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "recipient",
                    headerState: .margin(height: .margin16),
                    rows: [
                        StaticRow(
                                cell: recipientCell,
                                id: "recipient-input",
                                dynamicHeight: { [weak self] width in
                                    self?.recipientCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: recipientCautionCell,
                                id: "recipient-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.recipientCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            ),
            Section(
                    id: "button",
                    headerState: .margin(height: .margin8),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: buttonCell,
                                id: "button",
                                height: PrimaryButtonCell.height
                        )
                    ]
            )
        ]
    }

}
