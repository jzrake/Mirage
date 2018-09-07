import Foundation
import GLKit




// ============================================================================
class Camera
{
    var anchor = float3()
    var viewport = NSSize()
    var anchoredRotation: simd_quatf = simd_quaternion(0.0, 0.0, 0.0, 1.0)
    var currentRotation: simd_quatf = simd_quaternion(0.0, 0.0, 0.0, 1.0)

    var rotation: simd_float4x4
    {
        get { return simd_float4x4(currentRotation) }
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
