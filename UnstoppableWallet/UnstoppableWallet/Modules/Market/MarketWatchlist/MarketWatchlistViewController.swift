import UIKit
import RxSwift
import ThemeKit
import SectionsTableView

class MarketWatchlistView: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let viewModel: MarketWatchlistViewModel

    private let tableView = SectionsTableView(style: .plain)


    init(viewModel: MarketWatchlistViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
//        tableView.contentInset = UIEdgeInsets(Watchlist: 128, left: 0, bottom: 0, right: 0)
        tableView.registerCell(forClass: AdditionalDataCell.self)

        tableView.buildSections()

    }

}

extension MarketWatchlistView: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {

        var rows = [RowProtocol]()
        for i in 0..<40 {
            rows.append(Row<AdditionalDataCell>(
                    id: "\(i)",
                    height: AdditionalDataCell.height,
                    bind: { cell, _ in
                        cell.bind(title: "\(i)87efherf90843rehf", value: "\(i)3943yfkjsfy4389r", highlighted: true)
                    }
            ))
        }

        return [Section(id: "123", rows: rows)]
    }

}
