import Combine
import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import MarketKit
import ComponentKit
import Alamofire

class ReceiveSelectCoinViewController: ThemeSearchViewController {
    private var cancellables = Set<AnyCancellable>()

    private let viewModel: ReceiveSelectCoinViewModel

    private let tableView = SectionsTableView(style: .grouped)
    private var viewItems = [ReceiveSelectCoinViewModel.ViewItem]()

    var onSelect: ((FullCoin) -> ())?

    init(viewModel: ReceiveSelectCoinViewModel) {
        self.viewModel = viewModel

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "balance.receive".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        navigationItem.searchController?.searchBar.placeholder = "placeholder.search".localized

        viewModel.$viewItems
                .receive(on: DispatchQueue.main)
                .sink { [weak self] viewItems in
                    self?.sync(viewItems: viewItems)
                }
                .store(in: &cancellables)
        $filter
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.viewModel.apply(filter: $0) }
                .store(in: &cancellables)

        sync(viewItems: viewModel.viewItems)
    }

    @objc func onTapClose() {
        dismiss(animated: true)
    }

    private func onSelect(uid: String) {
        guard let coin = viewModel.fullCoin(uid: uid) else {
            return
        }
        onSelect?(coin)
    }

    private func sync(viewItems: [ReceiveSelectCoinViewModel.ViewItem]) {
        self.viewItems = viewItems

        tableView.reload()
    }

}

extension ReceiveSelectCoinViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "coins",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        let isLast = index == viewItems.count - 1

                        return tableView.universalRow62(
                                id: viewItem.uid,
                                image: .url(viewItem.imageUrl, placeholder: "placeholder_circle_32"),
                                title: .body(viewItem.title),
                                description: .subhead2(viewItem.description),
                                backgroundStyle: .transparent,
                                autoDeselect: true,
                                isLast: isLast
                        ) { [weak self] in
                            self?.onSelect(uid: viewItem.uid)
                        }
                    }
            )
        ]
    }

}
