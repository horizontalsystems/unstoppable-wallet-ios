import UIKit
import SnapKit
import ThemeKit
import SectionsTableView
import HUD
import RxSwift

class GuidesViewController: ThemeViewController {
    private let viewModel: IGuidesViewModel

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let filterHeaderView = FilterHeaderView(buttonStyle: .tab)

    private let spinner = HUDActivityView.create(with: .large48)

    private let errorView = PlaceholderViewModule.reachabilityView()

    private var viewItems = [GuideViewItem]()

    private let disposeBag = DisposeBag()

    init(viewModel: IGuidesViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "guides.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: GuideCell.self)
        tableView.dataSource = self
        tableView.delegate = self

        filterHeaderView.onSelect = { [weak self] index in
            self?.viewModel.onSelectFilter(index: index)
        }

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.image = UIImage(named: "not_available_48")

        viewModel.filters
                .drive(onNext: { [weak self] filters in
                    self?.filterHeaderView.reload(filters: filters.map { filter in
                        FilterHeaderView.ViewItem.item(title: filter)
                    })
                })
                .disposed(by: disposeBag)

        viewModel.viewItems
                .drive(onNext: { [weak self] viewItems in
                    self?.viewItems = viewItems
                    self?.tableView.reloadData()
                })
                .disposed(by: disposeBag)

        viewModel.isLoading
                .drive(onNext: { [weak self] visible in
                    self?.setSpinner(visible: visible)
                })
                .disposed(by: disposeBag)

        viewModel.error
                .drive(onNext: { [weak self] error in
                    self?.errorView.isHidden = error == nil
                    self?.errorView.text = error?.smartDescription
                })
                .disposed(by: disposeBag)
    }

    private func setSpinner(visible: Bool) {
        if visible {
            spinner.isHidden = false
            spinner.startAnimating()
        } else {
            spinner.isHidden = true
            spinner.stopAnimating()
        }
    }

}

extension GuidesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: String(describing: GuideCell.self), for: indexPath)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? GuideCell {
            let index = indexPath.row

            cell.bind(
                    viewItem: viewItems[index],
                    first: index == 0,
                    last: index == viewItems.count - 1
            )
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewItem = viewItems[indexPath.row]

        guard let url = viewItem.url else {
            return
        }

        let module = MarkdownModule.viewController(url: url)
        navigationController?.pushViewController(module, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let index = indexPath.row

        return GuideCell.height(
                containerWidth: tableView.width,
                viewItem: viewItems[index],
                first: index == 0,
                last: index == viewItems.count - 1
        )
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        filterHeaderView.headerHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        filterHeaderView
    }

}
