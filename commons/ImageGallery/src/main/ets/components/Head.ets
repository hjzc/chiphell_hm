import { PicturePreviewDataModel } from '../model/PicturePreviewDataModel';
import { PictureCacheUtil } from '../utils/PictureCacheUtil';
import { common } from '@kit.AbilityKit';

@Component
export struct Head{
  @Link index: number;
  iconSum: number = 0;
  backIcon: ResourceStr = $r('app.media.photo_gallery_public_arrow_left')
  onBack: ()=>void = ()=>{}

  build() {
    Stack() {

      Row() {
        Text((this.index + 1) + "/" +this.iconSum)
          .fontSize(18)
          .fontColor("#fff")
      }
      .width("100%")
      .justifyContent(FlexAlign.Center)
      .padding({top: 35, left: 15, right: 15})

      // 是否展示返回按钮
      if (PicturePreviewDataModel.getInstance().functionData.isBack) {
        Row() {
          if (this.backIcon.toString() == "[object Object]" || this.backIcon.toString().includes("http")) {
            Image(this.backIcon.toString().includes('http')?new PictureCacheUtil(this.getUIContext().getHostContext() as common.UIAbilityContext).getPathOrUrl('', this.backIcon as string,null):this.backIcon)
              .height(35)
              .width(35)
              .onClick(()=>{
                this.onBack()
              })
          } else {
            Text(this.backIcon)
              .fontColor("#fff")
              .onClick(()=>{
                this.onBack()
              })
          }
        }.width("100%")
        .justifyContent(FlexAlign.Start)
        .padding({top: 35, left: 15, right: 15})
      }


    }
  }
}