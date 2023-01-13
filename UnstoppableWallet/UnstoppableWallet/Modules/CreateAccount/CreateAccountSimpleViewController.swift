import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ThemeKit
import ComponentKit

class CreateAccountSimpleViewController: ThemeViewController {
    private let viewModel: CreateAccountViewModel
    private let disposeBag = DisposeBag()

    private weak var listener: ICreateAccountListener?

    init(viewModel: CreateAccountViewModel, listener: ICreateAccountListener?) {
        self.viewModel = viewModel
        self.listener = listener

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.largeTitleDisplayMode = .never

        let backgroundImageView = UIImageView()

        view.addSubview(backgroundImageView)
        backgroundImageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.image = UIImage(named: "Intro - Background")

        let titleWrapper = UIView()

        view.addSubview(titleWrapper)
        titleWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide)
            maker.leading.trailing.equalToSuperview()
        }

        let titleLabel = UILabel()

        titleWrapper.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.centerY.equalToSuperview()
        }

        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.font = .title2
        titleLabel.textColor = .themeLeah
        titleLabel.text = "create_wallet.description".localized

        let createButton = PrimaryButton()

        view.addSubview(createButton)
        createButton.snp.makeConstraints { maker in
            maker.top.equalTo(titleWrapper.snp.bottom)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
        }

        createButton.set(style: .yellow)
        createButton.setTitle("create_wallet.create_button".localized, for: .normal)
        createButton.addTarget(self, action: #selector(onTapCreate), for: .touchUpInside)

        let advancedButton = PrimaryButton()

        view.addSubview(advancedButton)
        advancedButton.snp.makeConstraints { maker in
            maker.top.equalTo(createButton.snp.bottom).offset(CGFloat.margin16)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }

        advancedButton.set(style: .transparent)
        advancedButton.setTitle("create_wallet.advanced_button".localized, for: .normal)
        advancedButton.addTarget(self, action: #selector(onTapAdvanced), for: .touchUpInside)

        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.show(error: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in self?.finish() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        transitionCoordinator?.animate { [weak self] context in
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            self?.navigationController?.navigationBar.standardAppearance = appearance
            self?.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        transitionCoordinator?.animate { [weak self] context in
            self?.navigationController?.navigationBar.standardAppearance = UINavigationBar.appearance().standardAppearance
            self?.navigationController?.navigationBar.scrollEdgeAppearance = UINavigationBar.appearance().scrollEdgeAppearance
        }
    }

    @objc private func onTapCancel() {
        dismiss(animated: true)
    }

    @objc private func onTapCreate() {
        viewModel.onTapCreate()
    }

    @objc private func onTapAdvanced() {
        let module = CreateAccountModule.viewController(advanced: true, listener: listener)
        navigationController?.pushViewController(module, animated: true)
    }

    private func show(error: String) {
        HudHelper.instance.show(banner: .error(string: error))
    }

    private func finish() {
        HudHelper.instance.show(banner: .created)

        if let listener = listener {
            listener.handleCreateAccount()
        } else {
            dismiss(animated: true)
        }
    }

}
