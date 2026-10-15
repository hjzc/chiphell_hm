import { env } from '../Storage/ZjEnv';
import { common } from '@kit.AbilityKit';
import { logger } from 'utils';
import { BusinessError } from '@kit.BasicServicesKit';
import { Any } from 'dialog';
import { HdsNavigation,HdsNavigationAttribute } from '@kit.UIDesignKit';
import data from '@ohos.telephony.data';
import { Constants } from '../common/Constants';

@Entry
@ComponentV2
struct SiteManagerPage {
  @Provider('navPageStack') navPageStack: NavPathStack = new NavPathStack();
  @Local statusBarHeight: number = env.statusBarHeight;
  @Local bottomRectHeight: number = env.bottomRectHeight;

  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private uiContext: UIContext = this.getUIContext();
  private controller = new TextInputController();
  @Local currentSearchContent: string = '';


  aboutToAppear() {

  }

  aboutToDisappear() {

  }
  @Builder
  HeaderSearch() {
    Row() {
      Stack() {
        // Search({
        //   placeholder: '请输入关键词',
        //   controller: this.searchController
        // })
        //   .onSubmit((value: string) => { // 点击键盘"搜索"键触发
        //     // 执行搜索逻辑
        //     console.log(`搜索内容: ${value}`);
        //   })
        //   .onChange((value: string) => { // 输入内容变化时触发
        //     this.searchText = value;
        //   })

        // 搜索框组件
        TextInput({ placeholder: $r('app.string.search_placeholder'), controller: this.controller })
          .width(Constants.FULL_PERCENT)
          .height($r('app.integer.height_forty'))
          .backgroundColor($r('app.color.search_background_color'))
          .borderStyle(BorderStyle.Solid)
          .borderColor($r('app.color.search_border_color'))
          .placeholderColor($r('app.color.search_placeholder_color'))
          .padding({
            left: $r('app.integer.search_content_padding_left'),
            right: $r('app.integer.search_content_padding_right')
          })
          .onEditChange((data) => {

          })
          .onSubmit((enterKey: EnterKeyType, event: SubmitEvent) => {

          })
          .onChange((value: string, previewText?: PreviewText, options?: TextChangeOptions) => {

          })

        Row() {
          Image($r('app.media.ic_search'))
            .width($r('app.integer.width_sixteen'))
            .height($r('app.integer.width_sixteen'))
          Button($r('app.string.search'))
            .width($r('app.integer.search_button_width'))
            .height($r('app.integer.search_button_height'))
            .fontColor($r('app.color.font_red'))
            .fontSize($r('app.integer.font_size_16'))
            .backgroundColor($r('app.color.search_background_color'))
            .onClick(() => {
              if (this.currentSearchContent.length !== Constants.ZERO_LENGTH) {
                //this.showLinkWord = false;
                //this.dealHistoryData(new HistoryWordModel(this.currentSearchContent), false);
                this.currentSearchContent = '';
              }
            });
        }.width(Constants.FULL_PERCENT)
        .hitTestBehavior(HitTestMode.None)
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({
          left: $r('app.integer.padding_ten'),
          right: $r('app.integer.padding_two')
        });
      }
      .width(Constants.FULL_PERCENT)
      .padding(10)
      .backgroundColor(Color.White)
    }

   // .backgroundColor('#F5F5F5')
  }

  build() {
    HdsNavigation(this.navPageStack) {
        // 页面内容
    }
    .titleBar({
      content: {
        stackBuilder: () => this.HeaderSearch(), // 在标题栏上层区域添加
        title: { mainTitle: '我的站点' },
      }
    })
    .backgroundColor($r('sys.color.background_primary'))
    .margin({ top: this.uiContext ? this.uiContext.px2vp(this.statusBarHeight) : 0 ,bottom: this.uiContext.px2vp(this.bottomRectHeight) })
  }


  private  navPushPathByName(name:string, param:Any, result?:(name:string,popInfo:PopInfo)=>void ){
    try{
      this.navPageStack.pushPathByName(name, param, (popInfo:PopInfo)=>{
       // this.onPageReShow();
       // if(result){
          //result(name,popInfo);
       // }
        //this.message = `[pushPath]last page is: ${popInfo.info.name} result: ${JSON.stringify(popInfo.result)}`
      },
      );
    }catch(error){
      logger.error(`PushByName:${name}, ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
    }
  }

  private  gotoAppSettingsPage():void{
    this.navPushPathByName('AppSettingsPage',null);
  }

}