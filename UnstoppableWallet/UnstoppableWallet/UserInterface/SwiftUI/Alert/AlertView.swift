import SwiftUI

struct ButtonsAlertView: View {
    @State private var opacity: CGFloat = 0
    @State private var backgroundOpacity: CGFloat = 0
    @State private var scale: CGFloat = 0.8

    @Environment(\.dismiss) private var dismiss

    let title: String
    let buttons: [AlertViewItem]
    let onTap: ((Int?) -> Void)?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                dimView

                view
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .frame(maxWidth: proxy.size.width - 2 * .margin32, maxHeight: proxy.size.height - 4 * .margin32)
            }
            .ignoresSafeArea()
            .transition(.opacity)
            .task {
                animate(isShown: true)
            }
        }
    }

    private var view: some View {
        ListSection {
            Text(title)
                .textSubhead1()
                .frame(alignment: .center)
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin12)

            ForEach(Array(buttons.enumerated()), id: \.offset) { index, button in
                ListRow {
                    Button(action: {
                        animate(isShown: false) {
                            onTap?(index)
                        }
                    }, label: {
                        view(item: button)
                    })
                    .disabled(button.disabled)
                }
            }
        }
        .background(Color.themeLawrence)
        .cornerRadius(.cornerRadius16)
    }

    private func view(item: AlertViewItem) -> some View {
        HStack {
            VStack(spacing: 1) {
                Text(item.text)
                    .textBody(color: item.selected ? .themeJacob : .themeLeah)

                if let description = item.description {
                    Text(description)
                        .textSubhead1()
                }
            }
        }
    }

    private var dimView: some View {
        Color(white: 0)
            .opacity(0.5)
            .opacity(backgroundOpacity)
            .onTapGesture {
                animate(isShown: false) {
                    onTap?(nil)
                }
            }
    }

    func animate(isShown: Bool, completion: (() -> Void)? = nil) {
        switch isShown {
        case true:
            opacity = 0

            withAnimation(.spring(response: 0.3, dampingFraction: 0.9, blendDuration: 0).delay(0.2)) {
                opacity = 1
                backgroundOpacity = 1
                scale = 1
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                completion?()
            }

        case false:
            withAnimation(.easeOut(duration: 0.2)) {
                backgroundOpacity = 0
                opacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                completion?()
                dismiss()
            }
        }
    }
}

extension View {
    func alert(isPresented: Binding<Bool>, title: String, viewItems: [AlertViewItem], onTap: ((Int?) -> Void)? = nil) -> some View {
        transparentFullScreenCover(isPresented: isPresented) {
            ButtonsAlertView(title: title, buttons: viewItems, onTap: onTap)
        }
    }
}
