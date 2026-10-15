import { PicturePreviewDataModel } from '../model/PicturePreviewDataModel';
import { PictureCacheUtil } from '../utils/PictureCacheUtil';
import { common } from '@kit.AbilityKit';

@Component
export struct Head{
  @Link index: number;
  @Link ableSave:boolean;
  iconSum: number = 0;
  backIcon: ResourceStr = $r('app.media.photo_gallery_public_arrow_left')
  saveIcon: ResourceStr = $r('app.media.photo_gallery_public_save')
  onBack: ()=>void = ()=>{}
  onSave: ()=>void = ()=>{}

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
        if((PicturePreviewDataModel.getInstance().functionData.isNavSave==true) &&
          (  PicturePreviewDataModel.getInstance().functionData.isDynamicNavSave==true? this.ableSave: true ) ){
          Row() {
            this.navLeftButton()
            this.navRightButton()
          }.width("100%")
          .justifyContent(FlexAlign.SpaceBetween)
          .padding({top: 35, left: 15, right: 15})
        }
        else {
          Row() {
            this.navLeftButton()
          }.width("100%")
          .justifyContent(FlexAlign.Start)
          .padding({top: 35, left: 150, right: 15})
        }

      }else   if((PicturePreviewDataModel.getInstance().functionData.isNavSave==true) &&
        (  PicturePreviewDataModel.getInstance().functionData.isDynamicNavSave==true? this.ableSave: true ) ){
        Row() {
          this.navRightButton()
        }.width("100%")
        .justifyContent(FlexAlign.End)
        .padding({top: 35, left: 150, right: 15})
      }
    }
  }

  @Builder navLeftButton() {
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
  }

  @Builder navRightButton() {
    if (this.saveIcon.toString() == "[object Object]" || this.saveIcon.toString().includes("http")) {
      Image(this.saveIcon.toString().includes('http')?new PictureCacheUtil(this.getUIContext().getHostContext() as common.UIAbilityContext).getPathOrUrl('', this.saveIcon as string,null):this.saveIcon)
        .height(35)
        .width(35)
        .onClick(()=>{
          this.onSave()
        })
    } else {
      Text(this.saveIcon)
        .fontColor("#fff")
        .onClick(()=>{
          this.onSave()
        })
    }
  }

}