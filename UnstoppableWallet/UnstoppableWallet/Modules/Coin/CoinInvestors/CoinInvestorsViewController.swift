import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

class CoinInvestorsViewController: ThemeViewController {
    private let viewModel: CoinInvestorsViewModel
    private let urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    private var viewItems: [CoinInvestorsViewModel.ViewItem]?

    init(viewModel: CoinInvestorsViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_analytics.funding".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
    }

    private func sync(viewItems: [CoinInvestorsViewModel.ViewItem]?) {
        self.viewItems = viewItems

        if viewItems != nil {
            tableView.bounces = true
        } else {
            tableView.bounces = false
        }

        tableView.reload()
    }

}

extension CoinInvestorsViewController: SectionsDataSource {

    private func headerSection(index: Int, title: String, value: String) -> SectionProtocol {
        Section(
                id: "header-\(index)",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin12),
                rows: [
                    tableView.universalRow48(
                            id: "header-\(index)",
                            title: .body(title, color: .themeJacob),
                            value: .body(value),
                            backgroundStyle: .transparent
                    )
                ]
        )
    }

    private func row(fundViewItem: CoinInvestorsViewModel.FundViewItem, isFirst: Bool, isLast: Bool) -> RowProtocol {
        tableView.universalRow56(
                id: fundViewItem.uid,
                image: .url(fundViewItem.logoUrl, placeholder: "placeholder_circle_32"),
                title: .body(fundViewItem.name),
                value: fundViewItem.isLead ? .subhead1("coin_analytics.funding.lead".localized, color: .themeRemus) : nil,
                accessoryType: fundViewItem.url.isEmpty ? .none : .disclosure,
                autoDeselect: true,
                isFirst: isFirst,
                isLast: isLast,
                action: { [weak self] in
                    self?.urlManager.open(url: fundViewItem.url, from: self)
                }
        )
    }

    private func section(index: Int, fundViewItems: [CoinInvestorsViewModel.FundViewItem], isLast: Bool) -> SectionProtocol {
        Section(
                id: "section-\(index)",
                footerState: .margin(height: isLast ? .margin32 : 0),
                rows: fundViewItems.enumerated().map { index, fundViewItem in
                    row(fundViewItem: fundViewItem, isFirst: index == 0, isLast: index == fundViewItems.count - 1)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let viewItems = viewItems else {
            return []
        }

        var sections = [SectionProtocol]()

        for (index, viewItem) in viewItems.enumerated() {
            sections.append(headerSection(index: index, title: viewItem.amount, value: viewItem.info))
            sections.append(section(index: index, fundViewItems: viewItem.fundViewItems, isLast: index == viewItems.count - 1))
        }

        return sections
    }

}
