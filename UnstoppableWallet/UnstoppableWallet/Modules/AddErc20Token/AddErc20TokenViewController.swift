import UIKit
import SectionsTableView
import SnapKit
import ThemeKit

class AddErc20TokenViewController: ThemeViewController {
    private let delegate: IAddErc20TokenViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: IAddErc20TokenViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "add_erc20_token.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.buildSections()
    }

    @objc func onTapCancelButton() {
        delegate.onTapCancel()
    }

}

extension AddErc20TokenViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        []
    }

}

extension AddErc20TokenViewController: IAddErc20TokenView {
}
