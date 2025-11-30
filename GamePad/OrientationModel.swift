// OrientationModel.swift
import Foundation
import Combine
import simd

final class OrientationModel: ObservableObject {

    // Published orientation (already calibrated)
    @Published var orientation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))

    // Internal absolute orientation from the filter
    private var rawOrientation: simd_quatf = simd_quatf(angle: 0, axis: SIMD3<Float>(0, 1, 0))

    // Calibration reference; displayed orientation = reference.inverse * rawOrientation
    private var reference: simd_quatf?

    private var cancellables = Set<AnyCancellable>()

    // Update cadence (approx; JoyCon sends ~60 Hz)
    private let dt: Float = 1.0 / 60.0

    // Gyro scale to rad/s
    private let gyroScale: Float = (Float.pi / 180.0) * 0.08

    // Madgwick gain
    private let baseBeta: Float = 0.10 // slightly higher to tighten accel influence

    // Madgwick filter state
    private var madgwick = Madgwick()

    // Simple gyro bias estimator (learned when still)
    private var gyroBias = SIMD3<Float>(repeating: 0)
    private var biasAlpha: Float = 0.01 // increased learning rate when still

    // Stillness detection thresholds (more sensitive)
    private let gyroStillThreshold: Float = 0.01   // rad/s magnitude (more sensitive)
    private let accelStillThreshold: Float = 0.02  // |norm-1| tolerance (more sensitive)

    // Drift correction parameters
    private let yawDampingWhenStill: Float = 0.1 // stronger yaw damping
    private let enableYawDamping = true
    
    // Accelerometer-based drift correction
    private var gravityReference = SIMD3<Float>(0, 0, 1) // Expected gravity direction
    private let gravityCorrectionStrength: Float = 0.05 // How much to correct toward gravity
    private let enableGravityCorrection = true

    init() {
        NotificationCenter.default.publisher(for: GamepadIMUChangedNotification.Name)
            .compactMap { $0.object as? GamepadIMUChangedNotification }
            .sink { [weak self] imu in
                self?.handleIMU(imu)
            }
            .store(in: &cancellables)
    }

    func calibrate() {
        // Reset bias when calibrating
        gyroBias = SIMD3<Float>(repeating: 0)
        
        // Set reference orientation
        reference = rawOrientation
        
        // Update gravity reference based on current accelerometer reading
        // This helps with drift correction
        if let lastIMU = lastIMUData {
            let ax = Float(lastIMU.accelX)
            let ay = Float(lastIMU.accelY)
            let az = Float(lastIMU.accelZ)
            let aLen = sqrt(ax*ax + ay*ay + az*az)
            if aLen > 1e-6 {
                gravityReference = SIMD3<Float>(ax/aLen, ay/aLen, az/aLen)
            }
        }
        
        updatePublished()
    }
    
    // Store last IMU data for calibration
    private var lastIMUData: GamepadIMUChangedNotification?

    private func handleIMU(_ imu: GamepadIMUChangedNotification) {
        // Store for calibration
        lastIMUData = imu
        
        // Axis mapping (keep existing swaps)
        var gx = -Float(imu.gyroYaw)   * gyroScale  // rotation about X
        var gy =  Float(imu.gyroPitch) * gyroScale  // rotation about Y
        var gz =  Float(imu.gyroRoll)  * gyroScale  // rotation about Z

        // Accel (normalize to direction)
        var ax = Float(imu.accelX)
        var ay = Float(imu.accelY)
        var az = Float(imu.accelZ)
        let aLen = sqrt(ax*ax + ay*ay + az*az)
        var aUnit = SIMD3<Float>(0,0,0)
        if aLen > 1e-6 {
            ax /= aLen; ay /= aLen; az /= aLen
            aUnit = SIMD3<Float>(ax, ay, az)
        }

        // Stillness detection (more sensitive)
        let gVec = SIMD3<Float>(gx, gy, gz)
        let gMag = simd_length(gVec)
        let accelNormDelta = abs(simd_length(aUnit) - 1.0) // should be ~0 if unit
        let isStill = (gMag < gyroStillThreshold) && (accelNormDelta < accelStillThreshold)

        // Learn gyro bias when still (more aggressive)
        if isStill {
            gyroBias = mix(gyroBias, gVec, t: biasAlpha)
        }

        // Subtract bias
        let gDebiased = gVec - gyroBias
        gx = gDebiased.x; gy = gDebiased.y; gz = gDebiased.z

        // Enhanced drift correction when still
        var gxD = gx, gyD = gy, gzD = gz
        if isStill {
            // Stronger yaw damping
            if enableYawDamping {
                gzD = gz * (1.0 - yawDampingWhenStill)
            }
            
            // Accelerometer-based drift correction
            if enableGravityCorrection {
                // Calculate correction to align with gravity reference
                let currentGravity = aUnit
                let correction = cross(currentGravity, gravityReference) * gravityCorrectionStrength
                
                // Apply correction to gyro rates
                gxD += correction.x
                gyD += correction.y
                gzD += correction.z
            }
        }

        // Update Madgwick
        madgwick.beta = baseBeta
        madgwick.update(gx: gxD, gy: gyD, gz: gzD, ax: ax, ay: ay, az: az, dt: dt)

        // Convert to simd_quatf
        rawOrientation = simd_normalize(madgwick.quaternionSIMD())

        updatePublished()
    }

    private func updatePublished() {
        let q = rawOrientation
        if let ref = reference {
            orientation = simd_normalize(ref.inverse * q)
        } else {
            orientation = q
        }
    }
}

