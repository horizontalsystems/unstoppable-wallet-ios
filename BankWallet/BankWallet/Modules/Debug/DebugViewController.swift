import UIKit

class DebugViewController: WalletViewController {
    private let delegate: IDebugViewDelegate

    private let topView = UIView()
    private let textView = UITextView()
    private let clearButton = UIButton.appYellow

    init(delegate: IDebugViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Debug".localized

        view.addSubview(topView)
        topView.snp.makeConstraints { maker in
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.zero)
        }

        textView.backgroundColor = .clear
        textView.contentInset = UIEdgeInsets(top: 0, left: CGFloat.margin4x, bottom: 0, right: CGFloat.margin4x)
        textView.textColor = .appOz
        textView.font = .appBody
        textView.isEditable = false

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.top.equalTo(topView.snp.bottom).offset(CGFloat.margin4x)
            maker.leading.trailing.equalToSuperview()
        }

        clearButton.setTitle("Clear".localized, for: .normal)
        clearButton.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)

        view.addSubview(clearButton)
        clearButton.snp.makeConstraints { maker in
            maker.top.equalTo(textView.snp.bottom).offset(CGFloat.margin8x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.marginButtonSide)
            maker.height.equalTo(CGFloat.heightButton)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin8x)
        }


        delegate.viewDidLoad()
    }

    @objc private func didTapClear() {
        delegate.didTapClear()
    }

}

extension DebugViewController: IDebugView {

    func set(logs: [String]) {
        textView.text = logs.joined(separator: "\n")
        textView.setContentOffset(.zero, animated: true)
    }



    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
