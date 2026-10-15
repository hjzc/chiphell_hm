
@ObservedV2
export class  NavBarItemData {
  order: number;
  icon:string;
  title: Resource|string;
  @Trace trailing:Resource| string;

  constructor(order: number, icon:string, title:Resource|string, trailing:Resource|string ){
    this.order =order;
    this.icon =icon;
    this.title =title;
    this.trailing =trailing;
  }

}

@ComponentV2
export struct SetNavItemView {
  @Event click: (index:number) => void;
  @Require @Param item: NavBarItemData;
  build() {
    Row() {
      if(this.item.icon.length>0){
        Image($r(this.item.icon))
          .width(20)
          .height(20)
      }
      Text(this.item.title)
        .fontFamily('HarmonyHeiTi-Medium')
        .fontSize(16)
        .fontColor($r('sys.color.font_primary'))
        .textAlign(TextAlign.Start)
        .lineHeight(22)
        .fontWeight(500)
      Blank()
      Text(this.item.trailing)
        .fontFamily('HarmonyHeiTi-Medium')
        .fontSize(14)
        .fontColor($r('sys.color.font_secondary'))
        .textAlign(TextAlign.Start)
        .lineHeight(22)
        .fontWeight(500)
      Image($r('app.media.ic_arrow'))
        .width(12)
        .height(24)
        .fillColor($r('sys.color.icon_primary'))
        //.backgroundColor(Color.Red) // 添加红色背景
    }
    .width('100%')
    .height(48)
    .borderRadius(16)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('sys.color.background_tertiary'))
    .onClick(()=>{
      this.click(this.item.order);
    })
  }
}

