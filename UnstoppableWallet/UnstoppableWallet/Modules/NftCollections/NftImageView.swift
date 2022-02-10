import UIKit
import SnapKit
import ThemeKit
import Kingfisher
import WebKit

class NftImageView: UIView {
    private let imageView = UIImageView()
    private let webView = WKWebView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = false
        clipsToBounds = true

        addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .themeSteel10

        addSubview(webView)
        webView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        webView.isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(url: String?) {
        guard let urlString = url, let url = URL(string: urlString) else {
            webView.alpha = 0
            imageView.image = nil

            return
        }

        if url.pathExtension == "svg" {
            imageView.image = nil

            if let data = try? ImageCache.default.diskStorage.value(forKey: url.absoluteString), let svgString = String(data: data, encoding: .utf8) {
                webView.alpha = 1
                webView.loadHTMLString(html(svgString: svgString), baseURL: nil)
            } else {
                webView.alpha = 0

                DispatchQueue.global(qos: .utility).async {
                    if let data = try? Data(contentsOf: url), let svgString = String(data: data, encoding: .utf8) {
                        DispatchQueue.main.async {
                            self.webView.loadHTMLString(self.html(svgString: svgString), baseURL: nil)
                            UIView.animate(withDuration: 1) { self.webView.alpha = 1 }
                        }

                        try? ImageCache.default.diskStorage.store(value: data, forKey: url.absoluteString)
                    }
                }
            }
        } else {
            webView.alpha = 0
            imageView.kf.setImage(with: url, options: [.transition(.fade(0.5))])
        }
    }

    var currentImage: UIImage? {
        imageView.image
    }

}

extension NftImageView {

    func html(svgString: String) -> String {
        """
        <!DOCTYPE html>
        <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width,initial-scale=1.0">
                <title></title>
                <style type="text/css">
                    body {
                        height: 100%;
                        width: 100%;
                        position: absolute;
                        margin: 0;
                        padding: 0;
                    }
                    svg {
                        height: 100%;
                        width: 100%;
                    }
                </style>
            </head>
            <body>
                \(svgString)
            </body>
        </html>
        """
    }

}
