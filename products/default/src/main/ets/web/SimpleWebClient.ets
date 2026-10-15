import { AppUtil } from "../utils/AppUtil";
import { DelayTasks } from "../utils/DelayTasks";
import { ZzjWebClient } from "./Zzj/ZzjWebClient";
import { webview } from "@kit.ArkWeb";
import { common } from "@kit.AbilityKit";
import { BusinessError } from '@kit.BasicServicesKit';
import { logger } from "utils";
import { StrUtil } from "../utils/StrUtil";

/**
 * 加载简单网页
 */
@ObservedV2
export class SimpleWebClient implements ZzjWebClient {
  @Trace progress: number = 1;
  @Trace isFullScreen: boolean = false;
  private isLoadErrorPage: boolean = false;

  sslErrorEvent?: OnSslErrorEventReceiveEvent = undefined;
  sslHandleResult:number = -1;
  sslUrl? :string;

  controller?: webview.WebviewController;

  onEvent?:(event:number,param: string | undefined | null |OnSslErrorEventReceiveEvent ) =>void = (event:number,param: string | undefined | null|OnSslErrorEventReceiveEvent )=>{

  };

  constructor() {

  }

  getContext(): common.UIAbilityContext {
    return AppUtil.getContext();
  }



  setWebviewController(controller: webview.WebviewController): void {
    this.controller = controller;
  }


  onFullScreenEnter(event: FullScreenEnterEvent): void{
    this.isFullScreen = true;
  }

  /**
   * 通知开发者Web组件退出全屏模式。
   */
  onFullScreenExit(): void
  {
    this.isFullScreen = false;
  }
  onProgressChange(event:OnProgressChangeEvent) :void {
    if (event.newProgress !== this.progress) {
      this.progress = event.newProgress;
      if (event.newProgress == 100) {
        DelayTasks.addDelayRun("initDataLoading",1000,()=>{
          if(this.progress==100){
            this.progress =-1;
          }
        });
      }
    }
  }
  onErrorReceive?(event: OnErrorReceiveEvent): void{
  //  if (event && event.request.isMainFrame()) {
      logger.error(`onHttpErrorReceive:${event.error.getErrorInfo()}`);
      // try {
      //   // 加载自定义错误页面
      //   this.controller?.stop();
      //   //this.controller.loadUrl($rawfile('custom_failure_page.html'));
      // } catch (error) {
      //   logger.error(`ErrorCode: ${(error as BusinessError).code}, Message: ${(error as BusinessError).message}`);
      // }
   // }
  }

  /**
   * 网页加载资源遇到的HTTP错误（响应码>=400)时触发该回调。
   */
  onHttpErrorReceive?(event: OnHttpErrorReceiveEvent): void{
    // Only handle loading errors of the main framework to avoid duplicate processing of errors in sub-resources
    logger.error(`onHttpErrorReceive:${event.request.getRequestUrl()}`);
  }



  sslErrorHandle(handle:number, innerHandle:boolean) :boolean {

    let r: boolean = false;
    if(this.sslErrorEvent!=undefined) {
      if (handle == 0) {

      } else if (handle == 1) {
        //back
        this.sslErrorEvent?.handler.handleCancel();
        this.sslHandleResult = 1;
        if(innerHandle){
          r = true;
        }
        else{
          if(this.controller?.accessBackward()) {
            this.controller?.backward();
            r = true;
          }
        }
      } else if (handle == 2) {
        //cancel
        // this.sslErrorEvent?.handler.handleCancel();
        //abortLoading-如果aboutLoading为true，则当前请求将被取消，用户将留在当前页面上。如果为false，则不会忽略SSL错误，并显示空白页。
        //如果启用了默认错误页面，则将显示默认错误页面。默认值为false。
        this.sslErrorEvent?.handler.handleCancel(true);
        this.sslHandleResult = 2;
        r = true;
      } else if (handle == 3) {
        //continue
        this.sslErrorEvent?.handler.handleConfirm();
        this.sslHandleResult = 3;
        r = true;

      } else if (handle == 4) {
        //强制绕过
        this.sslErrorEvent?.handler.handleConfirm();
        this.sslHandleResult = 4;
        r = true;

      }
    }
    return r;
  }

