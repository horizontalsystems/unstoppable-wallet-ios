import UIKit
import ActionSheet
import ThemeKit
import RxSwift
import RxCocoa
import ComponentKit

class UnlinkWatchViewController: ThemeActionSheetController {
    private let viewModel: UnlinkViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: UnlinkViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let titleView = BottomSheetTitleView()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.title = "settings_manage_keys.delete.title".localized
        titleView.image = UIImage(named: "trash_24")?.withTintColor(.themeLucian)
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        let descriptionView = HighlightedDescriptionView()

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom)
        }

        descriptionView.text = "settings_manage_keys.delete.confirmation_watch".localized

        let deleteButton = PrimaryButton()

        view.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin24)
        }

        deleteButton.set(style: .red)
        deleteButton.setTitle("settings_manage_keys.delete.confirmation_watch.button".localized, for: .normal)
        deleteButton.addTarget(self, action: #selector(onTapDeleteButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.successSignal) { [weak self] in
            HudHelper.instance.show(banner: .deleted)
            self?.dismiss(animated: true)
        }
    }

    @objc private func onTapDeleteButton() {
        viewModel.onTapDelete()
    }

}
