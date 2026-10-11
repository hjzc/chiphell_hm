import { IconData, StyleData, ToolBuild } from '../interface/PicturePreviewInterface'
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { promptAction } from '@kit.ArkUI';
import { PicturePreviewDataModel } from '../model/PicturePreviewDataModel';
import { common } from '@kit.AbilityKit';
import { PictureCacheUtil } from '../utils/PictureCacheUtil';

@Component
export struct Save{
  @Link saveIs: boolean
  @Prop styleData: StyleData = PicturePreviewDataModel.getInstance().styleData;
  @Prop toolBuild: ToolBuild = PicturePreviewDataModel.getInstance().toolBuild;
  @Prop iconData: IconData;
  private close: ()=>void = ()=>{
    this.saveIs = false;
  }

  private async saveImage(result:SaveButtonOnClickResult, uri: string) {
    let path: string = "";
    if(uri!== undefined){
      path = uri.replace(fileUri.getUriFromPath(""), "");
    }
    if (result == SaveButtonOnClickResult.SUCCESS) {
      try {
        // 获取应用上下文
        let appCtx :UIContext= AppStorage.get('UIContext') as UIContext;
        let context = appCtx.getHostContext() as common.UIAbilityContext; // this.getUIContext().
        if(context ==null){
          context =  getContext() as common.UIAbilityContext;
        }

        //const context = getContext(this);
        let helper = photoAccessHelper.getPhotoAccessHelper(context);
        // onClick触发后10秒内通过createAsset接口创建图片文件，10秒后createAsset权限收回。
        let acUri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
        // 使用uri打开文件，可以持续写入内容，写入过程不受时间限制
        let file = fileIo.openSync(acUri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        let file2 = fileIo.openSync(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        // 写入文件
        fileIo.copyFileSync(file2.fd, file.fd)
        // 关闭文件
        fileIo.closeSync(file.fd);
        fileIo.closeSync(file2.fd);
        this.showToast("保存成功");
        this.close()
      } catch (error) {
        console.error("save image error is "+ JSON.stringify(error));
        this.showToast( "保存失败");
      }
    }
  }

  private  showToast(message:string){
    const prompt = this.getUIContext().getPromptAction();
    try {
      prompt.showToast({
        message: '操作成功',
        duration: 2000
      });
    } catch (error) {
      // TODO: Implement error handling.
      console.error("show to toast error is "+ JSON.stringify(error));
    }
  }

  @Builder Save(){
    Column({space: 10}){
      Text("保存到相册")
        .margin({top: 20})
      Row(){
        SaveButton({text: SaveDescription.SAVE_TO_GALLERY})
          .width("50%")
          .height("50")
          .fontColor("#ff3cc800")
          .backgroundColor($r('sys.color.background_fourth'))
          .onClick((event:ClickEvent, result:SaveButtonOnClickResult) => {
            let path = this.iconData.path;
            if (path === undefined) {
              let ctx: Context = this.getUIContext().getHostContext() as common.UIAbilityContext;
              if (ctx!==undefined) {
                path = PictureCacheUtil.getFilePathFromUrl(ctx,this.iconData.path!, this.iconData.url! );
                if (path !==undefined) {
                  this.iconData.path = path;
                }
              }
            }
            this.saveImage(result, this.iconData.path!)

          })

        Text("取消")
          .width("50%")
          .height("50")
          .textAlign(TextAlign.Center)
          .fontColor("#ffb30000")
          .onClick(()=>{
            this.saveIs = false;
          })
      }.width("100%")
    }.width("90%")
    .constraintSize({
      maxWidth: 500
    })
    .backgroundColor($r('sys.color.background_fourth'))
    .borderRadius(15)
    .margin({bottom: 30})
    .onClick(()=>{})
  }


  // 自定义的保存按钮
  @BuilderParam saveDialog: (iconData: IconData, close: ()=>void)=>void = this.Save

  aboutToAppear(): void {
    if (this.toolBuild?.saveDialog) {
      this.saveDialog = this.toolBuild.saveDialog;
    }
  }

  build() {
    Column(){
      this.saveDialog(this.iconData, this.close)
    }.width("100%")
    .height("100%")
    .justifyContent(this.styleData?.saveLocation? this.styleData?.saveLocation : FlexAlign.End)
    .backgroundColor("#8f000000")
    .alignItems(HorizontalAlign.Center)
    .onClick(()=>{
      this.close()
    })
  }
}