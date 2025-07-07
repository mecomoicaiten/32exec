#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation+LC32.h>

LC32_CONST_STR_DECL(CAMediaTimingFillMode const kCAFillModeBoth)
LC32_CONST_STR_DECL(CAMediaTimingFillMode const kCAFillModeBackwards)
LC32_CONST_STR_DECL(CAMediaTimingFillMode const kCAFillModeForwards)
LC32_CONST_STR_DECL(CAMediaTimingFillMode const kCAFillModeRemoved)

LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityCenter)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityTop)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityLeft)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityRight)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityBottom)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityTopLeft)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityTopRight)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityBottomLeft)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityBottomRight)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityResize)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityResizeAspect)
LC32_CONST_STR_DECL(CALayerContentsGravity const kCAGravityResizeAspectFill)

LC32_CONST_STR_DECL(CAMediaTimingFunctionName const kCAMediaTimingFunctionLinear)
LC32_CONST_STR_DECL(CAMediaTimingFunctionName const kCAMediaTimingFunctionEaseIn)
LC32_CONST_STR_DECL(CAMediaTimingFunctionName const kCAMediaTimingFunctionEaseOut)
LC32_CONST_STR_DECL(CAMediaTimingFunctionName const kCAMediaTimingFunctionEaseInEaseOut)
LC32_CONST_STR_DECL(CAMediaTimingFunctionName const kCAMediaTimingFunctionDefault)

LC32_CONST_STR_DECL(CATransitionType const kCATransitionFade);
LC32_CONST_STR_DECL(CATransitionType const kCATransitionMoveIn);
LC32_CONST_STR_DECL(CATransitionType const kCATransitionPush);
LC32_CONST_STR_DECL(CATransitionType const kCATransitionReveal);

__attribute__((constructor)) void QuartzCoreInit() {
    LC32_CONST_STR_INIT(kCAFillModeBoth);
    LC32_CONST_STR_INIT(kCAFillModeBackwards);
    LC32_CONST_STR_INIT(kCAFillModeForwards);
    LC32_CONST_STR_INIT(kCAFillModeRemoved);

    LC32_CONST_STR_INIT(kCAGravityCenter);
    LC32_CONST_STR_INIT(kCAGravityTop);
    LC32_CONST_STR_INIT(kCAGravityLeft);
    LC32_CONST_STR_INIT(kCAGravityRight);
    LC32_CONST_STR_INIT(kCAGravityBottom);
    LC32_CONST_STR_INIT(kCAGravityTopLeft);
    LC32_CONST_STR_INIT(kCAGravityTopRight);
    LC32_CONST_STR_INIT(kCAGravityBottomLeft);
    LC32_CONST_STR_INIT(kCAGravityBottomRight);
    LC32_CONST_STR_INIT(kCAGravityResize);
    LC32_CONST_STR_INIT(kCAGravityResizeAspect);
    LC32_CONST_STR_INIT(kCAGravityResizeAspectFill);

    LC32_CONST_STR_INIT(kCAMediaTimingFunctionLinear);
    LC32_CONST_STR_INIT(kCAMediaTimingFunctionEaseIn);
    LC32_CONST_STR_INIT(kCAMediaTimingFunctionEaseOut);
    LC32_CONST_STR_INIT(kCAMediaTimingFunctionEaseInEaseOut);
    LC32_CONST_STR_INIT(kCAMediaTimingFunctionDefault);

    LC32_CONST_STR_INIT(kCATransitionFade);
    LC32_CONST_STR_INIT(kCATransitionMoveIn);
    LC32_CONST_STR_INIT(kCATransitionPush);
    LC32_CONST_STR_INIT(kCATransitionReveal);
}
