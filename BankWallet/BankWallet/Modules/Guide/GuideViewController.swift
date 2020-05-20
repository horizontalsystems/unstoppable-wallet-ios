import UIKit
import SnapKit
import ThemeKit
import WebKit

class GuideViewController: ThemeViewController {
    private let delegate: IGuideViewDelegate

    private let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())

    init(delegate: IGuideViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
        navigationItem.largeTitleDisplayMode = .never
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(webView)
        webView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        webView.isOpaque = false

        delegate.onLoad()
    }

}

extension GuideViewController: IGuideView {

    func load(url: String) {
        if let url = URL(string: url) {
            webView.load(URLRequest(url: url))
        }
    }

}
