import UIKit
import RxSwift
import ThemeKit
import ComponentKit
import SectionsTableView

class BirthdayHeightViewController: ThemeActionSheetController {
    private let blockchainImageUrl: String
    private let blockchainName: String
    private let birthdayHeight: String
    private let disposeBag = DisposeBag()

    private let titleView = BottomSheetTitleView()
    private let tableView = SelfSizedSectionsTableView(style: .grouped)

    init(blockchainImageUrl: String, blockchainName: String, birthdayHeight: String) {
        self.blockchainImageUrl = blockchainImageUrl
        self.blockchainName = blockchainName
        self.birthdayHeight = birthdayHeight

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
                image: .remote(url: blockchainImageUrl, placeholder: nil),
                title: blockchainName,
                viewController: self
        )

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(titleView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionDataSource = self

        tableView.buildSections()
    }

}

extension BirthdayHeightViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let birthdayHeight = birthdayHeight

        return [
            Section(
                    id: "main",
                    headerState: .margin(height: .margin12),
                    rows: [
                        CellBuilderNew.row(
                                rootElement: .hStack([
                                    .text { component in
                                        component.font = .body
                                        component.textColor = .themeLeah
                                        component.text = "birthday_height.title".localized
                                    },
                                    .secondaryButton { component in
                                        component.button.set(style: .default)
                                        component.button.setTitle(birthdayHeight, for: .normal)
                                        component.onTap = {
                                            CopyHelper.copyAndNotify(value: birthdayHeight)
                                        }
                                    }
                                ]),
                                tableView: tableView,
                                id: "birthday-height",
                                height: .heightCell48,
                                bind: { cell in
                                    cell.set(backgroundStyle: .bordered, isFirst: true, isLast: true)
                                }
                        )
                    ]
            )
        ]
    }

}
