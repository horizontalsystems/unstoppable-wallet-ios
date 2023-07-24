import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit

class EvmAddressViewController: ThemeViewController {
    private let viewModel: EvmAddressViewModel

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: EvmAddressViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "evm_address.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "circle_information_24"), style: .plain, target: self, action: #selector(onTapInfo))

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

        buttonsHolder.add(to: self, under: tableView)
        let copyButton = PrimaryButton()

        buttonsHolder.addSubview(copyButton)

        copyButton.set(style: .yellow)
        copyButton.setTitle("button.copy".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)

        tableView.buildSections()
    }

    @objc private func onTapInfo() {
        guard let url = FaqUrlHelper.privateKeysUrl else {
            return
        }

        let module = MarkdownModule.viewController(url: url, handleRelativeUrl: false)
        present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    @objc private func onTapCopy() {
        UIPasteboard.general.string = viewModel.address
        HudHelper.instance.show(banner: .copied)
    }

}

extension EvmAddressViewController: SectionsDataSource {

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
                        )
                    ]
            )
        ]
    }

}
