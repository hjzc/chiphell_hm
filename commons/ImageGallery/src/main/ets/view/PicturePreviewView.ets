import { MyDataSource } from '../model/MyDataSource'
import { FunctionData, IconData, PicturePreviewData, StyleData, ToolBuild } from '../interface/PicturePreviewInterface'
import { PicturePreview } from '../PicturePreview'
import { Head } from '../components/Head'
import { Images } from '../components/Images'
import { Save } from '../components/Save'
import { Tools } from '../components/Tools'
import { PicturePreviewDataModel } from '../model/PicturePreviewDataModel'

@Builder
export function PicturePreviewView(picturePreviewData: PicturePreviewData){
  PicturePreviewItem({
    picturePreviewData: new MyDataSource<IconData>(picturePreviewData.iconDatas),
    index: picturePreviewData.index,
  })
}

@Component
struct PicturePreviewItem{
  @Prop picturePreviewData: MyDataSource<IconData>;
  //index 变化，执行getData函数
  @Prop @Watch("getData") index: number = 0;
  @Prop @Watch("getDataValid")  imageValid: boolean=false;

  @Prop functionData: FunctionData = PicturePreviewDataModel.getInstance().functionData;
  @Prop styleData: StyleData = PicturePreviewDataModel.getInstance().styleData;
  @Prop toolBuild: ToolBuild = PicturePreviewDataModel.getInstance().toolBuild;
  @State saveIs: boolean = false;
  @State theIconData: IconData = this.picturePreviewData.getData(this.index);
  @Prop ableSave: boolean;

  aboutToAppear(): void {
    // 没什么用，单纯编辑器好看
    this.getData;
  }

  private getData(){
    this.theIconData = this.picturePreviewData.getData(this.index)
    this.imageValid = this.theIconData.path!=undefined;
  }

  private getDataValid(){
    this.ableSave = this.imageValid;
  }

  build() {
    Stack({alignContent: Alignment.TopStart}){
      // 图片展示区域
      Images({
        index: this.index,
        imageValid:this.imageValid,
        iconDatas: this.picturePreviewData,
        loading: this.toolBuild.loading,
      })
      // 位置指示器
      if (this.functionData.indicator){
        Head({
          index: this.index,
          ableSave:this.ableSave,
          iconSum: this.picturePreviewData.totalCount(),
          backIcon: this.functionData.backIcon,
          onBack: ()=>{
            PicturePreview.close()
          },
          onSave:()=>{
            // 打开保存到相册弹框
            if (this.functionData.saveAlbum) {
              this.saveIs = true;
            }
          }

        })
      }
      if (this.toolBuild.tools) {
        Tools({
          iconData: this.theIconData,
          tools: this.toolBuild.tools
        })
      }
      if (this.saveIs) {
        Save({
          saveIs: this.saveIs,
          iconData: this.theIconData,
        })
      }
    }.backgroundColor(this.styleData.bgColor)
    .width("100%")
    .height("100%")
    .gesture(
      LongPressGesture()
        .onAction(()=>{
          // 监听长按
          let fn = PicturePreviewDataModel.getInstance().listener.onLongPress!;
          let is = fn(this.index, this.picturePreviewData.getData(this.index))
          if (is) return;
          // 打开保存到相册弹框
          if (this.functionData.saveAlbum) {
            this.saveIs = true;
          }
        })
    )
  }
}

