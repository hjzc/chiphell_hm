import { BannerClass } from "../model/BannerClass";
import { bufferToString } from "../util/BufferUtil";
import { BreakpointType, BreakpointTypeEnum } from 'utils';

@Component
export  struct Banner{
  @Consume('articlePathStack') articlePathStack: NavPathStack;
  @State bannerList: Array<BannerClass> = [];

  @StorageProp('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.MD;

  getBannerDataFromJSON(){
    this.getUIContext().getHostContext()?.resourceManager.getRawFileContent('BannerData.json').then(value=>{
        let res:string = bufferToString(value);
        this.bannerList = JSON.parse(res) as BannerClass[];
    });
  }

  aboutToAppear(): void {
    this.getBannerDataFromJSON();
  }

  clickToDetailPage(item: BannerClass) {
    this.articlePathStack.pushPathByName('bannerDetailPage', item);
  }

  build() {
    Swiper() {
      ForEach(this.bannerList, (item: BannerClass, index: number) => {
        Image($r( item.imageSrc))
          .objectFit(ImageFit.Contain)
          .width('100%')
          .padding({ top: 11, left: 16, right: 16 })
          .borderRadius(16)
          .onClick(() => {
            this.clickToDetailPage(item)
          })
      }, (item: BannerClass, index: number) => item.id)
    }
    .autoPlay(true)
    .loop(true)

    .displayCount(new BreakpointType({ sm: 1, md: 2, lg: 2 }).getValue(this.currentBreakpoint))
    .displayMode(SwiperDisplayMode.STRETCH)
    .indicator(this.currentBreakpoint === BreakpointTypeEnum.SM ?
      Indicator.dot().
      color('#1a000000').
      selectedColor('#0A59F7') :
      false)
    .nextMargin(new BreakpointType<Length>({ sm: 0, md: 12, lg: 266 }).getValue(this.currentBreakpoint))

    // .indicator(
    //   new DotIndicator()
    //     .color('#1a000000')
    //     .selectedColor('#0A59F7'))
  }
}
