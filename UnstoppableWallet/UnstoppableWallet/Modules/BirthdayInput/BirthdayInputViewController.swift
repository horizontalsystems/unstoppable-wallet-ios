import UIKit
import ThemeKit
import SnapKit
import MarketKit
import ComponentKit

protocol IBirthdayInputDelegate: AnyObject {
    func didEnter(birthdayHeight: Int?)
    func didCancelEnterBirthdayHeight()
}

class BirthdayInputViewController: ThemeActionSheetController {
    private let token: Token
    private weak var delegate: IBirthdayInputDelegate?

    private let heightInputView = InputView()
    private let checkboxView = CheckboxView()
    private let checkboxButton = UIButton()

    private var didTapDone = false

    init(token: Token, delegate: IBirthdayInputDelegate) {
        self.token = token
        self.delegate = delegate

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

        titleView.bind(
                title: "birthday_input.title".localized,
                subtitle: token.coin.name,
                image: UIImage(named: "zcash_24")?.withTintColor(.themeJacob)
        )
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        let descriptionLabel = UILabel()

        view.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
        }

        descriptionLabel.text = "birthday_input.description".localized
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .subhead2
        descriptionLabel.textColor = .themeGray

        view.addSubview(heightInputView)
        heightInputView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(descriptionLabel.snp.bottom).offset(CGFloat.margin24)
        }

        heightInputView.inputPlaceholder = "birthday_input.input_placeholder".localized("000000000")
        heightInputView.keyboardType = .numberPad
        heightInputView.isValidText = { Int($0) != nil }

        let separatorView = UIView()

        view.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(heightInputView.snp.bottom).offset(CGFloat.margin12)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        separatorView.backgroundColor = .themeSteel10

        view.addSubview(checkboxView)

        let text = "birthday_input.new_wallet".localized
        let height = CheckboxView.height(containerWidth: view.width, text: text)

        checkboxView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(separatorView.snp.bottom)
            maker.height.equalTo(height)
        }

        checkboxView.text = text
        checkboxView.textColor = .themeLeah
        checkboxView.checked = false

        checkboxView.addSubview(checkboxButton)
        checkboxButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        checkboxButton.addTarget(self, action: #selector(onTapCheckBox), for: .touchUpInside)

        let secondSeparatorView = UIView()

        view.addSubview(secondSeparatorView)
        secondSeparatorView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(checkboxView.snp.bottom)
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        secondSeparatorView.backgroundColor = .themeSteel10

        let doneButton = ThemeButton()

        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(secondSeparatorView.snp.bottom).offset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        doneButton.apply(style: .primaryYellow)
        doneButton.setTitle("button.done".localized, for: .normal)
        doneButton.addTarget(self, action: #selector(onTapDoneButton), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        _ = heightInputView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !didTapDone {
            delegate?.didCancelEnterBirthdayHeight()
        }
    }

    @objc private func onTapCheckBox() {
        checkboxView.checked = !checkboxView.checked

        heightInputView.isEnabled = !checkboxView.checked
        heightInputView.textColor = checkboxView.checked ? .themeGray : .themeOz
    }

    @objc private func onTapDoneButton() {
        if checkboxView.checked {
            delegate?.didEnter(birthdayHeight: nil)
        } else {
            let birthdayHeight = heightInputView.inputText.flatMap { Int($0) } ?? 0
            delegate?.didEnter(birthdayHeight: birthdayHeight)
        }

        didTapDone = true
        dismiss(animated: true)
    }

}
