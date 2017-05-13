import Cocoa
@testable import Utils
/**
 * This UIComponent consist of 3 skin layers
 * Layer 0: Background is always green and has a grey stroke
 * Layer 1: blends from white to grey, and animates like an iris dilating.
 * Layer 2: Is the thumb  w/ Dropshadow, White fill and stroke blends from grey to green
 * TODO: ⚠️️ A problem is that you set the skinStyle in two animators that have different durations
 * TODO: instead of recreating Animators rather init them once and then start and stop them?
 * 1. a solution is to be able to directly set style to skin layers
 * 2. investigate if this is possible and if not possibly use temp variables
 * 3. or use 3 different elements to get things working
 */
class Switch:SwitchSlider,ICheckable{
    var bgColorAnimator:Animator?/*layer 1: grey to white anim*/
    var bgIrisAnimator:Animator?/*layer 1: dilate iris animation*/
    var thumbWidthAnimator:Animator?/*Layer 2: expands and contracts the width of the thumb*/
    var thumbXAnimator:Animator?/*Layer 2: moves the thumb in the x-axis*/
    var disableMouseUp:Bool = false//Don't setChecked if progress threshold has been crossed: 0.5
    var irisData:(size:CGSize,fillet:CGFloat,center:CGPoint) = (CGSize(140,80),40,CGPoint(140/2,80/2))//Stores the dimensions for the iris animation
    private var isChecked:Bool
    init(_ width:CGFloat, _ height:CGFloat, _ isChecked:Bool = false, _ parent:IElement? = nil, _ id:String? = nil, _ classId:String? = nil) {
        self.isChecked = isChecked
        super.init(width,height,isChecked ? 1:0,parent,id)
    }
    override func onMouseMove(event:NSEvent)->NSEvent?{
        let event = super.onMouseMove(event:event)
        if(progress == 1 && !isChecked){
            setChecked(true)
            super.onEvent(CheckEvent(CheckEvent.check, isChecked, self))
            disableMouseUp = true
        }else if(progress == 0 && isChecked){
            setChecked(false)
            super.onEvent(CheckEvent(CheckEvent.check, isChecked, self))
            disableMouseUp = true
        }
        return event
    }
    override func mouseDown(_ event:MouseEvent) {
        //Swift.print("Switch.mouseDown isChecked: \(isChecked)")
        let style:IStyle = self.skin!.style!//StyleModifier.clone(thumb!.skin!.style!, thumb!.skin!.style!.name)
        var widthProp = style.getStyleProperty("width",2)
        widthProp!.value = 80
        var marginProp = style.getStyleProperty("margin-left",2) /*edits the style*/
        marginProp!.value = progress == 1 ? 20  : 0
        self.skin!.setStyle(style)/*updates the skin*/
        /*bg color Anim*/
        if(bgColorAnimator != nil){bgColorAnimator!.stop()}
        bgColorAnimator = Animator(Animation.sharedInstance,0.4,0,1,bgColorAnim,Linear.ease)/*from 0 to 1*/
        bgColorAnimator!.start()
        /*Thumb width Anim*/
        if(thumbWidthAnimator != nil){thumbWidthAnimator!.stop()}
        thumbWidthAnimator = Animator(Animation.sharedInstance,0.2,0,1,thumbWidthAnim,Linear.ease)/*from 0 to 1*/
        thumbWidthAnimator!.start()
        super.mouseDown(event)
    }
    override func mouseUpInside(_ event: MouseEvent) {
        //Swift.print("Switch.mouseUpInside")
        if(!disableMouseUp){
            setChecked(!isChecked)
        }
        disableMouseUp = false/*reset*/
        super.mouseUpInside(event)
        super.onEvent(CheckEvent(CheckEvent.check, isChecked, self))
    }
    override func mouseUpOutside(_ event: MouseEvent) {
        //Swift.print("Switch.mouseUpOutside")
        disableMouseUp = false/*reset*/
        super.mouseUpOutside(event)
    }
    override func mouseUp(_ event: MouseEvent) {
        //Swift.print("Switch.mouseUp")
        /*Bg color Anim*/
        if(bgColorAnimator != nil){bgColorAnimator!.stop()}
        bgColorAnimator = Animator(Animation.sharedInstance,0.4,1,0,bgColorAnim,Linear.ease)/*from 1 to 0*/
        bgColorAnimator!.start()
        /*Thumb width Anim*/
        if(thumbWidthAnimator != nil){thumbWidthAnimator!.stop()}
        thumbWidthAnimator = Animator(Animation.sharedInstance,0.2,1,0,thumbWidthAnim,Linear.ease)/*from 1 to 0*/
        thumbWidthAnimator!.start()
        super.mouseUp(event)
    }
    func setChecked(_ isChecked:Bool) {
        //Swift.print("setChecked: " + "\(isChecked)")
        if(thumbXAnimator != nil){thumbXAnimator!.stop()}
        if(bgIrisAnimator != nil){bgIrisAnimator!.stop()}
        if(self.isChecked && !isChecked){
            thumbXAnimator = Animator(Animation.sharedInstance,0.5,1,0,thumbXAnim,Back.easeOut)/*from 1 - 0*/
            bgIrisAnimator = Animator(Animation.sharedInstance,0.2,1,0,bgIrisAnim,Quad.easeOut)/*from 1 - 0*/
        }else if (!self.isChecked && isChecked){
            thumbXAnimator = Animator(Animation.sharedInstance,0.5,0,1,thumbXAnim,Back.easeOut)/*from 0 - 1*/
            bgIrisAnimator = Animator(Animation.sharedInstance,0.3,0,1,bgIrisAnim,Quad.easeOut)/*from 0 - 1*/
        }
        bgIrisAnimator!.start()
        thumbXAnimator!.start()
        self.isChecked = isChecked
        //setSkinState(getSkinState())
    }
    func getChecked() -> Bool {
        return isChecked
    }
    override func getSkinState() -> String {
        return isChecked ? SkinStates.checked + " " + super.getSkinState() : super.getSkinState()
    }
    required init(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}
}
/**
 * We have the animation stuff in an extension to separate different parts of the code and make it more readable
 */
