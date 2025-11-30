import Foundation
import Combine

final class ButtonStateModel: ObservableObject {

    // Face buttons
    @Published var a = false
    @Published var b = false
    @Published var x = false
    @Published var y = false

    // D-pad
    @Published var dpadUp = false
    @Published var dpadRight = false
    @Published var dpadDown = false
    @Published var dpadLeft = false

    // Sticks pressed
    @Published var leftStick = false
    @Published var rightStick = false

    // Shoulders/triggers
    @Published var l1 = false
    @Published var r1 = false
    @Published var l2 = false // treated as pressed/not pressed via leftTriggerButton
    @Published var r2 = false

    // Aux buttons
    @Published var plus = false
    @Published var minus = false
    @Published var home = false
    @Published var capture = false

    private var cancellable: AnyCancellable?

    init() {
        cancellable = NotificationCenter.default.publisher(for: GamepadButtonChangedNotification.Name)
            .compactMap { $0.object as? GamepadButtonChangedNotification }
            .sink { [weak self] n in
                guard let self else { return }
                // Face buttons mapping from JoyConUIModel semantics:
                self.x = n.faceNorthButton
                self.a = n.faceEastButton
                self.b = n.faceSouthButton
                self.y = n.faceWestButton

                // D-pad
                self.dpadUp = n.upButton
                self.dpadRight = n.rightButton
                self.dpadDown = n.downButton
                self.dpadLeft = n.leftButton

                // Sticks (press)
                self.leftStick = n.leftStickButton
                self.rightStick = n.rightStickButton

                // Shoulders/triggers (Joy-Con are digital; use the button flags)
                self.l1 = n.leftShoulderButton
                self.r1 = n.rightShoulderButton
                self.l2 = n.leftTriggerButton
                self.r2 = n.rightTriggerButton

                // Aux
                self.plus = n.plusButton
                self.minus = n.minusButton
                self.home = n.rightAuxiliaryButton
                self.capture = n.socialButton
            }
    }
}