// MARK: - Madgwick AHRS (gyro + accel)
private struct Madgwick {

    // Quaternion state (w, x, y, z)
    private(set) var q0: Float = 1
    private(set) var q1: Float = 0
    private(set) var q2: Float = 0
    private(set) var q3: Float = 0

    // Algorithm gain
    var beta: Float = 0.1

    mutating func update(gx: Float, gy: Float, gz: Float,
                         ax: Float, ay: Float, az: Float,
                         dt: Float) {

        var q0 = self.q0
        var q1 = self.q1
        var q2 = self.q2
        var q3 = self.q3

        // If accel is zero vector, fall back to pure gyro integration
        let accelValid = (ax*ax + ay*ay + az*az) > 1e-12

        // Rate of change from gyro (quaternion derivative)
        let qDot0 = 0.5 * (-q1 * gx - q2 * gy - q3 * gz)
        let qDot1 = 0.5 * ( q0 * gx + q2 * gz - q3 * gy)
        let qDot2 = 0.5 * ( q0 * gy - q1 * gz + q3 * gx)
        let qDot3 = 0.5 * ( q0 * gz + q1 * gy - q2 * gx)

        var s0: Float = 0, s1: Float = 0, s2: Float = 0, s3: Float = 0

        if accelValid {
            let _2q0 = 2.0 * q0
            let _2q1 = 2.0 * q1
            let _2q2 = 2.0 * q2
            let _2q3 = 2.0 * q3
            let _4q1 = 4.0 * q1
            let _4q2 = 4.0 * q2

            // Gradient descent step (no magnetometer)
            let f1 = _2q1 * q3 - _2q0 * q2 - ax
            let f2 = _2q0 * q1 + _2q2 * q3 - ay
            let f3 = 1.0 - _2q1 * q1 - _2q2 * q2 - az

            s0 = -_2q2 * f1 + _2q1 * f2
            s1 =  _2q3 * f1 + _2q0 * f2 - _4q1 * f3
            s2 = -_2q0 * f1 + _2q3 * f2 - _4q2 * f3
            s3 =  _2q1 * f1 + _2q2 * f2

            // Normalize step magnitude
            let normS = sqrt(s0*s0 + s1*s1 + s2*s2 + s3*s3)
            if normS > 1e-12 {
                s0 /= normS; s1 /= normS; s2 /= normS; s3 /= normS
            } else {
                s0 = 0; s1 = 0; s2 = 0; s3 = 0
            }
        }

        // Apply feedback step
        let q0New = q0 + (qDot0 - beta * s0) * dt
        let q1New = q1 + (qDot1 - beta * s1) * dt
        let q2New = q2 + (qDot2 - beta * s2) * dt
        let q3New = q3 + (qDot3 - beta * s3) * dt

        // Normalize quaternion
        let normQ = sqrt(q0New*q0New + q1New*q1New + q2New*q2New + q3New*q3New)
        self.q0 = q0New / normQ
        self.q1 = q1New / normQ
        self.q2 = q2New / normQ
        self.q3 = q3New / normQ
    }

    func quaternionSIMD() -> simd_quatf {
        simd_quatf(ix: q1, iy: q2, iz: q3, r: q0)
    }
}

// MARK: - Helper Functions
private func mix(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
    return a + t * (b - a)
}

private func cross(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> SIMD3<Float> {
    return SIMD3<Float>(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
}
