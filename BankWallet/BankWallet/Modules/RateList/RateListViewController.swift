import UIKit
import SnapKit
import SectionsTableView

class RateListViewController: WalletViewController {
    private let delegate: IRateListViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: IRateListViewDelegate) {
        self.delegate = delegate

        super.init(gradient: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false

        tableView.registerHeaderFooter(forClass: RateListHeaderView.self)
        tableView.registerCell(forClass: RateListCell.self)
        tableView.sectionDataSource = self

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let gradient = CAGradientLayer()

        gradient.frame = view.bounds
        gradient.colors = [UIColor.clear.cgColor, UIColor.clear.cgColor, UIColor.black.cgColor, UIColor.black.cgColor, UIColor.clear.cgColor, UIColor.clear.cgColor]

        // calculate gradient fading converting margins to percents in view.height
        let percent = 1 / view.bounds.height
        let opaqueHeight = Double(CGFloat.margin6x * percent)
        let gradientHeight = Double(CGFloat.margin8x * percent)
        // locations 0-margin6x all faded. margin6x-margin8x smooth gradient. and same to bottom view part
        gradient.locations = [0.0, NSNumber(value: opaqueHeight), NSNumber(value: opaqueHeight + gradientHeight), NSNumber(value: 1 - opaqueHeight - gradientHeight), NSNumber(value: 1 - opaqueHeight), 1]
        view.layer.mask = gradient
    }

}

extension RateListViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        var rows = [RowProtocol]()
        let count = delegate.itemCount

        for index in 0..<count {
            let item = delegate.item(at: index)
            rows.append(Row<RateListCell>(id: "rate_\(index)", hash: item.hash, height: CGFloat.heightDoubleLineCell, autoDeselect: true, bind: { cell, _ in
                cell.bind(viewItem: item, last: index == count - 1)
            }))
        }
        let width = view.bounds.width
        let headerText = DateHelper.instance.formatRateListTitle(from: delegate.currentDate)
        let titleHeader: ViewState<RateListHeaderView> = .cellType(hash: "rate_list_header", binder: { view in
            view.bind(title: headerText)
        }, dynamicHeight: { _ in RateListHeaderView.height(forContainerWidth: width, text: headerText) })

        sections.append(Section(id: "rate_list_section", headerState: titleHeader, footerState: .margin(height: CGFloat.margin4x), rows: rows))
        return sections
    }

}

extension RateListViewController: IRateListView {

    func reload() {
        tableView.reload(animated: true)
    }

}
