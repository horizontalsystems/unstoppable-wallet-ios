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
                    .padding(EdgeInsets(top: 0, leading: .margin16, bottom: 0, trailing: .margin16))

            Spacer()
        }
    }

}
