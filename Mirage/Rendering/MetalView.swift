import Cocoa
import Metal
import GLKit




// ============================================================================
class MetalView: NSView
{
    var device:            MTLDevice!
    var pipelineState:     MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    var commandQueue:      MTLCommandQueue!
    var metalLayer:        CAMetalLayer!
    var xrotation:         Float = 0.0
    var yrotation:         Float = 0.0
    var zcamera:           Float = 10.0

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

    private func initGraphics()
    {
        self.device = MTLCreateSystemDefaultDevice()
        self.commandQueue = device.makeCommandQueue()
        self.depthStencilState = device.makeDepthStencilState(descriptor: self.depthStencilDescriptor())
        self.metalLayer = CAMetalLayer()
        self.metalLayer.device = self.device
        self.layer = metalLayer

        do {
            try self.pipelineState = device.makeRenderPipelineState(descriptor: self.pipelineDescriptor())
        } catch {
            print("MetalView: pipeline state creation failed")
        }
    }

    var representedObject: Int?
    {
        didSet
        {
            render()
        }
    }

    func updateSize()
    {
        let newSize = CGSize(width: self.frame.size.width * 2,
                             height: self.frame.size.height * 2)

        if (self.metalLayer.drawableSize != newSize)
        {
            self.metalLayer.drawableSize = newSize
            self.render()
        }
    }

    override func resize(withOldSuperviewSize oldSize: NSSize)
    {
        //print("metal view resized", self.frame.size)
        self.updateSize()
    }

    override func scrollWheel(with event: NSEvent)
    {
        zcamera *= 1 + Float(event.deltaY) * 0.01
        zcamera = clamp(x:zcamera, low:1, high:100)
        self.render()
    }

    override func mouseDragged(with event: NSEvent)
    {
        xrotation += Float(event.deltaX) * 0.01
        yrotation += Float(event.deltaY) * 0.01
        self.render()
    }

    private func pipelineDescriptor() -> MTLRenderPipelineDescriptor
    {
        let defaultLibrary   = device.makeDefaultLibrary()
        let vertexFunction   = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        
        let d = MTLRenderPipelineDescriptor()

        d.vertexFunction   = vertexFunction
        d.fragmentFunction = fragmentFunction
        d.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        d.depthAttachmentPixelFormat      = MTLPixelFormat.depth32Float

        return d
    }

    private func depthStencilDescriptor() -> MTLDepthStencilDescriptor
    {
        let d = MTLDepthStencilDescriptor()

        d.depthCompareFunction = MTLCompareFunction.less
        d.isDepthWriteEnabled  = true

        return d;
    }

    private func depthTextureDescriptor(preparedFor texture: MTLTexture) -> MTLTextureDescriptor
    {
        // See the link below if multi-sampling will be used:
        //
        // https://developer.apple.com/library/archive/samplecode/MetalShaderShowcase/Listings/MetalShaderShowcase_AAPLView_mm.html
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.depth32Float,
                                                         width: texture.width,
                                                         height: texture.height,
                                                         mipmapped: false)
        d.sampleCount     = 1
        d.textureType     = MTLTextureType.type2D
        d.resourceOptions = MTLResourceOptions.storageModePrivate
        d.usage           = MTLTextureUsage.renderTarget

        return d;
    }

    private func renderPassDescriptor(preparedFor drawable: CAMetalDrawable) -> MTLRenderPassDescriptor
    {
        let d = MTLRenderPassDescriptor()

        d.colorAttachments[0].texture     = drawable.texture;
        d.colorAttachments[0].loadAction  = MTLLoadAction.clear;
        d.colorAttachments[0].storeAction = MTLStoreAction.store;
        d.colorAttachments[0].clearColor  = MTLClearColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1)

        d.depthAttachment.texture     = device.makeTexture(descriptor: self.depthTextureDescriptor(preparedFor: drawable.texture))
        d.depthAttachment.loadAction  = MTLLoadAction.clear
        d.depthAttachment.storeAction = MTLStoreAction.dontCare
        d.depthAttachment.clearDepth  = 1.0;

        return d;
    }

    private func render()
    {
        let scene = PythonRuntime.scene(Int32(self.representedObject ?? -1))
        let drawable = self.metalLayer.nextDrawable()
        let renderPassDescriptor = self.renderPassDescriptor(preparedFor: drawable!)
        let commandBuffer = self.commandQueue?.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)

        renderEncoder!.setRenderPipelineState(self.pipelineState!)
        renderEncoder!.setDepthStencilState(self.depthStencilState!)

        if (scene != nil)
        {
            for i in 0...SceneAPI.numNodes(scene) - 1
            {
                render(node: SceneAPI.node(scene, at: i), with: renderEncoder!)
            }
        }
        renderEncoder!.endEncoding()
        commandBuffer!.present(drawable!)
        commandBuffer!.commit()
    }

    private func render(node: OpaquePointer, with encoder: MTLRenderCommandEncoder)
    {
        let message = SceneAPI.nodeValidate(node)!

        if (!message.isEmpty)
        {
            print(message)
            return
        }
    
        let W = Float(self.frame.size.width)
        let H = Float(self.frame.size.height)
        let x = SceneAPI.nodePositionX(node)
        let y = SceneAPI.nodePositionY(node)
        let z = SceneAPI.nodePositionZ(node)

        var model = GLKMatrix4MakeTranslation (x, y, z)
        var view  = GLKMatrix4Rotate (GLKMatrix4Rotate (GLKMatrix4MakeTranslation (0, 0, -zcamera), xrotation, 0, 1, 0), yrotation, 1, 0, 0)
        var proj  = GLKMatrix4MakePerspective (1.0, W / H, 0.1, 1024.0)

        let vbuf = SceneAPI.nodeVertices (node, for: self.device)
        let cbuf = SceneAPI.nodeColors (node, for: self.device)

        encoder.setVertexBuffer(vbuf, offset: 0, index: Int(VertexInputVertices.rawValue))
        encoder.setVertexBuffer(cbuf, offset: 0, index: Int(VertexInputColors.rawValue))
        encoder.setVertexBytes(&model,     length: MemoryLayout<GLKMatrix4>.size, index: Int(VertexInputModelMatrix.rawValue))
        encoder.setVertexBytes(&view,      length: MemoryLayout<GLKMatrix4>.size, index: Int(VertexInputViewMatrix.rawValue))
        encoder.setVertexBytes(&proj,      length: MemoryLayout<GLKMatrix4>.size, index: Int(VertexInputProjMatrix.rawValue))
        encoder.drawPrimitives(type: SceneAPI.nodeType(node), vertexStart: 0, vertexCount: SceneAPI.nodeNumVertices(node))
    }

    private func clamp(x:Float, low:Float, high:Float) -> Float
    {
        return x > high ? high : (x < low) ? low : x
    }
}

