import UIKit

import Combine
import ComponentKit
import Foundation
import HUD
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class ErrorViewController: ThemeViewController {
    private let placeholderView = PlaceholderView()
    private let text: String?

    init(text: String?) {
        self.text = text

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "alert.error".localized

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(placeholderView)
        placeholderView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        placeholderView.image = UIImage(named: "not_found_48")?.withTintColor(.themeGray)
        placeholderView.text = text
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }
}
