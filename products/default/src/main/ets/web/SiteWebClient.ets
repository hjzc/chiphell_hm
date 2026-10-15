import { ZzjWebClient } from "./Zzj/ZzjWebClient";
import { webview } from "@kit.ArkWeb";
import { logger } from "utils";
import { ZzjWebHelper } from "./Zzj/ZzjWebHelper";
import { WebSite } from "../model/WebSite";
import { env } from "../Storage/ZjEnv";
import { StrUtil } from "../utils/StrUtil";
import { Any } from "../utils/UtilConstraint";
import { BusinessError } from '@kit.BasicServicesKit';
import { RegexUtil } from "../utils/RegexUtil";
import { WantUtil } from "../utils/WantUtil";
import { bundleManager, common, Want } from "@kit.AbilityKit";
import { DelayTasks } from "../utils/DelayTasks";
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { AppUtil } from "../utils/AppUtil";
import {  getDBManager } from "../common/DBManager";
import { WebRecord } from "../model/WebRecord";
import { ZjStorage } from "../Storage/ZjStorage";
import { ToastUtil } from "../utils/ToastUtil";
import { PicturePreviewDataModel } from "imagegallery/src/main/ets/model/PicturePreviewDataModel";
import { call } from "@kit.TelephonyKit";
import { deviceInfo } from '@kit.BasicServicesKit';

@ObservedV2
export class SiteWebClient implements ZzjWebClient {
  @Trace progress:number = 1;
  @Trace imageCount:number = 0;
  @Trace imageIndexToken:number = -1;
  @Trace isFullScreen :boolean = false;
  private storage: ZjStorage;
  private isLoadErrorPage :boolean=false;

  imageIndex:number = 0;
  backToUrl :string | undefined;

  private  images: string[] = [];
  controller?: webview.WebviewController;
  private site:WebSite;
  constructor(site: WebSite,storage: ZjStorage ){
      this.site =site;
      this.storage = storage;
  }

  getContext(): common.UIAbilityContext {
    return AppUtil.getContext();
  }

  getImageUrlList():string[]{
    return Array.from(this.images);
  }

  setWebviewController(controller: webview.WebviewController): void {
    this.controller = controller;
  }
  // private onProgressChangedCallback?: Callback<number> = undefined;
  // setOnProgressChangedCallback(onProgressChangedCallback: Callback<number>) {
  //   this.onProgressChangedCallback = onProgressChangedCallback;
  // }

  // private onPageBeginCallback?: Callback<OnPageBeginEvent>;
  // setOnPageBegin(onPageBeginCallback: Callback<OnPageBeginEvent>) {
  //   this.onPageBeginCallback = onPageBeginCallback;
  // }
  private  setWebCustomUserAgent():void{
    try {
      let ua:string = this.site.getUserAgent();
      this.controller?.setCustomUserAgent(ua);
      PicturePreviewDataModel.requestUserAgent = ua;
      this.logInfo('set web user agent:',ua);
      //Mozilla/5.0 (Phone; OpenHarmony 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36  ArkWeb/6.0.0.47 Mobile
      //AppStorage.setOrCreate('useragent',ua);
    } catch (error) {
      this.logError('setWebCustomUserAgent:',error);
    }
  }

  switchUserAgent():boolean{
    let result:boolean = false;
    let reloadUrl:string = StrUtil.isNotEmpty(this.site.stopUrl)?this.site.stopUrl:(StrUtil.isNotEmpty(this.site.startUrl)?this.site.startUrl:'') ;

    if(this.controller!=null){
      try {
        let url:string = this.controller?.getUrl();
        if(url.length>0){
          reloadUrl =url;
        }
      } catch (error) {
        this.logError('switchUserAgent get url:',error);
      }
      if( StrUtil.isNotEmpty(reloadUrl)){
         reloadUrl=this.site.convertUrl(reloadUrl,this.site.isUseMobile()?false:true);
        try {
          this.site.toggleMobileOrPc();
          this.setWebCustomUserAgent();
          this.controller?.loadUrl(reloadUrl);
          result = true;
        } catch (error) {
          this.logError('switchUserAgent load url:',error);
        }
      }
    }
    return result;
  }

