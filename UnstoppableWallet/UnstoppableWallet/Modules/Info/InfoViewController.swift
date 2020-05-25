import UIKit
import SnapKit
import ThemeKit

class InfoViewController: ThemeViewController {
    private let viewTitle: String
    private let viewText: String

    init(title: String, text: String) {
        self.viewTitle = title
        self.viewText = text
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewTitle.localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))

        let scrollView = UIScrollView()

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview()
        }

        let container = UIView()

        scrollView.addSubview(container)
        container.snp.makeConstraints { maker in
            maker.top.bottom.equalTo(scrollView)
            maker.leading.trailing.equalTo(view)
        }

        let textLabel = UILabel()
        textLabel.text = viewText.localized
        textLabel.numberOfLines = 0
        textLabel.font = .subhead2
        textLabel.textColor = .themeGray

        container.addSubview(textLabel)
        textLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin8x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }
    }

    @objc func onClose() {
        dismiss(animated: true)
    }

}
