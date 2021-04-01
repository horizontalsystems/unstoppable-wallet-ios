import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import PinKit

class BackupConfirmKeyViewController: ThemeViewController {
    private let viewModel: BackupConfirmKeyViewModel
    private let disposeBag = DisposeBag()

    private let firstIndexedInputField = IndexedInputField()
    private let secondIndexedInputField = IndexedInputField()

    private let descriptionLabel = UILabel()

    init(viewModel: BackupConfirmKeyViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.confirmation.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))

        view.addSubview(firstIndexedInputField)
        firstIndexedInputField.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(CGFloat.margin12)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        firstIndexedInputField.textField.returnKeyType = .next
        firstIndexedInputField.onReturn = { [weak self] in
            self?.secondIndexedInputField.textField.becomeFirstResponder()
        }
        firstIndexedInputField.cornerRadius = CGFloat.cornerRadius8
        firstIndexedInputField.borderColor = .themeSteel20
        firstIndexedInputField.borderWidth = 1 / UIScreen.main.scale

        view.addSubview(secondIndexedInputField)
        secondIndexedInputField.snp.makeConstraints { maker in
            maker.top.equalTo(self.firstIndexedInputField.snp.bottom).offset(CGFloat.margin16)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        secondIndexedInputField.textField.returnKeyType = .done
        secondIndexedInputField.onReturn = { [weak self] in
            self?.onTapDoneButton()
        }
        secondIndexedInputField.cornerRadius = CGFloat.cornerRadius8
        secondIndexedInputField.borderColor = .themeSteel20
        secondIndexedInputField.borderWidth = 1 / UIScreen.main.scale

        view.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.secondIndexedInputField.snp.bottom).offset(CGFloat.margin12)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.text = "backup_key.confirmation.description".localized
        descriptionLabel.font = .subhead2
        descriptionLabel.textColor = .themeGray

        subscribe(disposeBag, viewModel.indexViewItemDriver) { [weak self] in self?.sync(indexViewItem: $0) }
        subscribe(disposeBag, viewModel.showErrorSignal) { HudHelper.instance.showError(title: $0) }
        subscribe(disposeBag, viewModel.successSignal) { [weak self] in
            HudHelper.instance.showSuccess()
            self?.dismiss(animated: true)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewModel.onViewAppear()

        firstIndexedInputField.textField.becomeFirstResponder()
    }

    @objc private func onTapDoneButton() {
        let firstWord = firstIndexedInputField.textField.text ?? ""
        let secondWord = secondIndexedInputField.textField.text ?? ""

        viewModel.onTapDone(firstWord: firstWord, secondWord: secondWord)
    }

    private func sync(indexViewItem: BackupConfirmKeyViewModel.IndexViewItem) {
        firstIndexedInputField.indexLabel.text = indexViewItem.first
        secondIndexedInputField.indexLabel.text = indexViewItem.second
    }

}
