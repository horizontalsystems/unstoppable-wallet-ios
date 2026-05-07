import SwiftUI

struct ListSectionInfoHeader: View {
    let text: String
    let action: () -> Void

    var body: some View {
        HStack {
            Button(action: action) {
                HStack {
                    Text(text.uppercased())
                        .font(.themeSubhead1)
                        .foregroundColor(.themeGray)
                    Image("circle_information_20").themeIcon()
                }
            }
            .frame(height: .margin32)
            .padding(.padding16)

            Spacer()
        }
    }
}
