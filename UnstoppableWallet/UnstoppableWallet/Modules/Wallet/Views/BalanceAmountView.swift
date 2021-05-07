import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class BalanceAmountView: UIView {
    static let height: CGFloat = 32

    private let balanceView = BalanceDoubleRowView()

    private let syncingLabel = UILabel()
    private let syncedUntilLabel = UILabel()

    init() {
        super.init(frame: .zero)

        addSubview(balanceView)
        balanceView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        addSubview(syncingLabel)
        syncingLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin1x)
            maker.top.equalToSuperview().offset(11)
        }

        syncingLabel.font = .subhead2
        syncingLabel.textColor = .themeGray

        addSubview(syncedUntilLabel)
        syncedUntilLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(syncingLabel.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin1x)
            maker.bottom.equalTo(syncingLabel.snp.bottom)
        }

        syncedUntilLabel.font = .subhead2
        syncedUntilLabel.textColor = .themeGray
        syncedUntilLabel.textAlignment = .right
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: BalanceAmountViewItem?, animated: Bool = false, duration: TimeInterval = 0.2) {
        guard let viewItem = viewItem else {
            balanceView.set(hidden: true, animated: animated, duration: duration)
            syncingLabel.set(hidden: true, animated: animated, duration: duration)
            syncedUntilLabel.set(hidden: true, animated: animated, duration: duration)
            return
        }

        switch viewItem {
        case let .amount(coinValue, currencyValue):
            balanceView.set(hidden: false, animated: animated, duration: duration)
            balanceView.bind(coinValue: coinValue, currencyValue: currencyValue, animated: animated)

            syncingLabel.set(hidden: true, animated: animated, duration: duration)
            syncedUntilLabel.set(hidden: true, animated: animated, duration: duration)
        case let .searchingTx(count):
            balanceView.set(hidden: true, animated: animated, duration: duration)
            syncingLabel.text = "balance.searching".localized()

            if count > 0 {
                syncedUntilLabel.text = "balance.searching.count".localized("\(count)")
                syncedUntilLabel.set(hidden: false, animated: animated, duration: duration)
            } else {
                syncedUntilLabel.set(hidden: true, animated: animated, duration: duration)
            }

            syncingLabel.set(hidden: false, animated: animated, duration: duration)
        case let .syncing(progress, syncedUntil):
            balanceView.set(hidden: true, animated: animated, duration: duration)

            if let progress = progress {
                syncingLabel.text = "balance.syncing_percent".localized("\(progress)%")
            } else {
                syncingLabel.text = "balance.syncing".localized
            }

            if let syncedUntil = syncedUntil {
                syncedUntilLabel.text = "balance.synced_through".localized(syncedUntil)
            } else {
                syncedUntilLabel.text = nil
            }

            syncingLabel.set(hidden: false, animated: animated, duration: duration)
            syncedUntilLabel.set(hidden: false, animated: animated, duration: duration)
        }
    }

}
