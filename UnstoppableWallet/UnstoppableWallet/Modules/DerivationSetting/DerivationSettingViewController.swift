import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView

class DerivationSettingViewController: ThemeActionSheetController {
    private let delegate: IDerivationSettingViewDelegate

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let doneButton = ThemeButton()

    private var viewItems = [DerivationSettingModule.ViewItem]()

    init(delegate: IDerivationSettingViewDelegate) {
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

        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom)
        }

        tableView.registerCell(forClass: BottomSheetCheckmarkCell.self)
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        delegate.onBeforeClose()
    }

    @objc private func _onTapDone() {
        delegate.onTapDone()
    }

}

extension DerivationSettingViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: viewItems.enumerated().map { index, viewItem in
                        Row<BottomSheetCheckmarkCell>(
                                id: "item_\(index)",
                                hash: "\(viewItem.selected)",
                                height: .heightDoubleLineCell,
                                bind: { cell, _ in
                                    cell.bind(
                                            title: viewItem.title,
                                            subtitle: viewItem.subtitle,
                                            checkmarkVisible: viewItem.selected
                                    )
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

extension DerivationSettingViewController: IDerivationSettingView {

    func set(coinTitle: String, coinCode: String, blockchainType: String?) {
        titleView.bind(
                title: "blockchain_settings.title".localized,
                subtitle: coinTitle,
                image: .image(coinCode: coinCode, blockchainType: blockchainType)
        )
    }

    func set(viewItems: [DerivationSettingModule.ViewItem]) {
        self.viewItems = viewItems
        tableView.reload()
    }

}
