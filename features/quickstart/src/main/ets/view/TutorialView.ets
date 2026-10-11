
import {ArticleClass} from '../model/ArticleClass'
import { bufferToString } from "../util/BufferUtil";
import { BreakpointType, BreakpointTypeEnum } from 'utils';

@Component
struct TutorialItem {
  @Prop tutorialItem: ArticleClass;

  build() {
    Row() {
      Column() {
        Text(this.tutorialItem.title)
          .height(19)
          .width('100%')
          .fontSize(14)
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .fontWeight(400)
          .margin({ top: 4 })
        Text(this.tutorialItem.brief)
          .height(32)
          .width('100%')
          .fontSize(12)
          .textAlign(TextAlign.Start)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(2)
          .fontWeight(400)
          .fontColor('rgba(0, 0, 0, 0.6)')
          .margin({ top: 5 })
      }
      .height('100%')
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ right: 12 })

      Image($r(this.tutorialItem.imageSrc))
        .objectFit(ImageFit.Cover)
        .height(64)
        .width(108)
        .borderRadius(16)
    }
    .width('100%')
    .height(88)
    .borderRadius(16)
    .backgroundColor($r('sys.color.background_tertiary'))
   // .backgroundColor( Color.White)
    .padding(12)
    .alignItems(VerticalAlign.Top)
  }
}



@Preview
@Component
export  struct TutorialView {
  @State tutorialList: Array<ArticleClass> = [
    // new ArticleClass('1', $r('app.media.tutorial_pic1'), 'Step1 环境的搭建',
    //   '本篇教程实现了快速入门——一个用于了解和学习HarmonyOS的应用程序。',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
    // new ArticleClass('2', $r('app.media.tutorial_pic2'), 'Step2 使用Swiper构建运营广告位',
    //   'Swiper组件提供滑动轮播显示的能力。Swiper本身是一个容器组件，当设置了多个子组件后，可以对这些子组件进行轮播显示。',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
    // new ArticleClass('3', $r('app.media.tutorial_pic3'), 'Step3 创建和组合视图',
    //   'Item定义子组件相关特征。相关组件支持使用条件渲染、循环渲染、懒加载等方式生成子组件。',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
    // new ArticleClass('4', $r('app.media.tutorial_pic4'), 'Step4 网格和列表组建的使用',
    //   '网格和列表组件中，当Item达到一定数量，内容超过屏幕大小时，可以自动提供滚动功能，适合用于呈现同类数据类型或数据类型集',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
    // new ArticleClass('5', $r('app.media.tutorial_pic5'), 'Step5 应用架构设计基础——MVVM模式',
    //   'ArkUI采取MVVM = Model + View + ViewModel模式，将数据与视图绑定在一起，更新数据的时候直接更新视图。',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
    // new ArticleClass('6', $r('app.media.tutorial_pic6'), 'Step6 应用架构设计基础——三层架构',
    //   '为了更好地适配复杂应用的开发，建议采用三层架构的方式对整个应用的功能进行模块化，实现高内聚、低耦合开发。',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
    // new ArticleClass('7', $r('app.media.tutorial_pic7'), 'Step6 ArkWeb页面适配',
    //   'ArkWeb（方舟Web）提供了Web组件，用于在应用程序中显示Web页面内容，为开发者提供页面加载、页面交互、页面调试等能力。',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
    // new ArticleClass('8', $r('app.media.tutorial_pic8'), 'Step7 数据驱动UI更新', '数据更新的同时会直接驱动UI的改变',
    //   'xxx'),
    // new ArticleClass('9', $r('app.media.tutorial_pic9'), 'Step8 设置组件导航',
    //   'Navigation组件适用于模块内页面切换，一次开发，多端部署场景。通过组件级路由能力实现更加自然流畅的转场体验，并提供多种标题栏样式来呈现更好的标题和内容联动效果。',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
    // new ArticleClass('10', $r('app.media.tutorial_pic10'), 'Step9 原生智能：AI语音朗读',
    //   '文本转语音服务提供将文本信息转换为语音并进行播报的能力，便于用户与设备进行互动，实现实时语音交互，文本播报。',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
    // new ArticleClass('11', $r('app.media.tutorial_pic11'), 'Step10 原生互联：分布式流转',
    //   '流转能力打破设备界限，多设备联动，使用户应用程序可分可合、可流转，实现如邮件跨设备编辑、多设备协同健身、多屏游戏等分布式业务。',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
    // new ArticleClass('12', $r('app.media.tutorial_pic12'), 'Step11 一次开发，多端部署',
    //   '一套代码工程，一次开发上架，多端按需部署。支撑开发者快速高效的开发支持多种终端设备形态的应用，实现对不同设备兼容的同时，提供跨设备的流转、迁移和协同的分布式体验。',
    //   'https://developer.huawei.com/consumer/cn/forum/home?all=1'),
  ];
  @Consume('articlePathStack') articlePathStack: NavPathStack;
  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.MD;

  getBannerDataFromJSON(){
    this.getUIContext().getHostContext()?.resourceManager.getRawFileContent('TutorialData.json').then(value=>{
      let res:string = bufferToString(value);
      this.tutorialList = JSON.parse(res) as ArticleClass[];
    });
  }

  aboutToAppear(): void {
    this.getBannerDataFromJSON();
  }
  build() {
    Column() {
      Text('入门教程')
        .fontColor('#182431')
        .fontSize(16)
        .fontWeight(500)
        .fontFamily('HarmonyHeiTi-medium')
        .textAlign(TextAlign.Start)
        .padding({ left: 16 })
        .margin({ bottom: 8.5 })
      List({ space: 12 }) {
        ForEach(this.tutorialList, (item: ArticleClass) => {
          ListItem() {
            TutorialItem({ tutorialItem: item })
              .onClick(() => {
                this.articlePathStack.pushPathByName('articleDetail', item)
              })
          }
        }, (item: ArticleClass) => item.id)
      }
      //该属性有两个参数。第一个参数为纵轴方向的列数，第二个参数为列间距。此处根据设计图，需要分别在sm、md、lg断点下使得lanes属性的第一个参数分别为1、2、3，第二个参数分别为0、12、16。
      .lanes(
        new BreakpointType<number>({ sm: 1, md: 2, lg: 3 }).getValue(this.currentBreakpoint),
        new BreakpointType<number>({ sm: 0, md: 12, lg: 16 }).getValue(this.currentBreakpoint)
      )

      .scrollBar(BarState.Off)
      .padding({ left: 16, right: 16 })
    }
    .margin({ top: 18 })
    .alignItems(HorizontalAlign.Start)
  }
}