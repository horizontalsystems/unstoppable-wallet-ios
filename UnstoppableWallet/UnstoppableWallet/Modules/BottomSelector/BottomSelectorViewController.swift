import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView

protocol IBottomSelectorDelegate: AnyObject {
    func bottomSelectorOnSelect(index: Int)
    func bottomSelectorOnCancel()
}

class BottomSelectorViewController: ThemeActionSheetController {
    private let config: Config
    private weak var delegate: IBottomSelectorDelegate?

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)
    private let doneButton = ThemeButton()

    private var currentIndex: Int
    private var didTapDone = false

    init(config: Config, delegate: IBottomSelectorDelegate) {
        self.config = config
        self.delegate = delegate

        currentIndex = config.selectedIndex

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
                title: config.title,
                subtitle: config.subtitle,
                image: config.icon
        )
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
        doneButton.setTitle("button.done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(onTapDone), for: .touchUpInside)

        tableView.reload()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !didTapDone {
            delegate?.bottomSelectorOnCancel()
        }
    }

    @objc private func onTapDone() {
        delegate?.bottomSelectorOnSelect(index: currentIndex)

        didTapDone = true
        dismiss(animated: true)
    }

}

extension BottomSelectorViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    rows: config.viewItems.enumerated().map { index, viewItem in
                        let selected = index == currentIndex

                        return Row<BottomSheetCheckmarkCell>(
                                id: "item_\(index)",
                                hash: "\(selected)",
                                height: .heightDoubleLineCell,
                                autoDeselect: true,
                                bind: { cell, _ in
                                    cell.bind(
                                            title: viewItem.title,
                                            subtitle: viewItem.subtitle,
                                            checkmarkVisible: selected
                                    )
                                },
                                action: { [weak self] _ in
                                    self?.currentIndex = index
                                    self?.tableView.reload(animated: true)
                                }
                        )
                    }
            )
        ]
    }

}

extension BottomSelectorViewController {

    struct Config {
        let icon: UIImage?
        let title: String
        let subtitle: String
        let selectedIndex: Int
        let viewItems: [ViewItem]
    }

    struct ViewItem {
        let title: String
        let subtitle: String
    }

}
