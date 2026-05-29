import SwiftUI

struct MarqueeView<Content: View>: View {
    let content: Content

    @State private var containerWidth: CGFloat? = nil
    @State private var model: Model

    private var targetVelocity: Double
    private var spacing: CGFloat

    init(targetVelocity: Double, spacing: CGFloat = .margin8, @ViewBuilder content: () -> Content) {
        self.content = content()
        _model = .init(wrappedValue: Model(targetVelocity: targetVelocity, spacing: spacing))
        self.targetVelocity = targetVelocity
        self.spacing = spacing
    }

    var body: some View {
        TimelineView(.animation) { context in
            HStack(spacing: model.spacing) {
                HStack(spacing: model.spacing) {
                    content
                }
                .measureWidth { model.contentWidth = $0 }

                ForEach(Array(0 ..< extraContentInstances), id: \.self) { _ in
                    content
                }
            }
            .offset(x: model.offset)
            .fixedSize()
            .onChange(of: context.date) { newDate in
                DispatchQueue.main.async {
                    model.tick(at: newDate)
                }
            }
        }
        .measureWidth { containerWidth = $0 }
        .gesture(dragGesture)
        .onAppear { model.previousTick = .now }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    private var extraContentInstances: Int {
        let contentPlusSpacing = ((model.contentWidth ?? 0) + model.spacing)

        guard contentPlusSpacing != 0 else {
            return 1
        }

        return Int(((containerWidth ?? 0) / contentPlusSpacing).rounded(.up))
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                model.dragChanged(value)
            }.onEnded { value in
                model.dragEnded(value)
            }
    }
}

extension MarqueeView {
    struct Model {
        var contentWidth: CGFloat?
        var offset: CGFloat
        var dragStartOffset: CGFloat?
        var dragTranslation: CGFloat = 0
        var currentVelocity: CGFloat = 0

        var previousTick: Date = .now
        var targetVelocity: Double
        var spacing: CGFloat

        init(targetVelocity: Double, spacing: CGFloat) {
            self.targetVelocity = targetVelocity
            self.spacing = spacing

            offset = spacing
        }

        mutating func tick(at time: Date) {
            let delta = time.timeIntervalSince(previousTick)

            defer { previousTick = time }

            currentVelocity += (targetVelocity - currentVelocity) * delta * 3

            if let dragStartOffset {
                offset = dragStartOffset + dragTranslation
            } else {
                offset -= delta * currentVelocity
            }

            if let c = contentWidth {
                offset.formTruncatingRemainder(dividingBy: c + spacing)

                while offset > 0 {
                    offset -= c + spacing
                }
            }
        }

        mutating func dragChanged(_ value: DragGesture.Value) {
            if dragStartOffset == nil {
                dragStartOffset = offset
            }

            dragTranslation = value.translation.width
        }

        mutating func dragEnded(_ value: DragGesture.Value) {
            guard let dragStartOffset else {
                return
            }

            offset = dragStartOffset + value.translation.width

            self.dragStartOffset = nil

            currentVelocity = (value.location.x - value.predictedEndLocation.x) * 3
        }
    }
}

extension View {
    func measureWidth(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background {
            GeometryReader { proxy in
                let width = proxy.size.width

                Color.clear
                    .onAppear {
                        DispatchQueue.main.async {
                            onChange(width)
                        }
                    }.onChange(of: width) {
                        onChange($0)
                    }
            }
        }
    }
}
