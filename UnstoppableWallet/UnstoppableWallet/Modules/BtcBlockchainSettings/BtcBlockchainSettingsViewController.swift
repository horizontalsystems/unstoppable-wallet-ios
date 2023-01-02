import UIKit
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit
import SectionsTableView

class BtcBlockchainSettingsViewController: ThemeViewController {
    private let viewModel: BtcBlockchainSettingsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let iconImageView = UIImageView()

    private let bottomButtonHolder = BottomGradientHolder()
    private let bottomButton = PrimaryButton()

    private var viewItem = BtcBlockchainSettingsViewModel.ViewItem(addressFormatViewItems: nil, restoreSourceViewItems: nil, applyEnabled: false)
    private var loaded = false

    private weak var delegate: IBtcBlockchainSettingsDelegate?
    private var didHandleClose = false

    init(viewModel: BtcBlockchainSettingsViewModel, delegate: IBtcBlockchainSettingsDelegate?) {
        self.viewModel = viewModel
        self.delegate = delegate

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if !didHandleClose {
            delegate?.didCancel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.blockchainName

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(CGFloat.iconSize24)
        }
        iconImageView.setImage(withUrlString: viewModel.blockchainIconUrl, placeholder: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self

        view.addSubview(bottomButtonHolder)
        bottomButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        bottomButtonHolder.addSubview(bottomButton)
        bottomButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin24)
        }

        bottomButton.set(style: .yellow)
        bottomButton.setTitle("button.apply".localized, for: .normal)
        bottomButton.addTarget(self, action: #selector(onTapApply), for: .touchUpInside)

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }
        subscribe(disposeBag, viewModel.approveApplySignal) { [weak self] in self?.openApproveApply() }
        subscribe(disposeBag, viewModel.approveSignal) { [weak self] in
            self?.delegate?.didApprove(coinSettingsArray: $0)
            self?.didHandleClose = true
            self?.dismiss(animated: true)
        }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.didHandleClose = true
            self?.dismiss(animated: true)
        }

        tableView.buildSections()
        loaded = true
    }

    @objc private func onTapApply() {
        viewModel.onTapApply()
    }

    @objc private func onTapCancel() {
        delegate?.didCancel()
        didHandleClose = true
        dismiss(animated: true)
    }

    private func sync(viewItem: BtcBlockchainSettingsViewModel.ViewItem) {
        self.viewItem = viewItem
        bottomButton.isEnabled = viewItem.applyEnabled
        reloadTable()
    }

    private func reloadTable() {
        if loaded {
            tableView.reload(animated: true)
        }
    }

    private func openRestoreModeInfo() {
        present(InfoModule.restoreSourceInfo, animated: true)
    }

    private func openApproveApply() {
        let title = BottomSheetItem.ComplexTitleViewItem(
                title: "btc_blockchain_settings.restore_source.title".localized,
                image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)
        )
        let description = InformationModule.Item.description(
                text: "btc_blockchain_settings.restore_source.alert".localized(viewModel.blockchainName),
                isHighlighted: true
        )
        let applyButton = InformationModule.ButtonItem(style: .yellow, title: "button.apply".localized, action: InformationModule.afterClose { [weak self] in
            self?.viewModel.onApproveApply()
        })
        let cancelButton = InformationModule.ButtonItem(style: .transparent, title: "button.cancel".localized, action: InformationModule.afterClose())

        let viewController = InformationModule.viewController(
                title: .complex(viewItem: title),
                items: [description],
                buttons: [applyButton, cancelButton]
        ).toBottomSheet

        present(viewController, animated: true)
    }

}

extension BtcBlockchainSettingsViewController: SectionsDataSource {

    private func addressFormatRow(viewItem: BtcBlockchainSettingsViewModel.RowViewItem, index: Int, isFirst: Bool, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .vStackCentered([
                        .text { component in
                            component.font = .body
                            component.textColor = .themeLeah
                            component.text = viewItem.title
                        },
                        .margin(3),
                        .text { component in
                            component.font = .subhead2
                            component.textColor = .themeGray
                            component.lineBreakMode = .byTruncatingMiddle
                            component.text = viewItem.subtitle
                        }
                    ]),
                    .switch { [weak self] component in
                        component.switchView.isOn = viewItem.selected
                        component.onSwitch = {
                            self?.viewModel.onToggleAddressFormat(index: index, selected: $0)
                        }
                    }
                ]),
                tableView: tableView,
                id: "address-format-\(index)",
                hash: "\(viewItem.selected)",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                }
        )
    }

    private func restoreSourceRow(viewItem: BtcBlockchainSettingsViewModel.RowViewItem, index: Int, isFirst: Bool, isLast: Bool, action: @escaping () -> ()) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .vStackCentered([
                        .text { component in
                            component.font = .body
                            component.textColor = .themeLeah
                            component.text = viewItem.title
                        },
                        .margin(3),
                        .text { component in
                            component.font = .subhead2
                            component.textColor = .themeGray
                            component.lineBreakMode = .byTruncatingMiddle
                            component.text = viewItem.subtitle
                        }
                    ]),
                    .image20 { [weak self] component in
                        component.isHidden = !viewItem.selected
                        component.imageView.image = UIImage(named: "check_1_20")?.withTintColor(.themeJacob)
                    }
                ]),
                tableView: tableView,
                id: "restore-source-\(index)",
                hash: "\(viewItem.selected)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast)
                },
                action: action
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let addressFormatViewItems = viewItem.addressFormatViewItems {
            sections.append(
                    Section(
                            id: "address-format",
                            headerState: .margin(height: .margin12),
                            footerState: tableView.sectionFooter(text: "btc_blockchain_settings.address_format.description".localized),
                            rows: addressFormatViewItems.enumerated().map { index, addressFormatViewItem in
                                addressFormatRow(viewItem: addressFormatViewItem, index: index, isFirst: index == 0, isLast: index == addressFormatViewItems.count - 1)
                            }
                    )
            )
        }

        if let restoreSourceViewItems = viewItem.restoreSourceViewItems {
            sections.append(
                    Section(
                            id: "restore-source",
                            headerState: .margin(height: viewItem.addressFormatViewItems == nil ? .margin12 : 0),
                            footerState: .margin(height: .margin32),
                            rows: [
                                tableView.subtitleWithInfoButtonRow(text: "btc_blockchain_settings.restore_source".localized) { [weak self] in
                                    self?.openRestoreModeInfo()
                                }
                            ] + restoreSourceViewItems.enumerated().map { index, viewItem in
                                restoreSourceRow(viewItem: viewItem, index: index, isFirst: index == 0, isLast: index == restoreSourceViewItems.count - 1) { [weak self] in
                                    self?.viewModel.onSelectRestoreSource(index: index)
                                }
                            }
                    )
            )
        }

        return sections
    }

}
