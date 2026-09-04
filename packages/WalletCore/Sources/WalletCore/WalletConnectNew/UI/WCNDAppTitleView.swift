import Kingfisher
import SwiftUI

// BSTitleView layout with a rounded remote dApp icon; ThemeImage does not clip remote images
struct WCNDAppTitleView: View {
    let iconUrl: String?
    let title: String
    var showGrabber = false

    var body: some View {
        VStack(spacing: 0) {
            if showGrabber {
                Rectangle()
                    .fill(Color.themeBlade)
                    .frame(width: 52, height: 4)
                    .cornerRadius(2)
                    .padding(.top, .margin8)
                    .padding(.bottom, .margin12)
            }

            KFImage.url(iconUrl.flatMap { URL(string: $0) })
                .resizable()
                .placeholder { RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous).fill(Color.themeBlade) }
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous))
                .frame(width: .iconSize72, height: .iconSize72)
                .padding(.top, .margin16)
                .padding(.bottom, .margin8)

            ThemeText(title, style: .headline1)
                .padding(.top, .margin16)
                .padding(.bottom, .margin8)
        }
        .padding(.horizontal, .margin48)
    }
}
