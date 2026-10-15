
import { common } from '@kit.AbilityKit';
import { env } from '../Storage/ZjEnv';
import { ZzjWeb } from '../web/Zzj/ZzjWeb';
import { SimpleWebClient } from '../web/SimpleWebClient';
import { ZzjWebOptions } from '../web/Zzj/ZzjWebOptions';
import { webview } from '@kit.ArkWeb';
import { SimpleWebJsObject } from '../web/SimpleWebJsObject';
import { logger } from 'utils';

@ComponentV2
export struct SimpleWebPage {
  @Consumer('navPageStack') navPageStack: NavPathStack = new NavPathStack();
  @Local statusBarHeight: number = env.statusBarHeight;
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private uiContext: UIContext = this.getUIContext();

  //初始化 同步一次
  @Require @Param webUrl:ResourceStr = '';

  @Local controller: webview.WebviewController = new webview.WebviewController();
  @Local options: ZzjWebOptions = new ZzjWebOptions(); //必选，Web参数
  @Local webClient: SimpleWebClient = new SimpleWebClient(); //可选，Web事件
  @Local jsObject: SimpleWebJsObject = new SimpleWebJsObject(); //可选，JS交互

  aboutToAppear(): void {
    this.uiContext = this.getUIContext();
    this.jsObject.onEvent = (event:number,param: string | undefined | null)=>{
      this.handleJsEvent(event,param);
    };
    this.webClient.onEvent = (event:number,param: string | undefined | null|OnSslErrorEventReceiveEvent)=>{
      this.handleClientEvent(event,param);
    };
  }

  private handleClientEvent(event:number,param: string | undefined | null|OnSslErrorEventReceiveEvent):void{
    if(event==-999){
      //ssl error 执行js 把错误信息传到web页面
      this.jsObject.onHandleWebClientEvent(event,param);
    }
  }

  private handleJsEvent(event:number,param: string | undefined | null):void
  {
     //ssl 错误
    let r:boolean =  this.webClient.sslErrorHandle(event,false);
    if(event==0){

    }else if(event==1){
      //back
      if(!r){
        this.navPageStack.pop(true);
      }
    }else if(event==2){
      //cancel
    }else if(event==3){
      //continue
      if(r){
        try {
          this.controller?.loadUrl(this.webClient.sslUrl);
        } catch (error) {
          // TODO: Implement error handling.
        }
      }

    }else if(event==4){
      //allow
      if(r){
        try {
          this.controller?.loadUrl(this.webClient.sslUrl);
        } catch (error) {
          // TODO: Implement error handling.
        }
      }
    }
    logger.debug('handle_js_event:'+event);
  }

  aboutToDisappear() {
    this.jsObject.onEvent=undefined;
    this.webClient.onEvent=undefined;
  }

  build() {
    NavDestination() {
      Column() {
        Progress({ value: this.webClient.progress,total:100, type: ProgressType.Linear })
          .width('100%')
          .height(2)
          .visibility( ((this.webClient.progress >=0) && (this.webClient.progress < 100)) ? (this.webClient.isFullScreen?Visibility.Hidden: Visibility.Visible) : Visibility.Hidden)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])

        ZzjWeb({
          controller: this.controller,
          src: this.webUrl,
          options: this.options,
          webClient: this.webClient,
          arkJsObject: this.jsObject,
          downloader:undefined
        })
          .layoutWeight(2)
      }
      .width('100%')
      // .margin({
      //   top:  ( this.isLandscape || this.webClient.isFullScreen)?0 :(this.uiContext.px2vp(this.statusBarHeight ) ),
      //   bottom:0
      //   // bottom: (this.uiContext ? this.uiContext.px2vp(this.statusBarHeight) : 0)
      //
      // }) // 顶部避让
    }

    .title($r('app.string.set_terms_of_service'))
    .backgroundColor($r('sys.color.background_primary'))
    .margin({ top: this.uiContext ? this.uiContext.px2vp(this.statusBarHeight) : 0 ,bottom:0 }) // 顶部避让
    .onBackPressed(()=>{
      return false;
    });
  }
}
