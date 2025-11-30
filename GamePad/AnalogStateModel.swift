import Foundation
import Combine

final class AnalogStateModel: ObservableObject {
    @Published var leftX: Float = 0     // normalized [-1, 1]
    @Published var leftY: Float = 0
    @Published var rightX: Float = 0
    @Published var rightY: Float = 0

    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default.publisher(for: GamepadAnalogChangedNotification.Name)
            .compactMap { $0.object as? GamepadAnalogChangedNotification }
            .sink { [weak self] n in
                guard let self else { return }
                let maxV = max(1, Int(n.stickMax))
                // Normalize to [-1, 1] using center at half max
                func norm(_ v: UInt16) -> Float {
                    let f = Float(v)
                    let center = Float(n.stickMax) / 2.0
                    let span = max(1.0, center)
                    return (f - center) / span
                }
                self.leftX = norm(n.leftStickX)
                self.leftY = norm(n.leftStickY)
                self.rightX = norm(n.rightStickX)
                self.rightY = norm(n.rightStickY)
            }
    }
}
