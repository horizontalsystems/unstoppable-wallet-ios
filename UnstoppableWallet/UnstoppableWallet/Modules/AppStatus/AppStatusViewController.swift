import UIKit
import ThemeKit

class AppStatusViewController: ThemeViewController {
    private let delegate: IAppStatusViewDelegate

    private let textView = UITextView.appDebug

    private let dateFormatter = DateFormatter()

    init(delegate: IAppStatusViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true

        dateFormatter.dateFormat = "dd MMM yyyy, HH:mm"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "app_status.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.copy".localized, style: .plain, target: self, action: #selector(didTapButton))

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    @objc private func didTapButton() {
        delegate.onCopy(text: textView.text)
    }

    private func build(logs: [(String, Any)], indentation: String = "", bullet: String = "", level: Int = 0) -> String {
        var result = ""

        logs.forEach { key, value in
            let key = (indentation + bullet + key + ": ").capitalized

            if let date = value as? Date {
                result += key + dateFormatter.string(from: date) + "\n"
            } else if let string = value as? String {
                result += key + string + "\n"
            } else if let int = value as? Int {
                result += key + "\(int)" + "\n"
            } else if let int = value as? Int32 {
                result += key + "\(int)" + "\n"
            } else if let deep = value as? [String] {
                result += key + "\n"
                deep.forEach { str in
                    result += indentation + "    " + bullet + str + "\n"
                }
            } else if let deep = value as? [(String, Any)] {
                result += key + "\n" + build(logs: deep, indentation: "    " + indentation, bullet: " - ", level: level + 1) + (level < 2 ? "\n" : "")
            }
        }

        return result
    }

}

extension AppStatusViewController: IAppStatusView {

    func set(logs: [(String, Any)]) {
        DispatchQueue.main.async { //need to handle weird behaviour of large title in relation to UITextView
            self.textView.text = self.build(logs: logs)
        }
    }

}
