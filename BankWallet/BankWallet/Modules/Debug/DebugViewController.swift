import UIKit

class DebugViewController: WalletViewController {
    private let delegate: IDebugViewDelegate

    private let topView = UIView()
    private let textView = UITextView()

    private let dateFormatter = DateFormatter()

    init(delegate: IDebugViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true

        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = "yyyy/MM/dd hh:mm"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationItem.largeTitleDisplayMode = .never

        textView.backgroundColor = .clear
        textView.contentInset = UIEdgeInsets(top: 0, left: CGFloat.margin4x, bottom: 0, right: CGFloat.margin4x)
        textView.textColor = .appGray
        textView.font = .appSubhead2
        textView.isEditable = false

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    @objc private func didTapButton() {
        delegate.didTapButton(text: textView.text)
    }

    private func build(logs: [(String, Any)], indentation: String = "", bullet: String = "", level: Int = 0) -> String {
        var result = ""
        logs.forEach { key, value in
            let key = indentation + bullet + key + ": "

            if let date = value as? Date {
                result += key + dateFormatter.string(from: date) + "\n"
            } else if let string = value as? String {
                result += key + string + "\n"
            } else if let deep = value as? [(String, Any)] {
                result += key + "\n" + build(logs: deep, indentation: "    " + indentation, bullet: " - ", level: level + 1) + (level < 2 ? "\n" : "")
            }
        }

        return result
    }

}

extension DebugViewController: IDebugView {

    func set(title: String) {
        self.title = title.localized
    }

    func set(buttonTitle: String) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: buttonTitle.localized, style: .plain, target: self, action: #selector(didTapButton))
    }

    func set(logs: [String]) {
        DispatchQueue.main.async { //need to handle weird behaviour of large title in relation to UITextView
            self.textView.text = logs.joined(separator: "\n")
        }
    }

    func set(logs: [(String, Any)]) {
        DispatchQueue.main.async { //need to handle weird behaviour of large title in relation to UITextView
            self.textView.text = self.build(logs: logs)
        }
    }

}
