import CoreMotion
import SwiftUI

/// Pure helpers for the tilt effect, so they can be tested.
enum TiltMath {
    /// Maps an angle (radians) to -1...1, reaching the edge at `range`.
    static func normalize(_ angle: Double, range: Double) -> Double {
        guard range > 0 else { return 0 }
        return min(max(angle / range, -1), 1)
    }

    /// Low-pass filter so the shelf glides instead of jittering.
    static func smooth(current: CGSize, target: CGSize, factor: Double) -> CGSize {
        CGSize(
            width: current.width + (target.width - current.width) * factor,
            height: current.height + (target.height - current.height) * factor
        )
    }
}

/// Reads the phone's tilt. `value.width` is left/right, `value.height` forward/back, both -1...1.
/// No permission prompt is needed for device motion.
@MainActor
@Observable
final class TiltMotion {
    static let enabledKey = "shelfTiltEnabled"

    private(set) var value: CGSize = .zero

    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var baselinePitch: Double?

    init() {
        if let fixed = LaunchOptions.fixedTilt {
            value = CGSize(width: fixed, height: fixed * 0.3)
        }
    }

    func start() {
        guard LaunchOptions.fixedTilt == nil,
              manager.isDeviceMotionAvailable,
              !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let attitude = motion?.attitude else { return }
            let roll = attitude.roll
            let pitch = attitude.pitch
            MainActor.assumeIsolated {
                self?.update(roll: roll, pitch: pitch)
            }
        }
    }

    func stop() {
        guard manager.isDeviceMotionActive else { return }
        manager.stopDeviceMotionUpdates()
        baselinePitch = nil
        value = .zero
    }

    private func update(roll: Double, pitch: Double) {
        // Measure forward/back tilt relative to how the phone was held when the shelf appeared.
        let baseline = baselinePitch ?? pitch
        if baselinePitch == nil { baselinePitch = pitch }
        let target = CGSize(
            width: TiltMath.normalize(roll, range: 0.5),
            height: TiltMath.normalize(pitch - baseline, range: 0.4)
        )
        value = TiltMath.smooth(current: value, target: target, factor: 0.18)
    }
}

extension EnvironmentValues {
    /// Current shelf tilt (-1...1 per axis); zero when the effect is off.
    @Entry var shelfTilt: CGSize = .zero
}

/// Rotates the bookcase slightly in 3D as the phone tilts.
struct TiltingShelf<Content: View>: View {
    @ViewBuilder var content: Content

    @Environment(TiltMotion.self) private var tilt
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(TiltMotion.enabledKey) private var enabled = true

    var body: some View {
        let value = (enabled && !reduceMotion) ? tilt.value : .zero
        content
            .environment(\.shelfTilt, value)
            .rotation3DEffect(.degrees(value.width * 6), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .rotation3DEffect(.degrees(-value.height * 3), axis: (x: 1, y: 0, z: 0), perspective: 0.5)
    }
}

/// The wall drifts the opposite way, so it feels further back than the books.
struct TiltingWall: View {
    @Environment(TiltMotion.self) private var tilt
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(TiltMotion.enabledKey) private var enabled = true

    var body: some View {
        let value = (enabled && !reduceMotion) ? tilt.value : .zero
        WallBackground()
            .scaleEffect(1.08)
            .offset(x: -value.width * 12, y: -value.height * 8)
            .ignoresSafeArea()
    }
}
