import SnapKit
import UIKit

class DimViewController: UIViewController {
    private var coverView: DimCoverView

    init(coverView: DimCoverView) {
        self.coverView = coverView

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(coverView)

        coverView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
    }
}

extension DimViewController {
    var onTap: (() -> Void)? {
        get { coverView.onTapCover }
        set { coverView.onTapCover = newValue }
    }
}
