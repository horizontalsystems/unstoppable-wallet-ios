import UIKit
import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit

class EvmPrivateKeyViewController: ThemeViewController {
    private let viewModel: EvmPrivateKeyViewModel

    private let tableView = SectionsTableView(style: .grouped)

    private var visible = false

    init(viewModel: EvmPrivateKeyViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "evm_private_key.title".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

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
        tableView.registerCell(forClass: EmptyCell.self)

        let buttonsHolder = BottomGradientHolder()

        view.addSubview(buttonsHolder)
        buttonsHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        let copyButton = PrimaryButton()

        buttonsHolder.addSubview(copyButton)
        copyButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin24)
        }

        copyButton.set(style: .yellow)
        copyButton.setTitle("button.copy".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)

        tableView.buildSections()
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    @objc private func onTapCopy() {

        let viewController = InformationModule.copyConfirmation(value: viewModel.privateKey)
        present(viewController, animated: true)
    }

    private func toggle() {
        visible = !visible
        tableView.reload()
    }

}

extension EvmPrivateKeyViewController: SectionsDataSource {

    private func marginRow(id: String, height: CGFloat) -> RowProtocol {
        Row<EmptyCell>(id: id, height: height)
    }

    func buildSections() -> [SectionProtocol] {
        let privateKey = viewModel.privateKey
        let visible = visible

        let backgroundStyle: BaseThemeCell.BackgroundStyle = .bordered
        let textFont: UIFont = .subhead1

        return [
            Section(
                    id: "main",
                    footerState: .margin(height: .margin32),
                    rows: [
                        tableView.highlightedDescriptionRow(
                                id: "warning",
                                text: "evm_private_key.warning".localized
                        ),
                        marginRow(id: "warning-bottom-margin", height: .margin12),
                        CellBuilderNew.row(
                                rootElement: .text { component in
                                    component.font = visible ? textFont : .subhead2
                                    component.textColor = visible ? .themeLeah : .themeGray
                                    component.text = visible ? privateKey : "evm_private_key.tap_to_show".localized
                                    component.textAlignment = visible ? .left : .center
                                    component.numberOfLines = 0
                                },
                                layoutMargins: UIEdgeInsets(top: 0, left: .margin24, bottom: 0, right: .margin24),
                                tableView: tableView,
                                id: "private-key",
                                dynamicHeight: { width in
                                    CellBuilderNew.height(
                                            containerWidth: width,
                                            backgroundStyle: backgroundStyle,
                                            text: privateKey,
                                            font: textFont,
                                            verticalPadding: .margin24,
                                            elements: [.multiline]
                                    )
                                },
                                bind: { cell in
                                    cell.set(backgroundStyle: backgroundStyle, cornerRadius: .cornerRadius24, isFirst: true, isLast: true)
                                    cell.selectionStyle = .none
                                },
                                action: { [weak self] in
                                    self?.toggle()
                                }
                        )
                    ]
            )
        ]
    }

}
