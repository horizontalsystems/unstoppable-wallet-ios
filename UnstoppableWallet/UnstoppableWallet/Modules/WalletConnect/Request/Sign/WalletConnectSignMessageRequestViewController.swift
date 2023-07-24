import UIKit
import ThemeKit
import SectionsTableView
import ComponentKit
import RxSwift

class WalletConnectSignMessageRequestViewController: ThemeViewController {
    private let viewModel: WalletConnectSignMessageRequestViewModel

    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let bottomWrapper = BottomGradientHolder()

    private let signButton = PrimaryButton()
    private let rejectButton = PrimaryButton()

    init(viewModel: WalletConnectSignMessageRequestViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.sign.request_title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false

        tableView.sectionDataSource = self

        bottomWrapper.add(to: self, under: tableView)
        bottomWrapper.addSubview(signButton)

        signButton.set(style: .yellow)
        signButton.setTitle("button.sign".localized, for: .normal)
        signButton.addTarget(self, action: #selector(onTapSign), for: .touchUpInside)

        bottomWrapper.addSubview(rejectButton)

        rejectButton.set(style: .gray)
        rejectButton.setTitle("button.reject".localized, for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)

        tableView.buildSections()

        subscribe(disposeBag, viewModel.errorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.dismissSignal) { [weak self] in self?.dismiss() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapSign() {
        viewModel.onSign()
    }

    @objc private func onTapReject() {
        viewModel.onReject()
    }

    private func show(error: Error) {
        HudHelper.instance.show(banner: .error(string: error.localizedDescription))
    }

    private func dismiss() {
        dismiss(animated: true)
    }

}

extension WalletConnectSignMessageRequestViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if viewModel.domain != nil || viewModel.dAppName != nil || viewModel.chain.chainName != nil {
            var rows: [RowProtocol] = []

            if let domain = viewModel.domain {
                let row = tableView.universalRow48(
                        id: "sign_domain",
                        title: .subhead2("wallet_connect.sign.domain".localized),
                        value: .subhead1(domain),
                        isFirst: true,
                        isLast: viewModel.dAppName == nil && viewModel.chain.chainName == nil
                )

                rows.append(row)
            }

            if let dAppName = viewModel.dAppName {
                let row = tableView.universalRow48(
                        id: "dApp_name",
                        title: .subhead2("wallet_connect.sign.dapp_name".localized),
                        value: .subhead1(dAppName),
                        isFirst: viewModel.domain == nil,
                        isLast: viewModel.chain.chainName == nil
                )

                rows.append(row)
            }

            if let chainName = viewModel.chain.chainName {
                let row = tableView.universalRow48(
                        id: "chain_name",
                        title: .subhead2(chainName),
                        value: .subhead1(viewModel.chain.address?.shortened),
                        isFirst: viewModel.domain == nil && viewModel.dAppName == nil,
                        isLast: true
                )

                rows.append(row)
            }

            sections.append(
                    Section(
                            id: "info",
                            headerState: .margin(height: .margin12),
                            footerState: .margin(height: .margin24),
                            rows: rows
                    )
            )
        }

        sections.append(
                Section(
                        id: "message",
                        headerState: tableView.sectionHeader(text: "wallet_connect.sign.message".localized),
                        footerState: .margin(height: .margin32),
                        rows: [
                            tableView.messageRow(text: viewModel.message)
                        ]
                )
        )

        return sections
    }

}
