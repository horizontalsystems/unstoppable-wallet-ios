import UIKit
import SnapKit
import SectionsTableView
import ThemeKit

class RateListViewController: ThemeViewController {
    private let delegate: IRateListViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var item: RateListViewItem?

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

    private func lastUpdateText(item: RateListViewItem?) -> String? {
        guard let lastTimestamp = item?.lastUpdateTimestamp else {
            return nil
        }

        let formattedTime = DateHelper.instance.formatTimeOnly(from: Date(timeIntervalSince1970: lastTimestamp))
        return "rate_list.updated".localized + "\n" + formattedTime
    }

}

extension RateListViewController: SectionsDataSource {

    public func buildSections() -> [SectionProtocol] {
        guard let item = item else {
            return []
        }
        var sections = [SectionProtocol]()
        var rows = [RowProtocol]()

        let count = item.rateViewItems.count
        for index in 0..<count {
            let item = item.rateViewItems[index]
            rows.append(Row<RateListCell>(id: "rate_\(index)", hash: item.hash, height: CGFloat.heightDoubleLineCell, autoDeselect: true, bind: { cell, _ in
                cell.bind(viewItem: item, last: index == count - 1)
            }))
        }
        let width = view.bounds.width

        let headerText = DateHelper.instance.formatRateListTitle(from: item.currentDate)
        let lastUpdatedText = lastUpdateText(item: item)

        let titleHeader: ViewState<RateListHeaderView> = .cellType(hash: "rate_list_header", binder: { view in
            view.bind(title: headerText, lastUpdated: lastUpdatedText)
        }, dynamicHeight: { _ in RateListHeaderView.height(forContainerWidth: width, text: headerText) })

        sections.append(Section(id: "rate_list_section", headerState: titleHeader, footerState: .margin(height: CGFloat.margin4x), rows: rows))
        return sections
    }

}

extension RateListViewController: IRateListView {

    func show(item: RateListViewItem) {
        self.item = item

        tableView.reload()
    }

}
