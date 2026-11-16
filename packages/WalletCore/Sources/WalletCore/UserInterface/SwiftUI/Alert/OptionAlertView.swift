import SwiftUI

public struct OptionAlertView: View {
    let title: String
    let viewItems: [AlertViewItem]
    let onSelect: (Int) -> Void
    @Binding var isPresented: Bool

    @State private var opacity: CGFloat = 0
    @State private var backgroundOpacity: CGFloat = 0
    @State private var scale: CGFloat = 0.8

    public init(
        title: String,
        viewItems: [AlertViewItem],
        onSelect: @escaping (Int) -> Void,
        isPresented: Binding<Bool>
    ) {
        self.title = title
        self.viewItems = viewItems
        self.onSelect = onSelect
        _isPresented = isPresented
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack {
                dimView

                view
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .frame(width: 240)
                    .frame(maxHeight: max(0, proxy.size.height - 4 * .margin32))
            }
            .ignoresSafeArea()
            .transition(.opacity)
            .task {
                animate(isShown: true)
            }
        }
    }

    private var view: some View {
        VStack(spacing: 0) {
            ThemeText(title, style: .subheadSB, colorStyle: .secondary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))

            ForEach(Array(viewItems.enumerated()), id: \.offset) { index, viewItem in
                HorizontalDivider()
                row(index: index, viewItem: viewItem)
            }
        }
        .padding(.vertical, .margin8)
        .background(Color.themeLawrence)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous))
    }

    private func row(index: Int, viewItem: AlertViewItem) -> some View {
        Button(action: {
            animate(isShown: false) {
                onSelect(index)
            }
        }) {
            ThemeText(viewItem.text, style: viewItem.selected ? .headline2 : .body, colorStyle: viewItem.selected ? .brand : .primary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        }
        .buttonStyle(CellButtonStyle())
        .withIdentifier(viewItem.identifier)
    }

    private var dimView: some View {
        Color(white: 0)
            .opacity(0.5)
            .opacity(backgroundOpacity)
            .onTapGesture {
                animate(isShown: false)
            }
    }

    func animate(isShown: Bool, completion: (() -> Void)? = nil) {
        switch isShown {
        case true:
            opacity = 0

            withAnimation(.easeOut(duration: 0.2)) {
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
                isPresented = false
            }
        }
    }
}
