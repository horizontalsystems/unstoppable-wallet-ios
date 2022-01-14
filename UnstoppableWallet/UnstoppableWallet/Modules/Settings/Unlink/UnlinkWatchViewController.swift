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

        titleView.onTapClose = { [weak self] in self?.dismiss(animated: true) }
        titleView.bind(
                title: "settings_manage_keys.delete.title".localized,
                subtitle: viewModel.accountName,
                image: UIImage(named: "warning_2_24"),
                tintColor: .themeLucian
        )

        let descriptionView = HighlightedDescriptionView()

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
        }

        descriptionView.text = "settings_manage_keys.delete.confirmation_watch".localized

        let separatorView = UIView()

        view.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin12)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10

        let deleteButton = ThemeButton()

        view.addSubview(deleteButton)
        deleteButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(separatorView.snp.bottom).offset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        deleteButton.apply(style: .primaryRed)
        deleteButton.setTitle("security_settings.delete_alert_button".localized, for: .normal)
        deleteButton.addTarget(self, action: #selector(onTapDeleteButton), for: .touchUpInside)

        subscribe(disposeBag, viewModel.successSignal) { [weak self] in
            HudHelper.instance.showSuccess(title: "alert.success_action".localized)
            self?.dismiss(animated: true)
        }
    }

    @objc private func onTapDeleteButton() {
        viewModel.onTapDelete()
    }

}
