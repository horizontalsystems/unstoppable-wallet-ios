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

        imageView.contentMode = .scaleAspectFit
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

    func set(nftImage: NftImage) {
        switch nftImage {
        case .image(let image):
            imageView.image = image
            webView.alpha = 0
        case .svg(let string):
            imageView.image = nil
            webView.alpha = 0
            webView.loadHTMLString(html(svgString: string), baseURL: nil)
            UIView.animate(withDuration: 1) { self.webView.alpha = 1 }
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
