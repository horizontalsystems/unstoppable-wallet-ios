import UIKit
import ThemeKit

class DebugViewController: ThemeViewController {
    private let delegate: IDebugViewDelegate

    private let textView = UITextView.appDebug

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

        title = "Debug"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(didTapButton))

        view.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    @objc private func didTapButton() {
        delegate.onClear()
    }

}

extension DebugViewController: IDebugView {

    func set(logs: [String]) {
        DispatchQueue.main.async { //need to handle weird behaviour of large title in relation to UITextView
            self.textView.text = logs.joined(separator: "\n")
        }
    }

}
