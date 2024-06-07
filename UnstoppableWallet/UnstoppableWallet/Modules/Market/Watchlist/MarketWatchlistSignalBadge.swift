import MarketKit
import SwiftUI

struct MarketWatchlistSignalBadge: View {
    let signal: TechnicalAdvice.Advice

    var body: some View {
        Text(signal.title)
            .font(.themeMicroSB)
            .foregroundColor(signal.foregroundColor)
            .padding(.horizontal, .margin6)
            .padding(.vertical, .margin2)
            .background(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(signal.backgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous))
    }
}
