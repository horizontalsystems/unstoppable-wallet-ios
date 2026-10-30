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
        ListSection {
            Text(title)
                .textSubhead1()
                .frame(alignment: .center)
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin12)

            ForEach(Array(viewItems.enumerated()), id: \.offset) { index, viewItem in
                let cell = Cell(
                    middle: {
                        VStack(spacing: 1) {
                            ThemeText(viewItem.text, style: .body, colorStyle: viewItem.selected ? .yellow : .primary, dimmed: viewItem.disabled)

                            if let description = viewItem.description {
                                ThemeText(description, style: .subhead, dimmed: viewItem.disabled)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    },
                    action: {
                        animate(isShown: false) {
                            onSelect(index)
                        }
                    }
                )

                if let identifier = viewItem.identifier {
                    cell
                        .accessibilityIdentifier(identifier)
                        .disabled(viewItem.disabled)
                } else {
                    cell
                        .disabled(viewItem.disabled)
                }
            }
        }
        .background(Color.themeLawrence)
        .cornerRadius(.cornerRadius16)
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
