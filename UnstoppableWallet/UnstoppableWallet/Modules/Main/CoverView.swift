import SwiftUI

struct CoverView: View {
    var body: some View {
        ThemeView {
            VStack(spacing: .margin24) {
                Image(AppIconManager.currentAppIcon.imageName)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
                    .frame(width: 60, height: 60)

                Text(AppConfig.appName)
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
            }
        }
    }
}
