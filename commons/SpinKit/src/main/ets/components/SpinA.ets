
/**
 * TODO SpinKit动画组件
 * author: Zorro
 * since: 2024/05/01
 */
@ComponentV2
export struct SpinA {
  @Require @Param spinSize: number;
  @Require @Param spinColor: ResourceColor;
  @Local x: number = 0;
  @Local y: number = 0;
  @Local angle: number = 0;

  build() {
    Canvas()
      .width(this.spinSize)
      .height(this.spinSize)
      .backgroundColor(this.spinColor)
      .renderFit(RenderFit.CENTER)
      .shadow(ShadowStyle.OUTER_DEFAULT_XS)
      .rotate({ perspective: this.spinSize, x: this.x, y: this.y, angle: this.angle })
      .onAppear(() => {
        this.getUIContext().keyframeAnimateTo({ iterations: -1, delay: 0 }, [
          {
            duration: 600,
            curve: Curve.EaseInOut,
            event: () => {
              this.angle = 180
              this.x = this.spinSize/2
              this.y = 0
            }
          },
          {
            duration: 0,
            curve: Curve.EaseInOut,
            event: () => {
              this.angle = 0
            }
          },
          {
            duration: 600,
            curve: Curve.EaseInOut,
            event: () => {
              this.angle = 180
              this.x = 0
              this.y = this.spinSize/2
            }
          }
        ])
      })
  }
}