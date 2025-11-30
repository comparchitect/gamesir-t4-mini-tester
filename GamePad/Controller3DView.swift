// Controller3DView.swift
import SwiftUI
import SceneKit
import simd
import Combine

struct Controller3DView: NSViewRepresentable {

    @ObservedObject var model: OrientationModel
    @StateObject private var buttons = ButtonStateModel()
    @StateObject private var analog  = AnalogStateModel()

    func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.allowsCameraControl = true
        scnView.backgroundColor = .black

        // Scene
        let scene = SCNScene()
        scnView.scene = scene

        // Camera: closer and slightly wider FOV to make the controller larger
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0.6, 7.2)
        cameraNode.camera?.fieldOfView = 62
        cameraNode.camera?.zNear = 0.1
        cameraNode.camera?.zFar = 100
        scene.rootNode.addChildNode(cameraNode)

        // Lights
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .omni
        key.light?.intensity = 1200
        key.position = SCNVector3(6, 8, 12)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .omni
        fill.light?.intensity = 700
        fill.position = SCNVector3(-8, 4, 6)
        scene.rootNode.addChildNode(fill)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = NSColor(white: 0.22, alpha: 1.0)
        scene.rootNode.addChildNode(ambient)

        // Controller root node
        let controllerNode = SCNNode()
        controllerNode.name = "controllerNode"

        // Body: darker translucent shell + inner plate + subtle grip bulges
        let shell = SCNBox(width: 5.0, height: 2.6, length: 0.55, chamferRadius: 0.60)
        let shellMat = SCNMaterial()
        shellMat.diffuse.contents = NSColor(calibratedWhite: 0.14, alpha: 0.75)
        shellMat.specular.contents = NSColor(white: 0.9, alpha: 1.0)
        shellMat.transparency = 0.90
        shellMat.isDoubleSided = false
        shell.materials = [shellMat]
        let shellNode = SCNNode(geometry: shell)

        let inner = SCNBox(width: 4.8, height: 2.4, length: 0.28, chamferRadius: 0.50)
        let innerMat = SCNMaterial()
        innerMat.diffuse.contents = NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.18, alpha: 1.0)
        innerMat.specular.contents = NSColor(white: 0.7, alpha: 1.0)
        inner.materials = [innerMat]
        let innerNode = SCNNode(geometry: inner)
        innerNode.position.z = 0.06

        // Grip bulges (hemisphere hints)
        func makeGripBulge(sign: CGFloat) -> SCNNode {
            let sphere = SCNSphere(radius: 0.95)
            let m = SCNMaterial()
            m.diffuse.contents = NSColor(calibratedWhite: 0.14, alpha: 0.75)
            m.specular.contents = NSColor(white: 0.9, alpha: 1.0)
            sphere.materials = [m]
            let n = SCNNode(geometry: sphere)
            n.scale = SCNVector3(0.7, 0.9, 0.35)
            n.position = SCNVector3(2.0 * Float(sign), -0.7, -0.06)
            return n
        }
        let leftGrip = makeGripBulge(sign: -1)
        let rightGrip = makeGripBulge(sign: 1)

        controllerNode.addChildNode(shellNode)
        controllerNode.addChildNode(innerNode)
        controllerNode.addChildNode(leftGrip)
        controllerNode.addChildNode(rightGrip)

        // Helpers
        func makeRoundButton(radius: CGFloat, height: CGFloat, color: NSColor) -> SCNNode {
            let cyl = SCNCylinder(radius: radius, height: height)
            let m = SCNMaterial()
            m.diffuse.contents = color
            m.specular.contents = NSColor.white
            cyl.materials = [m]
            let n = SCNNode(geometry: cyl)
            n.eulerAngles.x = .pi / 2 // face front
            return n
        }

        func makeShoulder(width: CGFloat, depth: CGFloat, color: NSColor) -> SCNNode {
            let g = SCNBox(width: width, height: 0.18, length: depth, chamferRadius: 0.09)
            let m = SCNMaterial()
            m.diffuse.contents = color
            m.specular.contents = NSColor.white
            g.materials = [m]
            let n = SCNNode(geometry: g)
            n.position.z = 0.12
            return n
        }

        // D-Pad (single-piece look but built from 4 arms + round hub so we can light each arm)
        func makeDPadArm(size: CGFloat, thickness: CGFloat, color: NSColor, orientation: String) -> SCNNode {
            let g: SCNBox
            if orientation == "h" {
                g = SCNBox(width: size, height: thickness, length: 0.09, chamferRadius: thickness * 0.35)
            } else {
                g = SCNBox(width: thickness, height: size, length: 0.09, chamferRadius: thickness * 0.35)
            }
            let m = SCNMaterial()
            m.diffuse.contents = color
            m.specular.contents = NSColor(white: 0.7, alpha: 1.0)
            g.materials = [m]
            let n = SCNNode(geometry: g)
            n.position.z = 0.30
            return n
        }
        func makeDPadHub(thickness: CGFloat, color: NSColor) -> SCNNode {
            let hub = SCNCylinder(radius: thickness * 0.42, height: 0.10)
            let hubMat = SCNMaterial()
            hubMat.diffuse.contents = color.blended(withFraction: 0.15, of: .black)
            hubMat.specular.contents = NSColor(white: 0.7, alpha: 1.0)
            hub.materials = [hubMat]
            let hubNode = SCNNode(geometry: hub)
            hubNode.eulerAngles.x = .pi / 2
            hubNode.position.z = 0.31
            return hubNode
        }

        // Sticks: protruding caps + torus rim to hint concave top
        let stickRadius: CGFloat = 0.34
        let stickHeight: CGFloat = 0.16
        let stickBaseZ: CGFloat = 0.40
        let stickColor = NSColor(calibratedWhite: 0.25, alpha: 1.0)

        func makeStick() -> (pivot: SCNNode, cap: SCNNode, rim: SCNNode) {
            let pivot = SCNNode()

            // Cap
            let cap = makeRoundButton(radius: stickRadius, height: stickHeight, color: stickColor)
            cap.position.z = stickBaseZ

            // Rim (thin torus)
            let torus = SCNTorus(ringRadius: stickRadius * 0.82, pipeRadius: 0.02)
            let rimMat = SCNMaterial()
            rimMat.diffuse.contents = NSColor(calibratedWhite: 0.08, alpha: 1.0)
            rimMat.specular.contents = NSColor(white: 0.2, alpha: 1.0)
            torus.materials = [rimMat]
            let rim = SCNNode(geometry: torus)
            rim.eulerAngles.x = .pi / 2
            rim.position.z = stickBaseZ + 0.01

            pivot.addChildNode(cap)
            pivot.addChildNode(rim)
            return (pivot, cap, rim)
        }

        let (leftStickPivot, leftStickCap, _) = makeStick()
        let (rightStickPivot, rightStickCap, _) = makeStick()

        // D-Pad arms + hub (smaller to fit within controller bounds, even smaller per request)
        let dpadColor = NSColor(calibratedWhite: 0.22, alpha: 1.0)
        let dpadSize: CGFloat = 0.62   // was 0.78
        let dpadThk: CGFloat = 0.20    // was 0.24

        let dpadCenter = SCNNode()
        // D-pad stays swapped into the lower-left zone, but nudged inward slightly
        dpadCenter.position = SCNVector3(-1.25, -0.10, 0.0)

        let dpadUp = makeDPadArm(size: dpadSize, thickness: dpadThk, color: dpadColor, orientation: "v")
        let dpadDown = makeDPadArm(size: dpadSize, thickness: dpadThk, color: dpadColor, orientation: "v")
        let dpadLeft = makeDPadArm(size: dpadSize, thickness: dpadThk, color: dpadColor, orientation: "h")
        let dpadRight = makeDPadArm(size: dpadSize, thickness: dpadThk, color: dpadColor, orientation: "h")

        dpadUp.position.y =  dpadSize * 0.5
        dpadDown.position.y = -dpadSize * 0.5
        dpadLeft.position.x = -dpadSize * 0.5
        dpadRight.position.x = dpadSize * 0.5

        let dpadHub = makeDPadHub(thickness: dpadThk, color: dpadColor)

        dpadCenter.addChildNode(dpadUp)
        dpadCenter.addChildNode(dpadDown)
        dpadCenter.addChildNode(dpadLeft)
        dpadCenter.addChildNode(dpadRight)
        dpadCenter.addChildNode(dpadHub)

        // Left stick stays swapped into the upper-left zone
        leftStickPivot.position = SCNVector3(-1.90, 0.35, 0.0)

        // Right stick unchanged
        rightStickPivot.position = SCNVector3(1.15, -0.25, 0.0)

        // Face buttons (diamond arrangement with requested colors/mapping)
        func makeFace(radius: CGFloat, color: NSColor) -> SCNNode {
            makeRoundButton(radius: radius, height: 0.09, color: color)
        }
        // Darker base colors to improve emissive contrast on press
        let darkBlue   = NSColor.systemBlue.blended(withFraction: 0.55, of: .black) ?? .systemBlue
        let darkYellow = NSColor.systemYellow.blended(withFraction: 0.55, of: .black) ?? .systemYellow
        let darkRed    = NSColor.systemRed.blended(withFraction: 0.55, of: .black) ?? .systemRed
        let darkGreen  = NSColor.systemGreen.blended(withFraction: 0.55, of: .black) ?? .systemGreen

        // Colors: Blue (left) = Y, Yellow (top) = X, Red (right) = A, Green (bottom) = B
        let faceBlueLeft  = makeRoundButton(radius: 0.26, height: 0.09, color: darkBlue)
        let faceYellowTop = makeRoundButton(radius: 0.26, height: 0.09, color: darkYellow)
        let faceRedRight  = makeRoundButton(radius: 0.26, height: 0.09, color: darkRed)
        let faceGreenBot  = makeRoundButton(radius: 0.26, height: 0.09, color: darkGreen)

        let faceCenter = SCNVector3(1.85, 0.40, 0.30)
        let faceSpacing: CGFloat = 0.40
        faceBlueLeft.position  = SCNVector3(faceCenter.x - faceSpacing, faceCenter.y, faceCenter.z)
        faceRedRight.position  = SCNVector3(faceCenter.x + faceSpacing, faceCenter.y, faceCenter.z)
        faceYellowTop.position = SCNVector3(faceCenter.x, faceCenter.y + faceSpacing, faceCenter.z)
        faceGreenBot.position  = SCNVector3(faceCenter.x, faceCenter.y - faceSpacing, faceCenter.z)

        // Shoulders / triggers
        let l1 = makeShoulder(width: 1.30, depth: 0.28, color: NSColor(calibratedWhite: 0.18, alpha: 1.0))
        l1.position = SCNVector3(-1.55, 1.20, 0.10)
        let r1 = makeShoulder(width: 1.30, depth: 0.28, color: NSColor(calibratedWhite: 0.18, alpha: 1.0))
        r1.position = SCNVector3(1.55, 1.20, 0.10)

        let l2 = makeShoulder(width: 1.10, depth: 0.40, color: NSColor(calibratedWhite: 0.16, alpha: 1.0))
        l2.position = SCNVector3(-1.55, 1.48, 0.02)
        let r2 = makeShoulder(width: 1.10, depth: 0.40, color: NSColor(calibratedWhite: 0.16, alpha: 1.0))
        r2.position = SCNVector3(1.55, 1.48, 0.02)

        // Plus / Minus / Home / Capture — move closer together toward center
        let smallBtnRadius: CGFloat = 0.16
        let smallBtnHeight: CGFloat = 0.08
        let auxColor = NSColor(calibratedWhite: 0.22, alpha: 1.0) // slightly darker than before

        let plus = makeRoundButton(radius: smallBtnRadius, height: smallBtnHeight, color: auxColor)
        let minus = makeRoundButton(radius: smallBtnRadius, height: smallBtnHeight, color: auxColor)
        let home = makeRoundButton(radius: smallBtnRadius, height: smallBtnHeight, color: auxColor)
        let capture = makeRoundButton(radius: smallBtnRadius, height: smallBtnHeight, color: auxColor)

        // Tighter cluster in the center area
        minus.position = SCNVector3(-0.18, 0.72, 0.30)
        plus.position  = SCNVector3( 0.18, 0.72, 0.30)
        capture.position = SCNVector3(-0.32, -0.06, 0.30)
        home.position    = SCNVector3( 0.32, -0.06, 0.30)

        // Assemble
        controllerNode.addChildNode(leftStickPivot)
        controllerNode.addChildNode(rightStickPivot)
        controllerNode.addChildNode(dpadCenter)
        controllerNode.addChildNode(faceBlueLeft)
        controllerNode.addChildNode(faceRedRight)
        controllerNode.addChildNode(faceYellowTop)
        controllerNode.addChildNode(faceGreenBot)
        controllerNode.addChildNode(l1)
        controllerNode.addChildNode(r1)
        controllerNode.addChildNode(l2)
        controllerNode.addChildNode(r2)
        controllerNode.addChildNode(plus)
        controllerNode.addChildNode(minus)
        controllerNode.addChildNode(home)
        controllerNode.addChildNode(capture)

        scene.rootNode.addChildNode(controllerNode)

        // Initial orientation
        controllerNode.simdOrientation = model.orientation

        // Store node references in coordinator
        context.coordinator.controllerNode = controllerNode
        context.coordinator.nodes = Nodes(
            leftStickPivot: leftStickPivot, leftStickCap: leftStickCap,
            rightStickPivot: rightStickPivot, rightStickCap: rightStickCap,
            dpadUp: dpadUp, dpadDown: dpadDown, dpadLeft: dpadLeft, dpadRight: dpadRight,
            a: faceRedRight,   // A = Red (right)
            b: faceGreenBot,   // B = Green (bottom)
            x: faceYellowTop,  // X = Yellow (top)
            y: faceBlueLeft,   // Y = Blue (left)
            l1: l1, r1: r1, l2: l2, r2: r2,
            plus: plus, minus: minus, home: home, capture: capture
        )

        // Observe orientation updates
        context.coordinator.orientationCancellable = model.$orientation.sink { [weak controllerNode] q in
            controllerNode?.simdOrientation = q
        }

        // Observe button updates
        context.coordinator.buttonsCancellable = buttons.objectWillChange.sink { [weak coordinator = context.coordinator] _ in
            guard let nodes = coordinator?.nodes else { return }
            updateButtonHighlights(nodes: nodes)
            updateDpadMotion(nodes: nodes)
            updateStickPress(nodes: nodes)
        }

        // Observe analog updates for stick tilt
        context.coordinator.analogCancellable = analog.objectWillChange.sink { [weak coordinator = context.coordinator] _ in
            guard let nodes = coordinator?.nodes else { return }
            updateStickTilt(nodes: nodes)
        }

        // Initial updates
        if let nodes = context.coordinator.nodes {
            updateButtonHighlights(nodes: nodes)
            updateDpadMotion(nodes: nodes)
            updateStickPress(nodes: nodes)
            updateStickTilt(nodes: nodes)
        }

        return scnView
    }

    func updateNSView(_ nsView: SCNView, context: Context) {
        // No-op; updates are driven by Combine
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Visual updates

    private func setEmissive(_ node: SCNNode, pressed: Bool, color: NSColor = .systemGreen) {
        guard let m = node.geometry?.firstMaterial else { return }
        if pressed {
            m.emission.contents = color
            m.emission.intensity = 1.0
        } else {
            m.emission.contents = NSColor.black
            m.emission.intensity = 0.0
        }
    }

    private func updateButtonHighlights(nodes: Nodes) {
        // Face buttons mapping per request:
        // Blue (left) = Y, Yellow (top) = X, Red (right) = A, Green (bottom) = B
        setEmissive(nodes.y, pressed: buttons.y, color: .systemBlue)     // Y -> Blue (left)
        setEmissive(nodes.x, pressed: buttons.x, color: .systemYellow)   // X -> Yellow (top)
        setEmissive(nodes.a, pressed: buttons.a, color: .systemRed)      // A -> Red (right)
        setEmissive(nodes.b, pressed: buttons.b, color: .systemGreen)    // B -> Green (bottom)

        setEmissive(nodes.l1, pressed: buttons.l1, color: .systemPurple)
        setEmissive(nodes.r1, pressed: buttons.r1, color: .systemPurple)
        setEmissive(nodes.l2, pressed: buttons.l2, color: .systemPurple)
        setEmissive(nodes.r2, pressed: buttons.r2, color: .systemPurple)

        setEmissive(nodes.plus, pressed: buttons.plus, color: .systemOrange)
        setEmissive(nodes.minus, pressed: buttons.minus, color: .systemOrange)
        setEmissive(nodes.home, pressed: buttons.home, color: .white)
        setEmissive(nodes.capture, pressed: buttons.capture, color: .white)
    }

    private func updateDpadMotion(nodes: Nodes) {
        // Apply press animation depth to the actual D-pad arm nodes
        let dz: Float = 0.05
        nodes.dpadUp.position.z = CGFloat(buttons.dpadUp ? 0.30 + dz : 0.30)
        nodes.dpadDown.position.z = CGFloat(buttons.dpadDown ? 0.30 + dz : 0.30)
        nodes.dpadLeft.position.z = CGFloat(buttons.dpadLeft ? 0.30 + dz : 0.30)
        nodes.dpadRight.position.z = CGFloat(buttons.dpadRight ? 0.30 + dz : 0.30)

        setEmissive(nodes.dpadUp, pressed: buttons.dpadUp, color: .systemGray)
        setEmissive(nodes.dpadDown, pressed: buttons.dpadDown, color: .systemGray)
        setEmissive(nodes.dpadLeft, pressed: buttons.dpadLeft, color: .systemGray)
        setEmissive(nodes.dpadRight, pressed: buttons.dpadRight, color: .systemGray)
    }

    private func updateStickTilt(nodes: Nodes) {
        let tilt: Float = 0.25
        // Invert behavior so pushing up visually tilts up
        nodes.leftStickPivot.eulerAngles.x = CGFloat( analog.leftY * tilt)
        nodes.leftStickPivot.eulerAngles.y = CGFloat( analog.leftX * tilt)
        nodes.rightStickPivot.eulerAngles.x = CGFloat( analog.rightY * tilt)
        nodes.rightStickPivot.eulerAngles.y = CGFloat( analog.rightX * tilt)
    }

    private func updateStickPress(nodes: Nodes) {
        let pressDz: CGFloat = 0.06
        let baseZ: CGFloat = 0.40
        nodes.leftStickCap.position.z = buttons.leftStick ? baseZ - pressDz : baseZ
        nodes.rightStickCap.position.z = buttons.rightStick ? baseZ - pressDz : baseZ
    }

    final class Coordinator {
        var controllerNode: SCNNode?
        var nodes: Nodes?
        var orientationCancellable: Any?
        var buttonsCancellable: Any?
        var analogCancellable: Any?
        deinit {
            (orientationCancellable as? AnyCancellable)?.cancel()
            (buttonsCancellable as? AnyCancellable)?.cancel()
            (analogCancellable as? AnyCancellable)?.cancel()
        }
    }

    struct Nodes {
        let leftStickPivot: SCNNode
        let leftStickCap: SCNNode
        let rightStickPivot: SCNNode
        let rightStickCap: SCNNode
        let dpadUp: SCNNode
        let dpadDown: SCNNode
        let dpadLeft: SCNNode
        let dpadRight: SCNNode
        let a: SCNNode
        let b: SCNNode
        let x: SCNNode
        let y: SCNNode
        let l1: SCNNode
        let r1: SCNNode
        let l2: SCNNode
        let r2: SCNNode
        let plus: SCNNode
        let minus: SCNNode
        let home: SCNNode
        let capture: SCNNode
    }
}
