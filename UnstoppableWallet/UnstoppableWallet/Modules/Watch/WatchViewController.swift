import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit
import RxSwift
import RxCocoa
import UIExtensions

class WatchViewController: KeyboardAwareViewController {
    private let viewModel: WatchViewModel
    private let publicKeyViewModel: WatchPublicKeyViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let gradientWrapperView = BottomGradientHolder()
    private let nextButton = PrimaryButton()

    private let nameCell = TextFieldCell()
    private let evmAddressCell: RecipientAddressInputCell
    private let evmAddressCautionCell: RecipientAddressCautionCell
    private let tronAddressCell: RecipientAddressInputCell
    private let tronAddressCautionCell: RecipientAddressCautionCell

    private let publicKeyInputCell = TextInputCell()
    private let publicKeyCautionCell = FormCautionCell()

    private var watchType: WatchModule.WatchType = .evmAddress
    private var isLoaded = false

    private weak var sourceViewController: UIViewController?

    init(viewModel: WatchViewModel, evmAddressViewModel: RecipientAddressViewModel, tronAddressViewModel: RecipientAddressViewModel, publicKeyViewModel: WatchPublicKeyViewModel, sourceViewController: UIViewController?) {
        self.viewModel = viewModel
        self.publicKeyViewModel = publicKeyViewModel
        self.sourceViewController = sourceViewController

        evmAddressCell = RecipientAddressInputCell(viewModel: evmAddressViewModel)
        evmAddressCautionCell = RecipientAddressCautionCell(viewModel: evmAddressViewModel)
        tronAddressCell = RecipientAddressInputCell(viewModel: tronAddressViewModel)
        tronAddressCautionCell = RecipientAddressCautionCell(viewModel: tronAddressViewModel)

        super.init(scrollViews: [tableView], accessoryView: gradientWrapperView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "watch_address.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .done, target: self, action: #selector(onTapNext))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        gradientWrapperView.add(to: self)
        gradientWrapperView.addSubview(nextButton)

        nextButton.set(style: .yellow)
        nextButton.setTitle(viewModel.hasNextPage ? "button.next".localized : "watch_address.watch".localized, for: .normal)
        nextButton.addTarget(self, action: #selector(onTapNext), for: .touchUpInside)

        let defaultName = viewModel.defaultName
        nameCell.inputText = defaultName
        nameCell.inputPlaceholder = defaultName
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0 ?? "") }

        evmAddressCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        evmAddressCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }
        evmAddressCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        tronAddressCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        tronAddressCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }
        tronAddressCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        publicKeyInputCell.set(placeholderText: "watch_address.public_key.placeholder".localized)
        publicKeyInputCell.onChangeHeight = { [weak self] in self?.reloadTable() }
        publicKeyInputCell.onChangeText = { [weak self] in self?.publicKeyViewModel.onChange(text: $0) }
        publicKeyInputCell.onChangeTextViewCaret = { [weak self] in self?.syncContentOffsetIfRequired(textView: $0) }
        publicKeyInputCell.onOpenViewController = { [weak self] in self?.present($0, animated: true) }

        publicKeyCautionCell.onChangeHeight = { [weak self] in self?.reloadTable() }

        subscribe(disposeBag, viewModel.nameSignal) { [weak self] name in
            self?.nameCell.inputText = name
            self?.nameCell.inputPlaceholder = name
        }
        subscribe(disposeBag, viewModel.watchTypeDriver) { [weak self] watchType in
            self?.watchType = watchType
            self?.tableView.reload()
        }
        subscribe(disposeBag, publicKeyViewModel.cautionDriver) { [weak self] caution in
            self?.publicKeyInputCell.set(cautionType: caution?.type)
            self?.publicKeyCautionCell.set(caution: caution)
        }
        subscribe(disposeBag, viewModel.watchEnabledDriver) { [weak self] enabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
            self?.nextButton.isEnabled = enabled
        }
        subscribe(disposeBag, viewModel.proceedSignal) { [weak self] (watchType, accountType, name) in
            self?.proceedToNextPage(watchType: watchType, accountType: accountType, name: name)
        }

        tableView.buildSections()
        isLoaded = true
    }

    @objc private func onTapNext() {
        viewModel.onTapNext()
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.buildSections()
        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func onTapWatchType() {
        let alertController = AlertRouter.module(
                title: "watch_address.watch_by".localized,
                viewItems: WatchModule.WatchType.allCases.enumerated().map { index, watchType in
                    AlertViewItem(
                            text: watchType.title,
                            description: watchType.subtitle,
                            selected: self.watchType == watchType
                    )
                }
        ) { [weak self] index in
            self?.viewModel.onSelect(watchType: WatchModule.WatchType.allCases[index])
        }

        present(alertController, animated: true)
    }

    private func proceedToNextPage(watchType: WatchModule.WatchType, accountType: AccountType, name: String) {
        guard let viewController = WatchModule.viewController(sourceViewController: sourceViewController, watchType: watchType, accountType: accountType, name: name) else {
            HudHelper.instance.show(banner: .walletAdded)
            sourceViewController?.dismiss(animated: true)
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

}

extension WatchViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                id: "margin",
                headerState: .margin(height: .margin12)
            ),
            Section(
                id: "name",
                headerState: tableView.sectionHeader(text: "create_wallet.name".localized),
                footerState: .margin(height: .margin32),
                rows: [
                    StaticRow(
                        cell: nameCell,
                        id: "name",
                        height: .heightSingleLineCell
                    )
                ]
            )
        ]

        sections.append(
                Section(
                        id: "watch-type",
                        footerState: .margin(height: .margin32),
                        rows: [
                            tableView.universalRow48(
                                    id: "watch_type",
                                    title: .body("watch_address.by".localized),
                                    value: .subhead1(watchType.title, color: .themeGray),
                                    accessoryType: .dropdown,
                                    autoDeselect: true,
                                    isFirst: true,
                                    isLast: true
                            ) { [weak self] in
                                self?.onTapWatchType()
                            }
                        ]
                )
        )

        switch watchType {
        case .evmAddress:
            let evmAddressSection: SectionProtocol = Section(
                    id: "address",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: evmAddressCell,
                                id: "address-input",
                                dynamicHeight: { [weak self] width in
                                    self?.evmAddressCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: evmAddressCautionCell,
                                id: "address-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.evmAddressCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )

            sections.append(evmAddressSection)
        case .tronAddress:
            let tronAddressSection: SectionProtocol = Section(
                    id: "address",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: tronAddressCell,
                                id: "address-input",
                                dynamicHeight: { [weak self] width in
                                    self?.tronAddressCell.height(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: tronAddressCautionCell,
                                id: "address-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.tronAddressCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )

            sections.append(tronAddressSection)
        case .publicKey:
            let publicKeySection: SectionProtocol = Section(
                    id: "public-key-input",
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: publicKeyInputCell,
                                id: "public-key-input",
                                dynamicHeight: { [weak self] width in
                                    self?.publicKeyInputCell.cellHeight(containerWidth: width) ?? 0
                                }
                        ),
                        StaticRow(
                                cell: publicKeyCautionCell,
                                id: "public-key-caution",
                                dynamicHeight: { [weak self] width in
                                    self?.publicKeyCautionCell.height(containerWidth: width) ?? 0
                                }
                        )
                    ]
            )

            sections.append(publicKeySection)
        }

        return sections
    }

}
