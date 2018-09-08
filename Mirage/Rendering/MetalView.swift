import Cocoa
import Metal
import MetalKit
import GLKit




// ============================================================================
class MetalView: NSView
{
    var device:            MTLDevice!
    var pipelineState:     MTLRenderPipelineState!
    var depthStencilState: MTLDepthStencilState!
    var commandQueue:      MTLCommandQueue!
    var metalLayer:        CAMetalLayer!
    var zcamera:           Float = 10.0
    var camera = Camera()

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
        self.camera.changeCallback = { [weak self] in self?.render() }

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

        camera.viewport = self.frame.size

        if (self.metalLayer.drawableSize != newSize)
        {
            self.metalLayer.drawableSize = newSize
            self.render()
        }
    }

    override func resize(withOldSuperviewSize oldSize: NSSize)
    {
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
        camera.dragAroundAnchor(with: self.convert(event.locationInWindow, from: nil))
    }

    override func mouseDown(with event: NSEvent)
    {
        if (event.clickCount == 2)
        {
            camera.animateToNoRotation()
        }
        else
        {
            camera.setAnchor(with: self.convert(event.locationInWindow, from: nil))
        }
    }

    private func pipelineDescriptor() -> MTLRenderPipelineDescriptor
    {
        let defaultLibrary   = device.makeDefaultLibrary()
        let vertexFunction   = defaultLibrary?.makeFunction(name: "vertexShader")
        let fragmentFunction = defaultLibrary?.makeFunction(name: "fragmentShader")
        
        let d = MTLRenderPipelineDescriptor()

        d.vertexFunction   = vertexFunction
        d.fragmentFunction = fragmentFunction
        d.depthAttachmentPixelFormat      = MTLPixelFormat.depth32Float

        d.colorAttachments[0].pixelFormat = MTLPixelFormat.bgra8Unorm
        d.colorAttachments[0].isBlendingEnabled = true
        d.colorAttachments[0].rgbBlendOperation = .add
        d.colorAttachments[0].alphaBlendOperation = .add
        d.colorAttachments[0].sourceRGBBlendFactor = .one
        d.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        d.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        d.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

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

    private func dummyTextureDescriptor() -> MTLTextureDescriptor
    {
        let d = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm,
                                                         width: 1,
                                                         height: 1,
                                                         mipmapped: false)
        d.sampleCount     = 1
        d.textureType     = MTLTextureType.type2D
        d.resourceOptions = MTLResourceOptions.storageModePrivate
        d.usage           = MTLTextureUsage.shaderRead
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

    func render()
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
            for i in 0..<SceneAPI.numNodes(scene)
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
        let ex = SceneAPI.nodeRotationVectorX(node)
        let ey = SceneAPI.nodeRotationVectorY(node)
        let ez = SceneAPI.nodeRotationVectorZ(node)
        let et = SceneAPI.nodeRotationVectorT(node)

        var model = float4x4.makeTranslation(x, y, z) * float4x4.makeRotate(radians: et, ex, ey, ez)
        var view  = float4x4.makeTranslation(0, 0, -zcamera) * camera.rotation
        var proj  = float4x4.makePerspective(fovyRadians: 1.0, W / H, 1e-1, 1e3)

        let vbuf = SceneAPI.nodeVertices(node, for: self.device)
        let cbuf = SceneAPI.nodeColors  (node, for: self.device)
        let nbuf = SceneAPI.nodeNormals (node, for: self.device)

        let L = MTKTextureLoader(device: device)
        let I = SceneAPI.nodeImageTexture(node)
        let T = I != nil ? try! L.newTexture(cgImage: I!.cgImage!) : device.makeTexture(descriptor: self.dummyTextureDescriptor())!

        var options = ShaderOptions()
        options.isTextureActive = I != nil
        options.hasNormals = SceneAPI.nodeHasNormals(node)

        encoder.setVertexBuffer(vbuf, offset: 0, index: Int(VertexInputVertices.rawValue))
        encoder.setVertexBuffer(cbuf, offset: 0, index: Int(VertexInputColors.rawValue))
        encoder.setVertexBuffer(nbuf, offset: 0, index: Int(VertexInputNormals.rawValue))
        encoder.setVertexBytes(&model,     length: MemoryLayout<GLKMatrix4>.size,    index: Int(VertexInputModelMatrix.rawValue))
        encoder.setVertexBytes(&view,      length: MemoryLayout<GLKMatrix4>.size,    index: Int(VertexInputViewMatrix.rawValue))
        encoder.setVertexBytes(&proj,      length: MemoryLayout<GLKMatrix4>.size,    index: Int(VertexInputProjMatrix.rawValue))
        encoder.setVertexBytes(&options,   length: MemoryLayout<ShaderOptions>.size, index: Int(VertexInputOptions.rawValue))

        encoder.setFragmentTexture(T, index: Int(FragmentInputTexture2D.rawValue))
        encoder.setFragmentBytes(&options, length: MemoryLayout<ShaderOptions>.size, index: Int(FragmentInputOptions.rawValue))
        encoder.drawPrimitives(type: SceneAPI.nodeType(node), vertexStart: 0, vertexCount: SceneAPI.nodeNumVertices(node))
    }

    private func clamp(x:Float, low:Float, high:Float) -> Float
    {
        return x > high ? high : (x < low) ? low : x
    }
}

