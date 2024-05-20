import SwiftUI
import ThemeKit

struct BadgeViewNew: View {
    private let text: String
    private let change: Int?

    init(text: String, change: Int? = nil) {
        self.text = text
        self.change = change
    }

    var body: some View {
        HStack(spacing: .margin2) {
            Text(text.uppercased())
                .font(.themeMicroSB)
                .foregroundColor(.themeBran)

            if let change, change != 0 {
                if change > 0 {
                    Text(verbatim: "↑\(change)")
                        .font(.themeMicroSB)
                        .foregroundColor(.themeRemus)
                } else {
                    Text(verbatim: "↓\(abs(change))")
                        .font(.themeMicroSB)
                        .foregroundColor(.themeLucian)
                }
            }
        }
        .padding(.horizontal, .margin4)
        .padding(.vertical, .margin2)
        .background(RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous).fill(Color.themeJeremy))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius4, style: .continuous))
    }
}
