import SwiftUI

/// The breathing bottom glow of the welcome and the cover. A pure function of the time since the start,
/// drawn in a `Canvas`. No blur filters: every blurred circle of the design is baked into a radial gradient.
enum WelcomeGlow {
    /// Seconds per breath in the idle state.
    private static let breath: Double = 5.2
    /// A moment where everything has settled; used for the static glow.
    fileprivate static let restTime: Double = 10.4

    /// Reference artboard the blob numbers were measured in.
    private static let refWidth: Double = 393
    private static let refHeight: Double = 852

    private struct Blob {
        let color: Color
        /// Centre Y in the artboard (the glow is anchored to the bottom edge).
        let centerY: Double
        /// Circle radius + 3 sigma of its blur, in artboard points.
        let outerRadius: Double
        let opacity: Double
        /// Breathing: scale amplitude, vertical lift (pt), horizontal drift (pt) and its period (s).
        let scaleAmp: Double
        let lift: Double
        let drift: Double
        let driftPeriod: Double
        /// Phase lag of this layer inside the breath (rad).
        let phase: Double
        /// How strongly the layer answers a pulse.
        let pulseGain: Double
        /// Alpha profile of the blurred circle from the centre to `outerRadius`.
        let gradient: Gradient

        init(color: Color, centerY: Double, outerRadius: Double, alphaStops: [Double], opacity: Double, scaleAmp: Double, lift: Double, drift: Double, driftPeriod: Double, phase: Double, pulseGain: Double) {
            self.color = color
            self.centerY = centerY
            self.outerRadius = outerRadius
            self.opacity = opacity
            self.scaleAmp = scaleAmp
            self.lift = lift
            self.drift = drift
            self.driftPeriod = driftPeriod
            self.phase = phase
            self.pulseGain = pulseGain

            let n = Double(max(alphaStops.count - 1, 1))
            gradient = Gradient(stops: alphaStops.enumerated().map { index, alpha in
                .init(color: color.opacity(alpha), location: Double(index) / n)
            })
        }
    }

    /// Back to front, same order as in the design.
    private static let blobs: [Blob] = [
        // #FF0000, circle r190, blur sigma 150, layer opacity 0.6
        Blob(
            color: Color(red: 1, green: 0, blue: 0),
            centerY: 759, outerRadius: 640,
            alphaStops: [0.5517, 0.5294, 0.4673, 0.3787, 0.2808, 0.1897, 0.1163, 0.0644, 0.0322, 0.0144, 0.0058, 0.0021, 0],
            opacity: 0.6, scaleAmp: 0.07, lift: 18, drift: 10, driftPeriod: 11, phase: 0.0, pulseGain: 0.6
        ),
        // #FFBB00, circle r130, blur sigma 50, layer opacity 1
        Blob(
            color: Color(red: 1, green: 187 / 255, blue: 0),
            centerY: 913, outerRadius: 280,
            alphaStops: [0.9660, 0.9530, 0.9091, 0.8236, 0.6911, 0.5230, 0.3483, 0.2000, 0.0975, 0.0399, 0.0135, 0.0038, 0],
            opacity: 1.0, scaleAmp: 0.16, lift: 34, drift: 22, driftPeriod: 13, phase: 1.4, pulseGain: 1.3
        ),
        // #FE4A11, circle r160, blur sigma 100, layer opacity 0.8
        Blob(
            color: Color(red: 254 / 255, green: 74 / 255, blue: 17 / 255),
            centerY: 838, outerRadius: 460,
            alphaStops: [0.7220, 0.6962, 0.6229, 0.5143, 0.3888, 0.2669, 0.1650, 0.0912, 0.0448, 0.0194, 0.0074, 0.0025, 0],
            opacity: 0.8, scaleAmp: 0.10, lift: 26, drift: 16, driftPeriod: 9, phase: 0.7, pulseGain: 0.9
        ),
    ]

    /// Moments when content appears and the glow "inhales", taken from the welcome timeline.
    private static let pulses: [(at: Double, strength: Double)] = WelcomeTimeline.Step.allCases.compactMap { step in
        step.pulseStrength.map { (at: step.time, strength: $0) }
    }

    /// Pulse energy at time `t`: each pulse has a soft attack (0.18 s) and a slow release (0.8 s).
    private static func pulseEnergy(at t: Double) -> Double {
        let release = 0.8
        let attack = 0.18
        var energy = 0.0

        for pulse in pulses where t > pulse.at {
            let d = t - pulse.at
            energy += pulse.strength * release / (release - attack) * (exp(-d / release) - exp(-d / attack))
        }

        return energy
    }

    fileprivate static func draw(in context: inout GraphicsContext, size: CGSize, time t: Double) {
        let k = Double(size.width) / refWidth
        let x01 = min(max((t - 0.1) / 1.8, 0), 1)
        let ignite = 1 - pow(1 - x01, 3)
        let energy = pulseEnergy(at: t)

        for blob in blobs {
            let w = sin(2 * .pi * t / breath - blob.phase)
            let scale = (0.55 + 0.45 * ignite)
                * (1 + blob.scaleAmp * w * ignite)
                * (1 + 0.16 * blob.pulseGain * energy)
            let dy = (1 - ignite) * 240 - blob.lift * w * ignite - 46 * blob.pulseGain * energy
            let dx = blob.drift * sin(2 * .pi * t / blob.driftPeriod + 2 * blob.phase) * ignite
            let alpha = min(1, blob.opacity * ignite * (1 - 0.10 * (1 - w) / 2))

            let center = CGPoint(
                x: Double(size.width) / 2 + dx * k,
                y: Double(size.height) - (refHeight - blob.centerY - dy) * k
            )
            let r = CGFloat(blob.outerRadius * scale * k)
            let rect = CGRect(x: center.x - r, y: center.y - r, width: 2 * r, height: 2 * r)

            var layer = context
            layer.opacity = alpha
            layer.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(blob.gradient, center: center, startRadius: 0, endRadius: r)
            )
        }
    }
}

struct WelcomeGlowView: View {
    /// The moment the welcome started; `nil` draws the static glow at rest.
    private let start: Date?

    init(start: Date?) {
        self.start = start
    }

    var body: some View {
        Group {
            if let start {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        WelcomeGlow.draw(in: &context, size: size, time: timeline.date.timeIntervalSince(start))
                    }
                }
            } else {
                Canvas { context, size in
                    WelcomeGlow.draw(in: &context, size: size, time: WelcomeGlow.restTime)
                }
            }
        }
        .background(Color.themeTyler)
        .ignoresSafeArea()
    }
}
