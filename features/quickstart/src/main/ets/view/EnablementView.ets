import {ArticleClass} from '../model/ArticleClass'
import { bufferToString } from "../util/BufferUtil";
import { BreakpointType, BreakpointTypeEnum } from 'utils';

@Component
export  struct EnablementItem {
  @Prop enablementItem: ArticleClass;

  build() {
    Column() {
      Image($r(this.enablementItem.imageSrc))
        .width('100%')
        .objectFit(ImageFit.Cover)
        .height(96)
        .borderRadius({
          topLeft: 16,
          topRight: 16
        })
      Text(this.enablementItem.title)
        .height(19)
        .width('100%')
        .fontSize(14)
        .textAlign(TextAlign.Start)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .fontWeight(400)
        .padding({ left: 12, right: 12 })
        .margin({ top: 8 })
      Text(this.enablementItem.brief)
        .height(32)
        .width('100%')
        .fontSize(12)
        .textAlign(TextAlign.Start)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(2)
        .fontWeight(400)
        .fontColor('rgba(0, 0, 0, 0.6)')
        .padding({ left: 12, right: 12 })
        .margin({ top: 2 })
    }
    .width(160)
    .height(169)
    .borderRadius(16)
    .backgroundColor(Color.White)
  }
}

@Preview
@Component
export  struct EnablementView {
  @Consume('articlePathStack') articlePathStack: NavPathStack;
  @State enablementList: Array<ArticleClass> = [];
  //适配不同屏幕
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.MD;

  getBannerDataFromJSON(){
    this.getUIContext().getHostContext()?.resourceManager.getRawFileContent('EnablementData.json').then(value=>{
      let res:string = bufferToString(value);
      this.enablementList = JSON.parse(res) as ArticleClass[];
    });
  }

  aboutToAppear(): void {
    this.getBannerDataFromJSON();
  }
  build() {
    Column() {
      Text('赋能套件')
        .fontColor('#182431')
        .fontSize(16)
        .fontWeight(500)
        .fontFamily('HarmonyHeiTi-medium')
        .textAlign(TextAlign.Start)
        .padding({ left: 16 })
        .margin({ bottom: 8.5 })
      Grid() {
        ForEach(this.enablementList, (item: ArticleClass) => {
          GridItem() {
            EnablementItem({ enablementItem: item })
              .onClick(() => {
                this.articlePathStack.pushPathByName('articleDetail', item)
              })
          }
          //适配不同屏幕 在sm、md、lg断点下分别呈现160、164、180的尺寸，
          .width(new BreakpointType<Length>({ sm: 160, md: 164, lg: 180 }).getValue(this.currentBreakpoint))

        }, (item: ArticleClass) => item.id)
      }
      //控制列间距。其次，网格组件的列间距在不同设备上也不一致，在sm、md、lg断点尺寸下分别列间距分别为8、12、16，可以使用columnsGap属性配合断点选值来实现。
      .columnsGap(new BreakpointType<Length>({ sm: 8, md: 12, lg: 16 }).getValue(this.currentBreakpoint))

      .rowsTemplate('1fr')
      .columnsGap(8)
      .scrollBar(BarState.Off)
      .height(169)
      .padding({ top: 2, left: 16, right: 16 })

    }
    .margin({ top: 18 })
    .alignItems(HorizontalAlign.Start)
  }
}