  backwardToNoThread():boolean{
    let result :boolean = false;
    if (this.controller!=null) {
      try {
        let list:webview.BackForwardList = this.controller?.getBackForwardEntries();
        let currentIndex:number = list.currentIndex;
        let i = currentIndex-1;
        let step = 0;
        while (i>=0) {
          let item: webview.HistoryItem=list.getItemAtIndex(i);
          if (this.site.isThreadUrl(item.historyUrl)) {
            i--;
          }else{
            step =  currentIndex - i;
            this.controller?.backOrForward(step);
            result =true;
            break;
          }
        }
      } catch (error) {
        this.logError('backwardToNoThread:',error);
      }
    }

    if (!result && (this.backToUrl != undefined) && (this.backToUrl.length>0) && ( this.backToUrl!= this.site.startUrl && this.backToUrl!= this.site.stopUrl ) ) {
      try {
        this.controller?.loadUrl(this.backToUrl);
        result = true;
      } catch (error) {
        this.logError('switchUserAgent load url:',error);
      }
    }
    return result;
  }

  backward():boolean{
    let result:boolean =false;
    if(this.controller!=null){
      try {
        let hasFlag = this.controller?.accessBackward();
        if (hasFlag) {
          this.controller?.backward();
          result = true;
        }
      } catch (error) {
        this.logError('backward:',error);
      }
    }
    return result;
  }

  goRefresh():boolean{
    let result:boolean =false;
    if(this.controller!=null){
      try {
        if( (this.progress >0) && (this.progress < 100) ){
          this.controller?.stop();
        }
        if (this.isLoadErrorPage) {
          this.isLoadErrorPage =false;
          this.controller?.loadUrl(this.site.startUrl);
        }
        else{
          this.controller?.refresh();
        }
        result = true;
      } catch (error) {
        this.logError('goRefresh:',error);
      }
    }
    return result;
  }

  gotoHome():boolean{
    let result:boolean =false;
    if(this.controller!=null){
      try {
        let list:webview.BackForwardList = this.controller?.getBackForwardEntries();
        let currentIndex:number = list.currentIndex;
        let i = currentIndex;
        let step = 0;
        while (i>=0) {
          let item: webview.HistoryItem=list.getItemAtIndex(i);
          if (this.site.isHomeUrl(item.historyUrl)) {
            step = i - currentIndex;
            if(step !=0){
              this.controller?.backOrForward(step);
            }
            result =true;
            break;
          }else{
            i--;
          }
        }
      } catch (error) {
        this.logError('gotoHome:',error);
      }
      if (!result) {
        //手动刷新
        let homeUrl:string = this.site.homeUrl();
        try {
          this.controller.loadUrl(homeUrl);
          result = true;
        } catch (error) {
          this.logError('gotoHome load url:',error);
        }
      }
    }
    return result;
  }
  gotoForum():boolean{
    let result:boolean =false;
    if(this.controller!=null){
      try {
        let list:webview.BackForwardList = this.controller?.getBackForwardEntries();
        let currentIndex:number = list.currentIndex;
        let i = currentIndex;
        let step = 0;
        while (i>=0) {
          let item: webview.HistoryItem=list.getItemAtIndex(i);
          if (this.site.isForumMainUrl(item.historyUrl)) {
            step = i - currentIndex;
            if(step !=0){
              this.controller?.backOrForward(step);
            }
            result =true;
            break;
          }else{
            i--;
          }
        }
      } catch (error) {
        this.logError('gotoForum:',error);
      }
      if (!result) {
        //手动刷新
        let forumUrl:string = this.site.forumUrl();
        try {
          this.controller.loadUrl(forumUrl);
          result = true;
        } catch (error) {
          this.logError('gotoForum load url:',error);
        }
      }
    }
    return result;
  }
  gotoLogin():boolean{
    let result:boolean =false;
    if(this.controller!=null){
      //手动刷新
      let url:string = this.site.loginUrl();
      try {
        this.controller.loadUrl(url);
        result = true;
      } catch (error) {
        this.logError('gotoLogin load url:',error);
      }
    }
    return result;
  }

  gotoOtherBrowser():void{
    WantUtil.toWebBrowser(this.site.startUrl,true);
  }

