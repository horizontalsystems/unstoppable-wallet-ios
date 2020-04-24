import UIKit
import XRatesKit
import Chart
import CurrencyKit
import ThemeKit
import SectionsTableView
import SnapKit

extension ChartType {

    var title: String {
        switch self {
            case .day: return "chart.time_duration.day".localized
            case .week: return "chart.time_duration.week".localized
            case .month: return "chart.time_duration.month".localized
            case .month3: return "chart.time_duration.month3".localized
            case .halfYear: return "chart.time_duration.halyear".localized
            case .year: return "chart.time_duration.year".localized
            case .year2: return "chart.time_duration.year2".localized
        }
    }

}

class ChartViewController: ThemeViewController {
    private let chartSection = 0
    private let postsSection = 1

    private let delegate: IChartViewDelegate

    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let chartHeaderView: ChartHeaderView

    private var viewItem: ChartViewItem?

    init(delegate: IChartViewDelegate & IChartIndicatorDelegate, chartConfiguration: ChartConfiguration) {
        self.delegate = delegate
        self.chartHeaderView = ChartHeaderView(configuration: chartConfiguration, delegate: delegate)

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        view.layoutIfNeeded()

        tableView.registerCell(forClass: ChartInfoCell.self)
        tableView.registerCell(forClass: PostCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.tableFooterView = PostFooterView()
        tableView.tableFooterView?.frame =  CGRect(x: 0, y: 0, width: view.width, height: PostFooterView.height)

        chartHeaderView.onSelectIndex = { [weak self] index in
            self?.delegate.onSelectChartType(at: index)
        }

        delegate.onLoad()
    }

    private func updateViews() {
        guard let viewItem = viewItem else {
            return
        }
        chartHeaderView.bind(viewItem: viewItem)
    }

}

extension ChartViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == chartSection {
            return 1
        }
        // posts section
        guard let viewItem = viewItem else {
            return 0
        }
        if let posts = viewItem.postsStatus.data {
            return posts.count
        }

        return 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == chartSection {
            return ChartInfoCell.viewHeight
        }
        // posts section
        guard let viewItem = viewItem else {
            return 0
        }
        if let posts = viewItem.postsStatus.data {
            let post = posts[indexPath.row]
            return PostCell.height(forContainerWidth: tableView.width, title: post.title, subtitle: post.subtitle)
        }

        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == chartSection {
            return tableView.dequeueReusableCell(withIdentifier: String(describing: ChartInfoCell.self), for: indexPath)
        }
        return tableView.dequeueReusableCell(withIdentifier: String(describing: PostCell.self), for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let viewItem = viewItem else {
            return
        }

        if let cell = cell as? PostCell {
            if let posts = viewItem.postsStatus.data {
                let post = posts[indexPath.row]
                cell.bind(title: post.title, subtitle: post.subtitle)
            }
        } else if let cell = cell as? ChartInfoCell {
            if let marketViewItem = viewItem.marketInfoStatus.data {
                cell.bind(marketCap: marketViewItem.marketCap, volume: marketViewItem.volume, supply: marketViewItem.supply, maxSupply: marketViewItem.maxSupply)
            }
        }
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == postsSection {
            delegate.onTapPost(at: indexPath.row)
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return ChartHeaderView.viewHeight
        }
        return PostHeaderView.height
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == chartSection {
            return chartHeaderView
        }
        let view = PostHeaderView()

        if let viewItem = viewItem {
            switch viewItem.postsStatus {
            case .loading:
                view.bind(showSpinner: true)
            case .failed:
                view.bind(showFailed: true)
            default:
                view.bind(showSpinner: false)
            }
        } else {
            view.bind(showSpinner: true)
        }

        return view
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        nil
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        0
    }

}

extension ChartViewController: IChartView {

    func set(title: String) {
        self.title = title.localized
    }

    func set(viewItem: ChartViewItem) {
        self.viewItem = viewItem

        updateViews()
        tableView.reloadData()
    }

    func set(types: [String]) {
        chartHeaderView.bind(titles: types)
    }

    func showSelectedPoint(viewItem: SelectedPointViewItem) {
        chartHeaderView.showSelected(date: viewItem.date, time: viewItem.time, value: viewItem.value, volume: viewItem.volume)
    }

    func hideSelectedPoint() {
        chartHeaderView.hideSelected()
    }

}