  /**
   * 通知用户加载资源时发生SSL错误，只支持主资源。（如果需要支持子资源，请使用OnSslErrorEvent接口）
   * */
  onSslErrorEventReceive?(event: OnSslErrorEventReceiveEvent): void{
    // if (event) {
    //   logger.error(`SSL Error Code: ${event.error}, Reason: ${getSslErrorReason(event.error)}`);
    //   this.sslErrorEvent = event;
    //
    //   if(this.sslErrorHandle(this.sslHandleResult,true)){
    //     this.sslErrorEvent = undefined;
    //   }else{
    //     try {
    //       this.sslErrorEvent = event;
    //       this.sslUrl = this.controller?.getUrl()??this.controller?.getOriginalUrl();
    //       //event.handler.handleCancel(false);
    //       StrUtil.rawUtf8FileToString(this.getContext(),'ssl_error_page_local.html',
    //         (context, content) =>{
    //          // 必须制定 "resource://rawfile/"
    //
    //           if(content!=null){
    //             // 替换  SSL_ERROR_URL 成当前url,
    //             let htmlStr :string = StrUtil.replaceAll(content,'SSL_ERROR_URL',this.sslUrl);
    //             //SSL_ERROR_CODE_VALUE getSslErrorCode
    //             htmlStr = StrUtil.replaceAll(htmlStr,'SSL_ERROR_CODE_VALUE',''+event.error);
    //             //SSL_ERROR_CODE_STRING getSslErrorCode
    //             htmlStr = StrUtil.replaceAll(htmlStr,'SSL_ERROR_CODE_STRING',getSslErrorCode(event.error));
    //             //SSL_ERROR_CODE_DESC getSslErrorReason
    //             htmlStr = StrUtil.replaceAll(htmlStr,'SSL_ERROR_CODE_DESC',getSslErrorReason(event.error));
    //
    //             this.controller?.loadData(htmlStr,'text/html','UTF-8',"resource://rawfile/");
    //           }else{
    //             this.sslErrorEvent = undefined;
    //             event.handler.handleCancel(true);
    //             this.sslUrl = undefined;
    //           }
    //       });
    //      // this.controller?.loadUrl($rawfile('ssl_error_page_local.html'));
    //     } catch (error) {
    //       // TODO: Implement error handling.
    //       this.sslErrorEvent = undefined;
    //       event.handler.handleCancel(true);
    //       this.sslUrl = undefined;
    //     }
    //   }
    // }
    event.handler.handleConfirm();
  }

  /**
   * 通知用户加载资源（主资源+子资源）时发生SSL错误，如果只想处理主资源的SSL错误，请用isMainFrame字段进行区分。
   */
  onSslErrorEvent?(event: SslErrorEvent): void{
   event.handler.handleConfirm();
    // if (event.isMainFrame) {
    //   event.handler.handleConfirm();
    // }else{
    //   event.handler.handleCancel(false);
    // }
  }

  onPageEnd(event: OnPageEndEvent): void {
    if(this.sslErrorEvent){
      if(this.onEvent){
        this.onEvent(-999,this.sslErrorEvent);
      }
    }
  }
}

function getSslErrorReason(code: number): string {
  switch (code) {
    case 0: return "网站证书已过期或未生效";
    case 1: return "证书与网站域名不匹配";
    case 2: return "证书未被信任的机构颁发";
    case 3: return "网络连接可能被拦截或篡改";
    default: return "未知错误";
  }
}
function getSslErrorCode(code: number): string {
  switch (code) {
    case 0: return "SSL_ERROR_INVALID";
    case 1: return "SSL_ERROR_HOST_MISMATCH";
    case 2: return "SSL_ERROR_DATE_INVALID";
    case 3: return "SSL_ERROR_UNTRUSTED";
    default: return "SSL_ERROR_INVALID";
  }
}