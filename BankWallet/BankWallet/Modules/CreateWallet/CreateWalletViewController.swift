import UIKit
import SectionsTableView

class CreateWalletViewController: WalletViewController {
    private let delegate: ICreateWalletViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: ICreateWalletViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "create_wallet.title".localized

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
        tableView.buildSections()
    }

}

extension CreateWalletViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        return [
        ]
    }

}

extension CreateWalletViewController: ICreateWalletView {

    func set(viewItems: [CreateWalletViewItem]) {
    }

    func set(createButtonEnabled: Bool) {
    }

}