  onControllerAttached(): void {
    try {
      if(this.site.getDefaultUA().length<10){
        let userAgent = this.controller?.getUserAgent();
        if (userAgent!=null) {
          env.defaultUserAgent  =userAgent;
          this.site.setDefaultUA(userAgent);
          PicturePreviewDataModel.requestUserAgent = userAgent;
          this.logInfo('get web default user agent:',userAgent);
          // AppStorage.setOrCreate('useragent',this.site.defaultUA);
        }
      }

      if(this.site.getUserAgent() !== this.site.getDefaultUA()){
        this.setWebCustomUserAgent();
      }
      if ( PicturePreviewDataModel.requestUserAgent==null) {
        PicturePreviewDataModel.requestUserAgent = this.site.getUserAgent();
        this.logInfo('get web default user agent1:',PicturePreviewDataModel.requestUserAgent);
      }
      // if ( PicturePreviewDataModel.getInstance().requestHost==null) {
      //   PicturePreviewDataModel.getInstance().requestHost = this.site.siteHost();
      // }

    } catch (error) {
      this.logError('onControllerAttached set user agent:',error);
    }

    try {
      ZzjWebHelper.setBFCacheOptionsToController(this.controller!);
    } catch (error) {
      this.logError('onControllerAttached:',error);
    }


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

  onLoadIntercept(event: OnLoadInterceptEvent): boolean{
    if (event) {
      console.info('onLoadIntercept url:' + event.data.getRequestUrl())
      console.info('url:' + event.data.getRequestUrl())
      console.info('isMainFrame:' + event.data.isMainFrame())
      console.info('isRedirect:' + event.data.isRedirect())
      console.info('isRequestGesture:' + event.data.isRequestGesture())

      let url: string = event.data.getRequestUrl();
      // 判断链接是否为拨号链接
      if (url.indexOf('tel://') === 0) {
        // 跳转拨号界面
        if(deviceInfo.deviceType !== '2in1' ) {
          call.makeCall(url.substring(6), (err) => {
            if (!err) {
              logger.info('make call succeeded.');
            } else {
              logger.info('make call fail, err is:' + JSON.stringify(err));
            }
          });
          return true;
        }
      }
    }
    // 返回true表示阻止此次加载，否则允许此次加载
    return false;
  }

  canLaunchUrl(link:string):boolean{
    let rc =false;
    try {
      let data = bundleManager.canOpenLink(link);
      logger.info('canOpenLink successfully: ', JSON.stringify(data));
    } catch (error) {
      this.logError('canOpenLink failed:',error);
    }
    return rc;
  }

  getUIContext():UIContext
  {
    const uiContext :UIContext= AppStorage.get('UIContext') as UIContext;
    return  uiContext;
  }
  getAbilityContext():common.UIAbilityContext
  {
    const CONTEXT =this.getUIContext().getHostContext() as common.UIAbilityContext;
    return  CONTEXT;
  }

  launchUrl(url:string):void{
    const WANT: Want = {
      uri: url
    }
    this.getAbilityContext().startAbility(WANT).then(() => {
      // 拉起成功
      logger.debug('launchUrl success: ', url);
    }).catch((err:Any) => {

      let message = (err as BusinessError).message;
      logger.error('canOpenLink failed: ', message);

      const prompt = this.getUIContext().getPromptAction();
      prompt.showDialog({
        title: $r('app.string.tips'),
        message: $r('app.string.fail'),
        buttons: [{
          text: $r('app.string.confirm'),
          color: '#FF0000',
        }]
      })
    })
  }

  appDownload(url:string):void{
    const prompt = this.getUIContext().getPromptAction();
    prompt.showDialog({
      title: $r('app.string.tips'),
      message: $r('app.string.download'),
      buttons: [{
        text: $r('app.string.confirm'),
        color: '#FF0000',
      }]
    })
    .then(index => {
      const WANT: Want = {
        uri: `store://appgallery.huawei.com/app/detail?id=com.huawei.hmos.tips`
      }
      this.getAbilityContext().startAbility(WANT).catch(() => {
        // TODO: Implement error handling.
        const prompt = this.getUIContext().getPromptAction();
        prompt.showDialog({
          title: $r('app.string.tips'),
          message: $r('app.string.fail'),
          buttons: [{
            text: $r('app.string.confirm'),
            color: '#FF0000',
          }]
        })
      }).then(() => {
          ////拉起成功
        logger.debug('launchUrl appgallery success: ', url);
      })
    })
  }

  onOverrideUrlLoading(request: WebResourceRequest): boolean{
    let rc = false;
    if (request ) {
      let isMainFrame:Boolean =  request.isMainFrame();
      let url:string = request.getRequestUrl();
      if (  url== "about:blank" ) {
        if(isMainFrame) {
          //不加载空白页
          rc = true;
        }
      }else if ((!url.startsWith('https://turing.captcha.gtimg.com', 0)) &&
        (!url.startsWith('https://player.bilibili.com',0 )) &&
        (!url.startsWith('https://www.bilibili.com/blackboard',0)) &&
        (!this.site.isSite(url)))
      {
        if (isMainFrame && !url.startsWith("about:blank")) {
          //弹窗用其他app打开
          WantUtil.toWebBrowser(url,true);
        }
        rc = true;
      }else{
        let scheme = RegexUtil.urlScheme(url);
        if (scheme==null) {
          rc = true;
        }else{
          if ([ "http",
            "https",
            "file",
            "chrome",
            "data",
            "javascript",
            "about",
          ].indexOf(scheme) < 0)
          {
            //其他应用打开
            if(this.canLaunchUrl(url)){
              this.launchUrl(url);
            }else{
              this.appDownload(url);
            }
            rc = true;
          }
        }
      }
    }else{
      rc = true;
    }
    return rc;
  }

  /**
   * 当Web组件加载url之前触发该回调，用于拦截url并返回响应数据。
   * 返回值WebResourceResponse。返回响应数据则按照响应数据加载，无响应数据则返回null表示按照原来的方式加载。
   */
  onInterceptRequest(event: OnInterceptRequestEvent): WebResourceResponse | null{
    //   headerKey: "Connection",
    //   headerValue: "keep-alive"
    // }
    // let head2: Header = {
    //   headerKey: "Cache-Control",
    //   headerValue: "no-cache"
    // }
    // // 将新元素追加到数组的末尾，并返回数组的新长度。
    //
    // responseWeb: WebResourceResponse = new WebResourceResponse();
    // heads: Header[] = new Array();
    //
    // let length = this.heads.push(head1);
    // length = this.heads.push(head2);
    // console.info('The response header result length is :' + length);
    // this.responseWeb.setResponseHeader(this.heads);
    // this.responseWeb.setResponseData(this.webData);
    // this.responseWeb.setResponseEncoding('utf-8');
    // this.responseWeb.setResponseMimeType('text/html');
    // this.responseWeb.setResponseCode(200);
    // this.responseWeb.setReasonMessage('OK');
    // // 返回响应数据则按照响应数据加载，无响应数据则返回null表示按照原来的方式加载
    // return this.responseWeb;
    return null;
  }

  onPageBegin(event: OnPageBeginEvent): void {
    //this.onPageBeginCallback?.(event);
    let url =event.url;
    if (!url) {
      return;
    }
    if (!url.toLowerCase().startsWith('http',0)) {
      return
    }
    if(this.site.startUrl !== event.url){
      this.site.startUrl = event.url;
      this.imageCount = 0 ;
      this.images = [];
      this.imageIndex = 0;
    }
  }

  async  asyncHandleSiteCookie(): Promise<void>{
    // try {
    //   webview.WebCookieManager.fetchCookie(this.site.siteUrl(), (error, cookie) => {
    //     if (error) {
    //       console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
    //       return;
    //     }
    //     if (cookie) {
    //       //v2x4_48dd_saltkey=eEQE7BO1; v2x4_48dd_lastvisit=1761451586; v2x4_48dd_sid=geIoDH; v2x4_48dd_sendmail=1; v2x4_48dd_lastact=1761455763%09index.php%09
    //       logger.debug("fetchCookie cookie = " ,cookie);
    //     }
    //   })
    // } catch (error) {
    //   console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
    // }
    try {
      webview.WebCookieManager.fetchCookie(this.site.siteUrl(),false)
        .then(cookie => {
          //v2x4_48dd_auth	""
          PicturePreviewDataModel.getInstance().requestCookie = cookie;
          if( (cookie!==undefined) && (cookie.includes('v2x4_48dd_auth'))){
            env.login = true;
          }
          else{
            logger.debug("fetchCookie cookie = " ,cookie);
          }
        })
        .catch((error: BusinessError) => {
          this.logError('fetchCookie catch: ',error);

        })
    } catch (error) {
      this.logError('fetchCookie errorCode: ',error);
    }
  }

  onPageEnd?(event: OnPageEndEvent): void{
    let url =event.url;
    if (!url) {
      return;
    }
    if (!url.toLowerCase().startsWith('http',0)) {
      return
    }
    this.site.stopUrl = event.url;
    this.site.lastUrl = event.url;
    PicturePreviewDataModel.getInstance().requestReferer = event.url;

    this.handleFilter();
    this.asyncHandleSiteCookie();
    this.saveToRecord(this.site.lastUrl,this.site.title);
  }

  handleFilter(){
    if(!this.controller){
      return
    }
    //webinterfaceFilterChanged('["mucheng","dddd","rdddd","要"]') ["reew","3222","vvvvvv","gg","dddddd","mucheng","vcvv"]
    if (this.storage.filterList.length <= 0) {
      return;
    }
    if(!this.site.isThreadUrl(this.site.lastUrl)){
      return;
    }
    const jsonString: string = JSON.stringify(this.storage.filterList);
    this.runJavaScriptFun('webinterfaceFilterChanged',jsonString);
  }

   saveToFavorites(){
     this.saveToRecord(this.site.lastUrl,this.site.title,true);
  }

  //手动调用是否收藏
  private  saveToRecord(url:string,title:string,favor:boolean = false){
    if (url.length <=0) {
      return;
    }
    getDBManager().queryRecord(this.getContext(),url).then((value)=>{
      if( value && ( value!==undefined)){
        if(favor){
          if(value.favor){
            return;
          }
          value.favor =1;
          value.favorDate = new Date().getTime();
        }
        else{
          value.access +=1;
          value.accessDate = new Date().getTime();
        }
        getDBManager().updateRecord(this.getContext(),value)
          .then((val)=>{
            if(favor){
              ToastUtil.showToast(this.getUIContext(),  $r( val?'app.string.do_success' : 'app.string.do_failed') );
            }
          });

      }else{
        let time =(new Date()).getTime();
        let record :WebRecord= {
          url:url,
          title: title??'',
          access: 1,
          accessDate: time,
          favor: favor?1:0,
          favorDate:favor?time:0,
          deleted: 0,
          updateDate: time,
          createDate: time,
        };
        getDBManager().insertRecord(this.getContext(),record)
          .then((val)=>{
            if(favor){
              ToastUtil.showToast(this.getUIContext(), $r( val?'app.string.do_success' : 'app.string.do_failed') );
            }

        });

      }
    })
  }

  //https://static.chiphell.com/forum/202510/20/135334znm9yjfapptknm9k.jpg
  //https://static.chiphell.com/portal/202510/20/090830m33qj5031pn5rnjz.png
  onResourceLoad(event: OnResourceLoadEvent): void{
      if(RegexUtil.isMatch(event.url, 'com/[forum|portal]+/[0-9]{6}/\\d{2}/[0-9|a-z]{20,}[.](jpg)') ||
      RegexUtil.isMatch(event.url, 'com/[forum|portal]+/[0-9]{6}/\\d{2}/[0-9|a-z]{20,}[.](png)')||
      RegexUtil.isMatch(event.url, 'com/[forum|portal]+/[0-9]{6}/\\d{2}/[0-9|a-z]{20,}[.](jpeg)') ||
      RegexUtil.isMatch(event.url, 'com/[forum|portal]+/[0-9]{6}/\\d{2}/[0-9|a-z]{20,}[.](webp)')||
      RegexUtil.isMatch(event.url, 'com/[forum|portal]+/[0-9]{6}/\\d{2}/[0-9|a-z]{20,}[.](gif)')
      ){
          if(this.images.includes(event.url)==false){
            this.images.push(event.url);
            this.imageCount +=1;
          }
      }
  }


  /**
   * https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-video-adaptation-based-web
   * 长按特定元素（例如图片，链接）或鼠标右键，跳出菜单。
   * 调用时触发的回调，以允许自定义显示上下文菜单。返回值boolean。自定义菜单返回true，触发的自定义菜单无效返回false。
   */
  onContextMenuShow(event: OnContextMenuShowEvent): boolean{
    if (event.param.getMediaType() === ContextMenuMediaType.Image) {
      let url = event.param.getSourceUrl();
      let index = this.images.indexOf(url);
      if (index>-1) {
          this.imageIndex = index;
          DelayTasks.addDelayRun("imageIndexToken",1500,()=>{
            this.imageIndexToken +=1;
          });
        return true; // 返回 true 表示阻止默认菜单
      }
    }
    return false; // 返回 false 显示默认菜单
  }

  onTitleReceive(event: OnTitleReceiveEvent): void{
     if(event.title !== undefined && (event.title.length>0) ) {
       this.site.title  = event.title;
     }
  }

  requestPermissions(arr: Array<string>) {
    let permissionList: Array<Permissions> = [];
    arr.forEach((it) => {
      if (it.toString() === 'TYPE_VIDEO_CAPTURE') {
        permissionList.push('ohos.permission.CAMERA')
        permissionList.push('ohos.permission.MICROPHONE')
      } else if (it.toString() === 'TYPE_AUDIO_CAPTURE') {
        permissionList.push('ohos.permission.MICROPHONE')
      }else if (it.toString() === 'TYPE_SENSOR') {
        permissionList.push('ohos.permission.ACCELEROMETER')
      }
    })
    if(permissionList.length ==0 ){
      return;
    }
    let atManager = abilityAccessCtrl.createAtManager();
    // getContext(this)
    atManager.requestPermissionsFromUser( this.getContext(), permissionList)
      .then((data) => {

        // if (err) {
        //   event.request.deny(); // 拒绝网页请求
        // } else {
        //   event.request.grant(resourceTypes); // 授权网页
        // }

        console.info('data permissions:' + data.permissions);
        console.info('data authResults:' + data.authResults);
      }).catch((error: BusinessError) => {
      console.error(`Failed to request permissions from user. Code is ${error.code}, message is ${error.message}`);
    })
  }

  onPermissionRequest(event: OnPermissionRequestEvent): void{
    if (event) {
      this.requestPermissions(event.request.getAccessibleResource())
      this.getUIContext().showAlertDialog({
        title:  $r('app.string.tips'),
        message:  $r('app.string.web_permission_message'),
        primaryButton: {
          value: $r('app.string.onDeny'),
          action: () => {
            event.request.deny();
          }
        },
        secondaryButton: {
          value: $r('app.string.onConfirm'),
          action: () => {
            event.request.grant(event.request.getAccessibleResource());
          }
        },
        cancel: () => {
          event.request.deny();
        }
      })
    }
  }


  /**
   * 网页加载遇到错误时触发该回调。主资源与子资源出错都会回调该接口，可以通过request.isMainFrame来判断是否是主资源报错。
   * 出于性能考虑，建议此回调中尽量执行简单逻辑。
   * 在无网络的情况下，触发此回调。
   */
  onErrorReceive(event: OnErrorReceiveEvent): void {
    //errorCode：-102 - errorMsg：ERR_CONNECTION_REFUSED
    if (event.error.getErrorCode() == -102) {
      logger.error('ERR_CONNECTION_REFUSED 网络错误');
      if (this.isLoadErrorPage) {
        return;
      }
      this.isLoadErrorPage = true;
      try {
        this.controller?.stop();
      } catch (error) {
        // TODO: Implement error handling.
      }
      this.load404Html(this.site.startUrl??'',event.error.getErrorInfo() );
    }else{
      this.isLoadErrorPage = false;
    }
  }

  load404Html(errorUrl:string,errorDes:string ):void{

    StrUtil.rawUtf8FileToString(this.getContext() as common.UIAbilityContext, '404.html', (context:common.UIAbilityContext,content:string|null)=> {
      if (content != null) {
        let htm:string = content.replace('$errorUrl',errorUrl);
        htm= htm.replace('$\{error.description}',errorDes);
        try {
          this.controller?.loadData(htm, 'text/html', 'UTF-8',errorUrl,errorUrl);
        } catch (error) {
          // TODO: Implement error handling.
        }
      }
    });

  }

  onConsole(event: OnConsoleEvent): boolean{
    let r:boolean =false;
    if (ZzjWebHelper.debug) {
      let msg  = event.message.getMessage();
      let lv  =  event.message.getMessageLevel();
      switch (lv){
        case MessageLevel.Debug:
          logger.debug ('WebLog:', msg);
          r =true;
          break;
        case MessageLevel.Info:
          logger.info ('WebLog', msg);
          r =true;
          break;
        case MessageLevel.Warn:
          logger.warn ('WebLog', msg);
          r =true;
          break;
        case MessageLevel.Error:
          logger.error ('WebLog', msg);
          r =true;
          break;
        case MessageLevel.Log:
          logger.info ('WebLog', msg);
          r =true;
          break;
      }
    }
    return r;
  }

  onFullScreenEnter(event: FullScreenEnterEvent): void{
    this.isFullScreen = true;
  }

  /**
   * 通知开发者Web组件退出全屏模式。
   */
  onFullScreenExit(): void {
    this.isFullScreen = false;
  }
  //自定义 证书访问，p12
  // onClientAuthenticationRequest?(event: OnClientAuthenticationEvent): void{
  //   console.info("onClientAuthenticationRequest ");
  //   //event.handler.confirm(this.uri);
  // }

  onSslErrorEventReceive?(event: OnSslErrorEventReceiveEvent): void{
    if (event.error) {
      // 跳过SSL证书验证
      event.handler.handleConfirm();
    }
  }

  onSslErrorEvent?(event: SslErrorEvent): void{
   // if (event.isMainFrame) {
    if (event.error) {
      // 跳过SSL证书验证
      event.handler.handleConfirm();
    }
    // }else{
    //   event.handler.handleCancel(false);
    // }
  }

  //文件选择
  onShowFileSelector(event: OnShowFileSelectorEvent): boolean {
    // const isCapture = event.fileSelector.isCapture(); //是否拍照/拍视频
    // if (isCapture) { //拍照/拍视频
    //   PickerUtil.cameraEasy().then((result) => {
    //     event.result.handleFileList([result]);
    //   });
    // } else {
    //   const types = event.fileSelector.getAcceptType() ?? [];
    //   const mode = event.fileSelector.getMode();
    //   const isPhoto = Utils.isPhoto(types);
    //   const isVideo = Utils.isVideo(types);
    //   if (isPhoto || isVideo) { //图片、视频
    //     let sheets = isPhoto ? ["拍照", "选择照片"] : ["拍视频", "选择视频"];
    //     DialogHelper.showActionSheetDialog({
    //       title: "请选择",
    //       sheets: sheets,
    //       onAction: (action) => {
    //         if (action === 0) {
    //           let options = new CameraOptions();
    //           options.mediaTypes = isPhoto ? [cameraPicker.PickerMediaType.PHOTO] : [cameraPicker.PickerMediaType.VIDEO];
    //           PickerUtil.cameraEasy(options).then((result) => {
    //             if (isPhoto) { //对拍照的图片进行压缩，压缩到3M以内
    //               ImageUtil.compressPhoto(result, 1024 * 3).then((path) => {
    //                 event.result.handleFileList([path]);
    //               }).catch((err: BusinessError) => {
    //                 event.result.handleFileList([result]); //图片压缩异常时，使用原图。
    //                 LogUtil.error(`拍照图片压缩异常：${err.code} - ${err.message}`);
    //               });
    //             } else {
    //               event.result.handleFileList([result]);
    //             }
    //           });
    //         } else {
    //           PickerUtil.selectDocument({
    //             maxSelectNumber: mode === FileSelectorMode.FileOpenMode ? 1 : 9,
    //             fileSuffixFilters: types
    //           }).then((result) => {
    //             event.result.handleFileList(result);
    //           })
    //         }
    //       }
    //     })
    //   } else { //文档
    //     PickerUtil.selectDocument({
    //       maxSelectNumber: mode === FileSelectorMode.FileOpenMode ? 1 : 9,
    //       fileSuffixFilters: types
    //     }).then((result) => {
    //       event.result.handleFileList(result);
    //     })
    //   }
    // }
    return true;
  }

  async runJavaScript(script: string): Promise<string> {
    if (this.controller) {
      return ZzjWebHelper.runJavaScript(this.controller, script);
    }
    return '';
  }


  async runJavaScriptExt(script: string | ArrayBuffer): Promise<webview.JsMessageExt> {
    if (this.controller) {
      return ZzjWebHelper.runJavaScriptExt(this.controller, script);
    }
    return new webview.JsMessageExt();
  }


  async runJavaScriptFun(funName: string, param?: string): Promise<string> {
    if (this.controller) {
      return ZzjWebHelper.runJavaScriptFun(this.controller, funName, param);
    }
    return '';
  }


  /**
   * 日志打印
   * @param content
   */
  logError(tag:string, error:Any): void {
    //console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
    //console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
    if (ZzjWebHelper.debug && (error !== undefined) &&  (error !== null ) ) {
      logger.error(tag,`errorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
    }
  }

  logInfo(tag:string, content: string): void {
    if (ZzjWebHelper.debug) {
      logger.info(tag,content);
    }
  }

  onEnableDownloadNotification?(): boolean{
    return false;
  }




}
