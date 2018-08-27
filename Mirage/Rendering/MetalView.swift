import Cocoa
import Metal
import GLKit




// ============================================================================
class MetalView: NSView
{
    var device: MTLDevice!
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var metalLayer: CAMetalLayer!
    var rotation: Float = 0.0
    var zcamera: Float = 10.0

    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        self.initGraphics()
    }

    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
        self.initGraphics()
    }

    override func resize(withOldSuperviewSize oldSize: NSSize)
    {
        self.metalLayer.drawableSize.width  = self.frame.size.width * 2
        self.metalLayer.drawableSize.height = self.frame.size.height * 2
        self.render()
    }

    override func scrollWheel(with event: NSEvent)
    {
        zcamera *= 1 + Float(event.deltaY) * 0.01
        zcamera = clamp(x:zcamera, low:1, high:100)
        self.render()
    }

    override func mouseDragged(with event: NSEvent)
    {
        rotation += Float(event.deltaX) * 0.01
        self.render()
    }

    private func initGraphics()
    {
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device.makeCommandQueue()
        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = self.device
        self.layer = metalLayer

        do {
            try self.pipelineState = device.makeRenderPipelineState(descriptor: self.pipelineDescriptor())
        } catch {
            print("MetalView: pipeline state creation failed")
        }
    }

    private func pipelineDescriptor() -> MTLRenderPipelineDescriptor
    {
        let defaultLibrary   = device.makeDefaultLibrary()
        let vertexFunction   = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        
        let d = MTLRenderPipelineDescriptor()

        d.vertexFunction   = vertexFunction;
        d.fragmentFunction = fragmentFunction;
        d.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm;

        return d
    }

    private func renderPassDescriptor(preparedFor drawable: CAMetalDrawable) -> MTLRenderPassDescriptor
    {
        let d                             = MTLRenderPassDescriptor()
        d.colorAttachments[0].texture     = drawable.texture;
        d.colorAttachments[0].loadAction  = MTLLoadAction.clear;
        d.colorAttachments[0].storeAction = MTLStoreAction.store;
        d.colorAttachments[0].clearColor  = MTLClearColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        return d;
    }

    private func render()
    {
        if (device == nil)
        {
            print("device not ready yet")
            return
        }

        let W = Float(self.frame.size.width)
        let H = Float(self.frame.size.height)

        let vertexData:[Float] = [
            +0.0, +1.0, 0.0,
            -1.0, -1.0, 0.0,
            +1.0, -1.0, 0.0]

        let layer = self.layer as! CAMetalLayer
        let drawable = layer.nextDrawable()

        var model = GLKMatrix4Rotate(GLKMatrix4Identity, rotation, 0, 1, 0)
        var view  = GLKMatrix4MakeTranslation(0, 0, -zcamera)
        var proj  = GLKMatrix4MakePerspective(1.0, W/H, 0.01, 1e3)

        let renderPassDescriptor = self.renderPassDescriptor(preparedFor: drawable!)
        let commandBuffer = self.commandQueue?.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        renderEncoder!.setRenderPipelineState(self.pipelineState!)
        renderEncoder!.setVertexBytes(vertexData, length: MemoryLayout<Float>.size * 9 , index: Int(VertexInputVertices.rawValue))
        renderEncoder!.setVertexBytes(&model,     length: MemoryLayout<GLKMatrix4>.size, index: Int(VertexInputModelMatrix.rawValue))
        renderEncoder!.setVertexBytes(&view,      length: MemoryLayout<GLKMatrix4>.size, index: Int(VertexInputViewMatrix.rawValue))
        renderEncoder!.setVertexBytes(&proj,      length: MemoryLayout<GLKMatrix4>.size, index: Int(VertexInputProjMatrix.rawValue))
        renderEncoder!.drawPrimitives(type: MTLPrimitiveType.triangle, vertexStart: 0, vertexCount: 3)

        renderEncoder!.endEncoding()
        commandBuffer!.present(drawable!)
        commandBuffer!.commit()
    }

    private func clamp(x:Float, low:Float, high:Float) -> Float
    {
        return x > high ? high : (x < low) ? low : x
    }
}
