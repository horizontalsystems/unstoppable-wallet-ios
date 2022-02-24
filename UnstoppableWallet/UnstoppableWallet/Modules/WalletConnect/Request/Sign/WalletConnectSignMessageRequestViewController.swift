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

    private let signButton = ThemeButton()
    private let rejectButton = ThemeButton()

    private var domainCell: D7Cell?
    private let messageCell = D1Cell()
    private var dAppNameCell: D7Cell?

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

        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: D1Cell.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        view.addSubview(bottomWrapper)
        bottomWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        bottomWrapper.addSubview(signButton)
        signButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin32)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        signButton.apply(style: .primaryYellow)
        signButton.setTitle("button.sign".localized, for: .normal)
        signButton.addTarget(self, action: #selector(onTapSign), for: .touchUpInside)

        bottomWrapper.addSubview(rejectButton)
        rejectButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(signButton.snp.bottom).offset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        rejectButton.apply(style: .primaryGray)
        rejectButton.setTitle("button.reject".localized, for: .normal)
        rejectButton.addTarget(self, action: #selector(onTapReject), for: .touchUpInside)

        if let domain = viewModel.domain {
            domainCell = D7Cell()
            domainCell?.set(backgroundStyle: .lawrence, isFirst: true)
            domainCell?.title = "wallet_connect.sign.domain".localized
            domainCell?.value = domain
        }

        messageCell.set(backgroundStyle: .lawrence, isFirst: domainCell == nil, isLast: viewModel.dAppName == nil)
        messageCell.title = "wallet_connect.sign.message".localized

        if let dAppName = viewModel.dAppName {
            dAppNameCell = D7Cell()
            dAppNameCell?.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
            dAppNameCell?.title = "wallet_connect.sign.dapp_name".localized
            dAppNameCell?.value = dAppName
        }
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

    private func showMessage() {
        navigationController?.pushViewController(WalletConnectShowSigningMessageViewController(viewModel: viewModel), animated: true)
    }

    private func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

    private func dismiss() {
        dismiss(animated: true)
    }

}

extension WalletConnectSignMessageRequestViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var rows: [RowProtocol] = []
        if let domainCell = domainCell {
            rows.append(StaticRow(
                    cell: domainCell,
                    id: "sign_domain",
                    height: .heightCell48
            ))
        }
        rows.append(StaticRow(
                cell: messageCell,
                id: "sign_message",
                height: .heightCell48,
                action: { [weak self] in
                    self?.showMessage()
                }
        ))
        if let dAppNameCell = dAppNameCell {
            rows.append(StaticRow(
                    cell: dAppNameCell,
                    id: "dApp_name",
                    height: .heightCell48
            ))
        }

        return [Section(
                id: "sign_section",
                headerState: .margin(height: .margin12),
                footerState: footer(text: "wallet_connect.sign.description".localized),
                rows: rows
        )]
    }

    private func footer(text: String) -> ViewState<BottomDescriptionHeaderFooterView> {
        .cellType(
                hash: "bottom_description",
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { width in
                    BottomDescriptionHeaderFooterView.height(containerWidth: width, text: text)
                }
        )
    }

}
