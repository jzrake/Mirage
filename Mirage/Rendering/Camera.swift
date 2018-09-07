import Foundation
import GLKit




// ============================================================================
class EasingFunction
{
    var timer: Timer?
    let duration: Double = 0.33
    let frames: Int = 30
    var current: Int = 0
    var notification: ((Double) -> Void)?

    var parameter: Double {
        get {
            let x = Double(self.current) / Double(self.frames - 1)
            return 2 * pow(x, 2) / (1 + pow(x, 4))
        }
    }

    func ease(callback: @escaping (Double) -> Void)
    {
        notification = callback
        startTimer()
    }

    private func startTimer()
    {
        timer?.invalidate()
        current = 0

        timer = Timer.scheduledTimer(withTimeInterval: duration / Double(frames), repeats: true)
        {
            [weak self] _ in
            guard let s = self else { return }

            s.notification?(s.parameter)
            s.current += 1

            if (s.current == s.frames)
            {
                s.timer?.invalidate()
            }
        }
    }

    deinit
    {
        self.timer?.invalidate()
    }
}




// ============================================================================
class Camera
{
    var anchor = float3()
    var viewport = NSSize()
    var anchoredRotation: simd_quatf = simd_quaternion(0, 0, 0, 1)
    var currentRotation: simd_quatf = simd_quaternion(0, 0, 0, 1)
    var easing = EasingFunction()
    var changeCallback: (() -> Void)?

    var rotation: simd_float4x4
    {
        get { return simd_float4x4(currentRotation) }
    }

    func animateToNoRotation()
    {
        anchoredRotation = currentRotation
        easing.ease(callback: {
            [weak self] t in
            guard let s = self else { return }
            s.currentRotation = s.anchoredRotation.slerp(to: simd_quaternion(0, 0, 0, 1), frac: Float(t))
            s.changeCallback?()
        })
    }

    func setAnchor(with point: NSPoint)
    {
        anchor = projectToUnitSphere(point)
        anchoredRotation = currentRotation
    }

    func dragAroundAnchor(with point: NSPoint)
    {
        let current = projectToUnitSphere(point)
        let axis = cross(anchor, current)
        let angle = acosf(dot(anchor, current))
        let Q = simd_quaternion(angle * 2, axis).normalized
        currentRotation = Q * anchoredRotation
        self.changeCallback?()
    }

    func projectToUnitSphere(_ point: NSPoint) -> simd_float3
    {
        let r = Float(0.5 * min(viewport.width, viewport.height)) // trackball radius
        let x = Float(point.x - viewport.width / 2)
        let y = Float(point.y - viewport.height / 2)
        let p = simd_float3(x, y, r - sqrt(x * x + y * y))
        return p / length(p)
    }
}




// ============================================================================
extension simd_quatf
{
    func slerp(to end: simd_quatf, frac: Float) -> simd_quatf
    {
        let A = unsafeBitCast(self, to: GLKQuaternion.self)
        let B = unsafeBitCast(end, to: GLKQuaternion.self)
        return unsafeBitCast(GLKQuaternionSlerp(A, B, frac), to: simd_quatf.self)
    }
}




// ============================================================================
extension float4x4
{
    static func makeScale(_ x: Float, _ y: Float, _ z: Float) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakeScale(x, y, z), to: float4x4.self)
    }

    static func makeRotate(radians: Float, _ x: Float, _ y: Float, _ z: Float) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakeRotation(radians, x, y, z), to: float4x4.self)
    }

    static func makeTranslation(_ x: Float, _ y: Float, _ z: Float) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakeTranslation(x, y, z), to: float4x4.self)
    }

    static func makePerspective(fovyRadians: Float, _ aspect: Float, _ nearZ: Float, _ farZ: Float) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakePerspective(fovyRadians, aspect, nearZ, farZ), to: float4x4.self)
    }

    static func makeFrustum(_ left: Float,
                            _ right: Float,
                            _ bottom: Float,
                            _ top: Float,
                            _ nearZ: Float,
                            _ farZ: Float) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakeFrustum(left, right, bottom, top, nearZ, farZ), to: float4x4.self)
    }

    static func makeOrtho(_ left: Float,
                          _ right: Float,
                          _ bottom: Float,
                          _ top: Float,
                          _ nearZ: Float,
                          _ farZ: Float) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakeOrtho(left, right, bottom, top, nearZ, farZ), to: float4x4.self)
    }

    static func makeLookAt(_ eyeX: Float,
                           _ eyeY: Float,
                           _ eyeZ: Float,
                           _ centerX: Float,
                           _ centerY: Float,
                           _ centerZ: Float,
                           _ upX: Float,
                           _ upY: Float,
                           _ upZ: Float) -> float4x4
    {
        return unsafeBitCast(GLKMatrix4MakeLookAt(eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ), to: float4x4.self)
    }

    func scale(x: Float, y: Float, z: Float) -> float4x4
    {
        return self * float4x4.makeScale(x, y, z)
    }

    func rotate(radians: Float, _ x: Float, _ y: Float, _ z: Float) -> float4x4
    {
        return self * float4x4.makeRotate(radians: radians, x, y, z)
    }

    func translate(x: Float, _ y: Float, _ z: Float) -> float4x4
    {
        return self * float4x4.makeTranslation(x, y, z)
    }
}
