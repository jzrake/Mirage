import Foundation
import GLKit




// ============================================================================
class Camera
{
    var viewport = NSSize()
    var anchor = float3()
    var anchoredRotation: simd_quatf = simd_quaternion(0.0, 0.0, 0.0, 1.0)
    var currentRotation: simd_quatf = simd_quaternion(0.0, 0.0, 0.0, 1.0)

    func dragAroundAnchor(with point: NSPoint)
    {
        let current = projectToUnitSphere(point)
        let axis = cross(anchor, current)
        let angle = acosf(dot(anchor, current))
        let Q = simd_quaternion(angle * 2, axis).normalized
        currentRotation = Q * anchoredRotation
    }

    func setAnchor(with point: NSPoint)
    {
        anchor = projectToUnitSphere(point)
    }

    func projectToUnitSphere(_ point: NSPoint) -> float3
    {
        var p = float3()
        let R = Float(0.25 * min(viewport.width, viewport.height)) // radius of the trackball
        let X = Float(point.x - viewport.width / 2)
        let Y = Float(point.y - viewport.height / 2)
        let r = sqrt(X * X + Y * Y)
        let x = r < R ? X : X * R / r
        let y = r < R ? Y : Y * R / r

        p.x = x
        p.y = y
        p.z = R - sqrt(x * x + y * y)

        return p / length(p)
    }
}
