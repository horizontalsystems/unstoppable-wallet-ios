import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import ComponentKit

class PrivacyEthereumRpcModeViewController: ThemeActionSheetController {
    private let delegate: IPrivacyEthereumRpcModeViewDelegate

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let doneButton = ThemeButton()

    private var viewItems = [PrivacyEthereumRpcModeModule.ViewItem]()

    init(delegate: IPrivacyEthereumRpcModeViewDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
                title: "settings_privacy.alert_connection.title".localized,
                subtitle: "Ethereum",
                image: UIImage(named: "ethereum")
        )

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
        }

        tableView.registerCell(forClass: F4Cell.self)
        tableView.sectionDataSource = self

        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(tableView.snp.bottom).offset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        doneButton.apply(style: .primaryYellow)
        doneButton.setTitle("Done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(_onTapDone), for: .touchUpInside)

        delegate.onLoad()

        tableView.reload()
    }

    @objc private func _onTapDone() {
        delegate.onTapDone()
    }

}

extension PrivacyEthereumRpcModeViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: viewItems.enumerated().map { index, viewItem in
                        let isFirst = index == 0
                        let isLast = index == viewItems.count - 1

                        return Row<F4Cell>(
                                id: "item_\(index)",
                                hash: "\(viewItem.selected)",
                                height: .heightDoubleLineCell,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .transparent, isFirst: isFirst, isLast: isLast)
                                    cell.title = viewItem.title
                                    cell.subtitle = viewItem.subtitle
                                    cell.valueImage = viewItem.selected ? UIImage(named: "check_1_20")?.withRenderingMode(.alwaysTemplate) : nil
                                    cell.valueImageTintColor = .themeJacob
                                },
                                action: { [weak self] _ in
                                    self?.delegate.onTapViewItem(index: index)
                                }
                        )
                    }
            )
        ]
    }

}

extension PrivacyEthereumRpcModeViewController: IPrivacyEthereumRpcModeView {

    func set(viewItems: [PrivacyEthereumRpcModeModule.ViewItem]) {
        self.viewItems = viewItems
        tableView.reload()
    }

}
