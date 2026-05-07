import SwiftUI

struct HighlightedTitledTextView: View {
    private let title: String
    private let text: String
    private let cautionType: CautionType

    init(caution: TitledCaution) {
        title = caution.title
        text = caution.text
        cautionType = caution.type
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image("warning_2_20").themeIcon(color: Color(cautionType.labelColor))

                Text(title)
                    .textBody(color: Color(cautionType.labelColor))
                    .font(.themeSubhead1)
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: 0, trailing: .margin16))

            Text(text)
                .textBody(color: .themeBran)
                .font(.themeSubhead2)
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(Color(cautionType.borderColor).opacity(0.2)))
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).stroke(Color(cautionType.borderColor), lineWidth: .heightOneDp)
        )
    }
}
