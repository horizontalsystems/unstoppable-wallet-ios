
import SectionsTableView
import SnapKit

import UIKit

class PublicAddressViewController: ThemeViewController {
    private let viewModel: PublicAddressViewModel
    private let accountType: PublicAddressModule.AbstractAccountType

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: PublicAddressViewModel, accountType: PublicAddressModule.AbstractAccountType) {
        self.viewModel = viewModel
        self.accountType = accountType

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = accountType.title

        navigationItem.largeTitleDisplayMode = .never

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

        tableView.buildSections()
    }

    @objc private func onTapCopy() {
        UIPasteboard.general.string = viewModel.address
        HudHelper.instance.show(banner: .copied)
        stat(page: .evmAddress, event: .copy(entity: .evmAddress))
    }
}

extension PublicAddressViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        let address = viewModel.address

        let backgroundStyle: BaseThemeCell.BackgroundStyle = .bordered
        let textFont: UIFont = .subhead1

        return [
            Section(
                id: "main",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: [
                    CellBuilderNew.row(
                        rootElement: .text { component in
                            component.font = textFont
                            component.textColor = .themeLeah
                            component.text = address
                            component.numberOfLines = 0
                        },
                        layoutMargins: UIEdgeInsets(top: 0, left: .margin24, bottom: 0, right: .margin24),
                        tableView: tableView,
                        id: "address",
                        dynamicHeight: { width in
                            CellBuilderNew.height(
                                containerWidth: width,
                                backgroundStyle: backgroundStyle,
                                text: address,
                                font: textFont,
                                verticalPadding: .margin24,
                                elements: [.multiline]
                            )
                        },
                        bind: { cell in
                            cell.set(backgroundStyle: backgroundStyle, cornerRadius: .cornerRadius24, isFirst: true, isLast: true)
                            cell.selectionStyle = .none
                        }
                    ),
                ]
            ),
        ]
    }
}

extension PublicAddressModule.AbstractAccountType {
    var title: String {
        switch self {
        case .evm: return "evm_address.title".localized
        case .tron: return "tron_address.title".localized
        }
    }
}