extension Switch{
    func thumbXAnim(value:CGFloat){
        progress = value
        let style:IStyle = skin!.style!
        var offsetProp = skin!.style!.getStyleProperty("offset",2)
        let thumbWidth:CGFloat = 100/*thumbWidth is always 100*/
        let thumbX = HSliderUtils.thumbPosition(progress, width, thumbWidth)
        offsetProp!.value = [thumbX, 0]
        /*ThumbLine*/
        var thumbLineProp = style.getStyleProperty("line",2) /*Edits the style*/
        if(thumbLineProp != nil){//temp
            let color:NSColor = grey.blended(withFraction: value, of: green)!
            thumbLineProp!.value = color
        }
        skin!.setStyle(style)
    }
    func thumbWidthAnim(value:CGFloat){
        let style:IStyle = skin!.style!//StyleModifier.clone(thumb!.skin!.style!, thumb!.skin!.style!.name)
        var marginProp = style.getStyleProperty("margin-left",2) /*edits the style*/
        marginProp!.value = getChecked() ? 20 * (1-value) : 0
        var widthProp = style.getStyleProperty("width",2)
        widthProp!.value = 80 + (20 * value)
        skin!.setStyle(style)
    }
    func bgColorAnim(value:CGFloat){
        let style:IStyle = StyleModifier.clone(skin!.style!,skin!.style!.name)/*we clone the style so other Element instances doesnt get their style changed aswell*/// :TODO: this wont do if the skin state changes, therefor we need something similar to DisplayObjectSkin
        var fillProp = style.getStyleProperty("fill",1) /*edits the style*/
        let initColor = white
        let endColor = grey
        let color = initColor.blended(withFraction: value, of: endColor)!
        fillProp!.value = color
        skin!.setStyle(style)
    }
    func bgIrisAnim(value:CGFloat){
        let progress = value
        /*bg*/
        let sizeMultiplier = 1 - progress//we need values from 1 to 0
        let style:IStyle = StyleModifier.clone(skin!.style!,skin!.style!.name)/*We clone the style so other Element instances doesnt get their style changed aswell*/// :TODO: this wont do if the skin state changes, therefor we need something similar to DisplayObjectSkin
        var widthProp = style.getStyleProperty("width",1)
        widthProp!.value = irisData.size.width * sizeMultiplier//CGFloatParser.interpolate(initW,0,progress)
        var heightProp = style.getStyleProperty("height",1)
        heightProp!.value = irisData.size.height * sizeMultiplier
        var cornerRadiusProp = style.getStyleProperty("corner-radius",1)
        cornerRadiusProp!.value = irisData.fillet * sizeMultiplier
        var offsetProp = style.getStyleProperty("offset",1)//center align the scaling of the white bg graphic
        offsetProp!.value = [irisData.center.x * progress, irisData.center.y * progress]
        skin!.setStyle(style)/*updates the skin*/
    }
}
extension Switch{/*Conveniently store colors used*/
    var green:NSColor {return NSColorParser.nsColor(UInt(0x39D149))}
    var grey:NSColor {return NSColorParser.nsColor(UInt(0xDCDCDC))}
    var white:NSColor {return NSColor.white}
}
class SwitchSlider:Element {/*Incorporates the sliding part of the Switch*/
    var progress:CGFloat
    var leftMouseDraggedEventListener:Any?
    init(_ width:CGFloat, _ height:CGFloat, _ progress:CGFloat = 0, _ parent:IElement? = nil, _ id:String? = nil, _ classId:String? = nil) {
        self.progress = progress
        super.init(width,height,parent,id)
    }
    func onMouseMove(event:NSEvent)-> NSEvent?{
        progress = HSliderUtils.progress(event.localPos(self).x, 0/*thumbWidth/2*/, width, /*thumbWidth*/ 0)
        super.onEvent(SliderEvent(SliderEvent.change,progress,self))
        return event
    }
    override func mouseDown(_ event:MouseEvent) {
        progress = HSliderUtils.progress(event.event!.localPos(self).x, /*thumbWidth/2*/0, width, /*thumbWidth*/0)
        leftMouseDraggedEventListener = NSEvent.addLocalMonitorForEvents(matching:[.leftMouseDragged], handler:onMouseMove )//we add a global mouse move event listener
        //super.mouseDown(event)/*passes on the event to the nextResponder, NSView parents etc*/
    }
    override func mouseUp(_ event:MouseEvent) {
        if(leftMouseDraggedEventListener != nil){NSEvent.removeMonitor(leftMouseDraggedEventListener!);leftMouseDraggedEventListener = nil}//we remove a global mouse move event listener
    }
    required init(coder: NSCoder) {fatalError("init(coder:) has not been implemented")}
}
