import MarketKit
import SwiftUI

struct TokenSelectorButton: View {
    let token: Token?
    var action: (() -> Void)? = nil

    var body: some View {
        if let action {
            Button(action: action) {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 16) {
            CoinIconView(token: token)

            HStack(spacing: 8) {
                if let token {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(token.coin.code).textHeadline1()
                        BadgeViewNew(token.fullBadge)
                    }
                } else {
                    Text("token_selector.select".localized).textHeadline2(color: .themeJacob)
                }

                if action != nil {
                    ThemeImage("arrow_s_down", size: 20, colorStyle: .primary)
                }
            }
        }
    }
}
