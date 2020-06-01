import UIKit
import ThemeKit
import SnapKit

class BarPageControl: UIView {
    private let barSize = CGSize(width: 20, height: 4)

    private var barViews = [UIView]()

    var currentPage: Int = 0 {
        didSet {
            updateBackgrounds()
        }
    }

    init(barCount: Int) {
        super.init(frame: .zero)

        for i in 0..<barCount {
            let barView = UIView()

            addSubview(barView)
            barView.snp.makeConstraints { maker in
                if i == 0 {
                    maker.leading.equalToSuperview()
                } else {
                    maker.leading.equalTo(barViews[i - 1].snp.trailing).offset(CGFloat.margin1x)
                }

                if i == barCount - 1 {
                    maker.trailing.equalToSuperview()
                }

                maker.size.equalTo(barSize)
            }

            barView.cornerRadius = .cornerRadius05x

            barViews.append(barView)
        }

        updateBackgrounds()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var numberOfPages: Int {
        barViews.count
    }

    private func updateBackgrounds() {
        for (index, view) in barViews.enumerated() {
            view.backgroundColor = index == currentPage ? .themeJacob : .themeSteel20
        }
    }

}
