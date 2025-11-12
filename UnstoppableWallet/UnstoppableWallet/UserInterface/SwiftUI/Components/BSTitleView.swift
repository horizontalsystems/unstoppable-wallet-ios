import Kingfisher
import SwiftUI

struct BSTitleView: View {
    private let showGrabber: Bool
    private let icon: CustomStringConvertible?
    private let title: CustomStringConvertible

    private let showDismiss: Bool
    @Binding var isPresented: Bool

    init(showGrabber: Bool = true, icon: CustomStringConvertible? = nil, title: CustomStringConvertible, subtitle _: CustomStringConvertible? = nil, isPresented: Binding<Bool>? = nil) {
        self.showGrabber = showGrabber
        self.icon = icon
        self.title = title

        // TODO: use if needed
        showDismiss = isPresented != nil
        _isPresented = isPresented ?? .constant(true)
    }

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

            if let icon {
                ThemeImage(icon, size: .iconSize72)
                    .padding(.top, .margin16)
                    .padding(.bottom, .margin8)
            }

            ThemeText(title, style: .headline1)
                .padding(.top, .margin16)
                .padding(.bottom, .margin8)
        }
        .padding(.horizontal, .margin48)
    }
}
