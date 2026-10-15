import { webview } from '@kit.ArkWeb';
import { DialogAction, DialogHelper } from 'dialog';

import { DateUtil } from '../../utils/DateUtil';
import { ObjectUtil } from '../../utils/ObjectUtil';
import { NotificationUtil } from '../../utils/NotificationUtil';
import { CacheUtil } from '../../utils/CacheUtil';
import { FileUtil } from '../../utils/FileUtil';
import { StrUtil } from '../../utils/StrUtil';
import { ZzjWebJsObject } from './ZzjWebJsObject';
import { ZzjWebClient } from './ZzjWebClient';
import { ZzjWebHelper } from './ZzjWebHelper';
import { ZzjWebOptions } from './ZzjWebOptions';
import { BaseZzjWebClient } from './BaseZzjWebClient';
import { ZzjWebUtils } from './ZzjWebUtils';
import { logger } from 'utils';
import { ZzjWebDownload } from './ZzjWebDownload';


@ComponentV2
export struct ZzjWeb {

  private needReloadWhenVisible: boolean = false ;  // Web组件不可见时render退出后阻止重新加载页面，在可见时重新加载页面。
  private webIsVisible: boolean = false;            // 判断Web组件是否可见。
  // 此处是将子进程异常崩溃和其它异常原因做了区分，应用开发者可根据实际业务特点，细化对应异常的处理策略。
  private renderReloadMaxForCrashed: number = 5;    // 设置因为异常崩溃后重新加载的最大重试次数，应用可根据业务特点，自行设置试错上限。
  private renderReloadCountForCrashed: number = 0;  // 异常崩溃后重新加载的次数。
  private renderReloadMaxForOthers: number = 10;    // 设置因为其它异常原因退出的最大重试次数，应用可根据业务特点，自行设置试错上限。
  private renderReloadCountForOthers: number = 0;   // 其它异常原因退出后重新加载的次数。

  //父传进来，没有初始化，需要增加参数 @Require
  @Require @Param controller: webview.WebviewController;
  @Require @Param src: ResourceStr;
  //@Param 父传子，可以初始化，父传子单向,值不能修改，; 但是，如果装饰的变量是对象类型，在子组件中可以修改对象的属性，在
  @Param options: ZzjWebOptions = new ZzjWebOptions();
  @Param webClient: ZzjWebClient = new BaseZzjWebClient();
  @Param arkJsObject: ZzjWebJsObject | ZzjWebJsObject[] = new ZzjWebJsObject();
  @Require @Param downloader: ZzjWebDownload|undefined;

  //本组建自己用
  @Local arkJsObjects: ZzjWebJsObject[] = []; //需要注册的接口对象

  private beginTime: number = 0; //页面开始加载时间戳
  private downloadDelegate: webview.WebDownloadDelegate = new webview.WebDownloadDelegate(); //下载任务的状态会通过该类的回调接口通知给用户。

  aboutToAppear(): void {
    if (Array.isArray(this.arkJsObject)) {
      if (this.arkJsObject.length > 0) {
        this.arkJsObjects = this.arkJsObject;
      }
    } else {
      this.arkJsObjects = [this.arkJsObject];
    }
  }

  reload():void
  {
    try {
      let currentUrl:string =  this.controller.getUrl();
      if(currentUrl.length>5){
        this.controller.loadUrl(currentUrl);
      }else{
        this.controller.refresh();
      }
    } catch (error) {
      try {
        this.controller.refresh();
      } catch (error) {
        // TODO: Implement error handling.
      }
    }
  }

  build() {
    Column() {
      Web({
        src: this.src,
        controller: this.controller,
        renderMode: this.options.renderMode,
        incognitoMode: this.options.incognitoMode,
        sharedRenderProcessToken: this.options.sharedRenderProcessToken
      })
        .width('100%')
        .height('100%')
        .zIndex(10) //保证web全屏播放时候可以在最上层
        .domStorageAccess(this.options.domStorageAccess)
        .javaScriptAccess(this.options.javaScriptAccess)
        .fileAccess(this.options.fileAccess)
        .imageAccess(this.options.imageAccess)
        .onlineImageAccess(this.options.onlineImageAccess)
        .overScrollMode(this.options.overScrollMode)
        .mixedMode(this.options.mixedMode)
        .zoomAccess(this.options.zoomAccess)
        .overviewModeAccess(this.options.overviewModeAccess)
        .databaseAccess(this.options.databaseAccess)
        .geolocationAccess(this.options.geolocationAccess)
        .mediaPlayGestureAccess(this.options.mediaPlayGestureAccess)
        .multiWindowAccess(this.options.multiWindowAccess)
        .horizontalScrollBarAccess(this.options.horizontalScrollBarAccess)
        .verticalScrollBarAccess(this.options.verticalScrollBarAccess)
        .cacheMode(this.options.cacheMode)
        .copyOptions(this.options.copyOptions)
        .textZoomRatio(this.options.textZoomRatio)
        .initialScale(this.options.initialScale)
        .blockNetwork(this.options.blockNetwork)
        .defaultFixedFontSize(this.options.defaultFixedFontSize)
        .defaultFontSize(this.options.defaultFontSize)
        .minFontSize(this.options.minFontSize)
        .minLogicalFontSize(this.options.minLogicalFontSize)
        .webFixedFont(this.options.webFixedFont)
        .webSansSerifFont(this.options.webSansSerifFont)
        .webSerifFont(this.options.webSerifFont)
        .webStandardFont(this.options.webStandardFont)
        .webFantasyFont(this.options.webFantasyFont)
        .webCursiveFont(this.options.webCursiveFont)
        .darkMode(this.options.darkMode)
        .forceDarkAccess(this.options.forceDarkAccess)
        .pinchSmooth(this.options.pinchSmooth)
        .allowWindowOpenMethod(this.options.allowWindowOpenMethod)
        .mediaOptions(this.options.mediaOptions)
        .javaScriptOnDocumentStart(this.options.javaScriptOnDocumentStart)
        .javaScriptOnDocumentEnd(this.options.javaScriptOnDocumentEnd)
        .layoutMode(this.options.layoutMode)
        .nestedScroll(this.options.nestedScroll)
        .enableNativeEmbedMode(this.options.enableNativeEmbedMode)
        .defaultTextEncodingFormat(this.options.defaultTextEncodingFormat)
        .metaViewport(this.options.metaViewport)
        .textAutosizing(this.options.textAutosizing)
        .enableNativeMediaPlayer(this.options.enableNativeMediaPlayer)
        .selectionMenuOptions(this.options.selectionMenuOptions)
        .keyboardAvoidMode(this.options.keyboardAvoidMode)

        .onVisibleAreaChange([0, 1.0], (isVisible) => {
          this.webIsVisible = isVisible;
          if (isVisible && this.needReloadWhenVisible) { // Web组件可见时重新加载页面。
            this.needReloadWhenVisible = false;
            this.reload();
          }
        })
        // 应用监听渲染子进程异常退出回调，并进行异常处理。
        .onRenderExited((event) => {
          this.webClient.onRenderExited?.(event);
          this.logInfo(`onRenderExited => 事件回调`);

          if (!event) {
            return;
          }
          if (event.renderExitReason == RenderExitReason.ProcessCrashed) {
            if (this.renderReloadCountForCrashed >= this.renderReloadMaxForCrashed) {
              // 设置重试次数上限保护，避免必现问题导致页面被循环加载。
              return;
            }
            console.info('renderReloadCountForCrashed: ' + this.renderReloadCountForCrashed);
            this.renderReloadCountForCrashed++;
          } else {
            if (this.renderReloadCountForOthers >= this.renderReloadMaxForOthers) {
              // 设置重试次数上限保护, 避免必现问题导致页面被循环加载。
              return;
            }
            console.info('renderReloadCountForOthers: ' + this.renderReloadCountForOthers);
            this.renderReloadCountForOthers++;
          }
          if (this.webIsVisible) {
            // Web组件可见则立即重新加载。
            this.reload();
            return;
          }
          // Web组件不可见时不立即重新加载。
          this.needReloadWhenVisible = true;
        })

        .onControllerAttached(() => {
          this.webClient.setWebviewController?.(this.controller);
          this.downloader?.setWebviewController(this.controller);
          this.initDownloadDelegate();
          this.arkJsObjects.forEach((jsObject) => {
            jsObject?.setWebviewController(this.controller)
            try {
              //注入对象。对象名字（自定义），方法列表，这样 js就可以直接执行：对象名字.方法==》这样就可以js执行应用对象方法了。
              // let pictures = picture.chosePicture()
              this.controller.registerJavaScriptProxy(jsObject, jsObject.getName(), ObjectUtil.getMethodsNames(jsObject));
            } catch (error) {
              logger.error('onControllerAttached registerJavaScriptProxy error: ', JSON.stringify(error));
            }
          })
          this.webClient.onControllerAttached?.();
          this.logInfo(`onControllerAttached => 事件回调`);
        })
        .onPageBegin((event) => {
          this.webClient.onPageBegin?.(event);
          this.beginTime = DateUtil.getTodayTime();
          this.logInfo(`onPageBegin => ${event.url}`);
        })
        .onPageEnd((event) => {
          this.webClient.onPageEnd?.(event);
          this.logInfo(`onPageEnd => 耗时：${DateUtil.getTodayTime() - this.beginTime}，${event.url}`);
        })
        .onProgressChange((event) => {
          this.webClient.onProgressChange?.(event);
          this.logInfo(`onProgressChange => ${event.newProgress}`);
        })
        .onPageVisible((event) => {
          this.webClient.onPageVisible?.(event);
          this.logInfo(`onPageVisible => ${event.url}`);
        })
        .onLoadIntercept((event) => {
          this.logInfo(`onLoadIntercept => 事件回调`);
          return this.webClient.onLoadIntercept?.(event) ?? false;
        })
        .onOverrideUrlLoading((request) => {
          this.logInfo(`onOverrideUrlLoading => 事件回调`);
          let flag = this.webClient.onOverrideUrlLoading?.(request) ?? false;
          if ((!flag) && request && request.getRequestUrl() == "about:blank") {
            flag= true; //不加载空白页
          }
          return flag;// this.webClient.onOverrideUrlLoading?.(request) ?? false;

        })
        .onInterceptRequest((event) => {
          this.logInfo(`onInterceptRequest => 事件回调`);
          return this.webClient?.onInterceptRequest?.(event) ?? null;
        })
        .onTitleReceive((event) => {
          this.webClient.onTitleReceive?.(event);
          this.logInfo(`onTitleReceive => ${event.title}`);
        })
        .onErrorReceive((event) => {
          this.webClient.onErrorReceive?.(event);
          this.logInfo(`onErrorReceive => errorCode：${event.error.getErrorCode()} - errorMsg：${event.error.getErrorInfo()}`);
        })
        .onHttpErrorReceive((event) => {
          this.webClient.onHttpErrorReceive?.(event);
          this.logInfo(`onHttpErrorReceive => responseCode：${event.response.getResponseCode()}`);
        })
        .onSslErrorEventReceive((event) => {
          this.webClient.onSslErrorEventReceive?.(event);
          this.logInfo(`onSslErrorEventReceive => 事件回调`);
        })
        .onSslErrorEvent((event) => {
          this.webClient.onSslErrorEvent?.(event);
          this.logInfo(`onSslErrorEvent => isMainFrame：${event.isMainFrame}`);
        })
        .onHttpAuthRequest((event) => {
          this.logInfo(`onHttpAuthRequest => 事件回调`);
          return this.webClient?.onHttpAuthRequest?.(event) ?? true;
        })
        .onClientAuthenticationRequest((event) => {
          this.webClient.onClientAuthenticationRequest?.(event);
          this.logInfo(`onClientAuthenticationRequest => 事件回调`);
        })
        // .onRenderExited((event) => {
        //
        // })
        .onDownloadStart((event) => {
          if (this.webClient.onDownloadStart) {
            this.webClient.onDownloadStart(event);
          }
          this.logInfo(`onDownloadStart => 事件回调`);
        })
        .onShowFileSelector((event) => {
          this.logInfo(`onShowFileSelector => 事件回调`);
          if (this.webClient.onShowFileSelector) {
            return this.webClient.onShowFileSelector(event);
          }
          return false;
        })
        .onPermissionRequest((event) => {
          if (this.webClient.onPermissionRequest) {
            this.webClient.onPermissionRequest(event);
          }
          this.logInfo(`onPermissionRequest => 事件回调`);
        })
        .onGeolocationShow((event) => {
          if (this.webClient.onGeolocationShow) {
            this.webClient.onGeolocationShow(event);
          }
          this.logInfo(`onGeolocationShow => 事件回调`);
        })
        .onGeolocationHide(() => {
          if (this.webClient.onGeolocationHide) {
            this.webClient.onGeolocationHide();
          }
          this.logInfo(`onGeolocationHide => 事件回调`);
        })
        .onFullScreenEnter((event) => {
          if (this.webClient.onFullScreenEnter) {
            this.webClient.onFullScreenEnter(event);
          }
          this.logInfo(`onFullScreenEnter => 事件回调`);
        })
        .onFullScreenExit(() => {
          if (this.webClient.onFullScreenExit) {
            this.webClient.onFullScreenExit();
          }
          this.logInfo(`onFullScreenExit => 事件回调`);
        })
        .onContextMenuShow((event) => {
          this.logInfo(`onContextMenuShow => 事件回调`);
          if (this.webClient.onContextMenuShow) {
            return this.webClient.onContextMenuShow(event);
          }
          return false;
        })
        .onContextMenuHide(() => {
          if (this.webClient.onContextMenuHide) {
            this.webClient.onContextMenuHide();
          }
          this.logInfo(`onContextMenuHide => 事件回调`);
        })
        .onScaleChange((event) => {
          this.webClient.onScaleChange?.(event);
          this.logInfo(`onScaleChange => changed from ${event.oldScale} to ${event.newScale}`);
        })
        .onScroll((event) => {
          this.webClient.onScroll?.(event);
         // this.logInfo(`onScroll => x=${event.xOffset}，y=${event.yOffset}`);
        })
        .onOverScroll((event) => {
          this.webClient.onOverScroll?.(event);
          this.logInfo(`onOverScroll => x=${event.xOffset}，y=${event.yOffset}`);
        })
        .onRequestSelected(() => {
          this.webClient.onRequestSelected?.();
          this.logInfo(`onRequestSelected => 事件回调`);
        })
        .onScreenCaptureRequest((event) => {
          this.webClient.onScreenCaptureRequest?.(event);
          this.logInfo(`onScreenCaptureRequest => ${event.handler.getOrigin()}`);
        })
        .onWindowNew((event) => {
          this.webClient.onWindowNew?.(event);
          this.logInfo(`onWindowNew => 事件回调`);
        })
        .onWindowExit(() => {
          this.webClient.onWindowExit?.();
          this.logInfo(`onWindowExit => 事件回调`);
        })
        .onResourceLoad((event) => {
          this.webClient.onResourceLoad?.(event);
          this.logInfo(`onResourceLoad => ${event.url}`);
        })
        .onRefreshAccessedHistory((event) => {
          this.webClient.onRefreshAccessedHistory?.(event);
          this.logInfo(`onRefreshAccessedHistory => 事件回调`);
        })
        .onBeforeUnload((event) => {
          this.logInfo(`onBeforeUnload => ${event.url}`);
          return this.webClient.onBeforeUnload?.(event) ?? false;
        })
        .onRenderProcessNotResponding((event) => {
          this.webClient.onRenderProcessNotResponding?.(event);
          this.logInfo(`onRenderProcessNotResponding => 事件回调`);
        })
        .onRenderProcessResponding(() => {
          this.webClient.onRenderProcessResponding?.();
          this.logInfo(`onRenderProcessResponding => 事件回调`);
        })
        .onSearchResultReceive((event) => {
          this.webClient.onSearchResultReceive?.(event);
          this.logInfo(`onSearchResultReceive => 事件回调`);
        })
        .onDataResubmitted((event) => {
          this.webClient.onDataResubmitted?.(event);
          this.logInfo(`onDataResubmitted => 事件回调`);
        })
        .onInterceptKeyEvent((event) => {
          this.logInfo(`onInterceptKeyEvent => keyCode=${event.keyCode}`);
          return this.webClient.onInterceptKeyEvent?.(event) ?? false;
        })
        .onTouchIconUrlReceived((event) => {
          this.webClient.onTouchIconUrlReceived?.(event);
          this.logInfo(`onTouchIconUrlReceived => 事件回调`);
        })
        .onFaviconReceived((event) => {
          this.webClient.onFaviconReceived?.(event);
          this.logInfo(`onFaviconReceived => 事件回调`);
        })
        .onAudioStateChanged((event) => {
          this.webClient.onAudioStateChanged?.(event);
          this.logInfo(`onAudioStateChanged => 事件回调`);
        })
        .onFirstContentfulPaint((event) => {
          this.webClient.onFirstContentfulPaint?.(event);
          this.logInfo(`onFirstContentfulPaint => 事件回调`);
        })
        .onFirstMeaningfulPaint((paint) => {
          this.webClient.onFirstMeaningfulPaint?.(paint);
          this.logInfo(`onFirstMeaningfulPaint => 事件回调`);
        })
        .onLargestContentfulPaint((paint) => {
          this.webClient.onLargestContentfulPaint?.(paint);
          this.logInfo(`onLargestContentfulPaint => 事件回调`);
        })
        .onNavigationEntryCommitted((details) => {
          this.webClient.onNavigationEntryCommitted?.(details);
          this.logInfo(`onNavigationEntryCommitted => 事件回调`);
        })
        .onNativeEmbedLifecycleChange((event) => {
          this.webClient.onNativeEmbedLifecycleChange?.(event);
          this.logInfo(`onNativeEmbedLifecycleChange => 事件回调`);
        })
        .onNativeEmbedGestureEvent((event) => {
          this.webClient.onNativeEmbedGestureEvent?.(event);
          this.logInfo(`onNativeEmbedGestureEvent => 事件回调`);
        })
        .onNativeEmbedVisibilityChange((info) => {
          this.webClient.onNativeEmbedVisibilityChange?.(info);
          this.logInfo(`onNativeEmbedVisibilityChange => 事件回调`);
        })
        .onSafeBrowsingCheckResult((threatType) => {
          this.webClient.onSafeBrowsingCheckResult?.(threatType);
          this.logInfo(`onSafeBrowsingCheckResult => 事件回调`);
        })
        .onIntelligentTrackingPreventionResult((details) => {
          this.webClient.onIntelligentTrackingPreventionResult?.(details);
          this.logInfo(`onNativeEmbedVisibilityChange => 事件回调`);
        })
        .onViewportFitChanged((viewportFit) => {
          this.webClient.onViewportFitChanged?.(viewportFit);
          this.logInfo(`onViewportFitChanged => 事件回调`);
        })
        .onInterceptKeyboardAttach((keyboardCallbackInfo) => {
          this.logInfo(`onInterceptKeyboardAttach => 事件回调`);
          const option: WebKeyboardOptions = { useSystemKeyboard: true }; //option初始化，默认使用系统默认键盘
          return this.webClient.onInterceptKeyboardAttach?.(keyboardCallbackInfo) ?? option;
        })
        .onAdsBlocked((details) => {
          if (this.webClient.onAdsBlocked) {
            this.webClient.onAdsBlocked(details);
          }
          this.logInfo(`onAdsBlocked => 事件回调`);
        })
        .onAlert((event) => {
          this.logInfo(`onAlert => ${event.url}`);
          if (this.webClient.onAlert) {
            return this.webClient.onAlert(event);
          } else {
            DialogHelper.showAlertDialog({
              secondaryButton: $r("app.string.btn_sure"),
              backCancel: false,
              autoCancel: false,
              cornerRadius: 16,
              content: event.message,
              onAction: () => {
                event.result.handleConfirm();
              }
            })
            return true;
          }
        })
        .onConfirm((event) => {
          this.logInfo(`onConfirm => ${event.url}`);
          if (this.webClient.onConfirm) {
            return this.webClient.onConfirm(event);
          } else {
            DialogHelper.showAlertDialog({
              primaryButton: $r("app.string.btn_cancel"),
              secondaryButton: $r("app.string.btn_sure"),
              backCancel: false,
              autoCancel: false,
              cornerRadius: 16,
              content: event.message,
              onAction: (action) => {
                if (action == DialogAction.ONE) {
                  event.result.handleCancel();
                } else {
                  event.result.handleConfirm();
                }
              }
            })
            return true;
          }
        })
        .onPrompt((event) => {
          this.logInfo(`onPrompt => ${event.url} - ${event.value}`);
          if (this.webClient.onPrompt) {
            return this.webClient.onPrompt(event);
          } else {
            DialogHelper.showTextInputDialog({
              buttons: [$r("app.string.btn_cancel"), $r("app.string.btn_sure")],
              backCancel: false,
              autoCancel: false,
              cornerRadius: 16,
              secondaryTitle: event.message,
              text: event.value,
              onAction: (action, _dialogId, content) => {
                if (action == DialogAction.ONE) {
                  event.result.handleCancel();
                } else {
                  event.result.handlePromptConfirm(content);
                }
              }
            })
            return true;
          }
        })
        .onConsole((event) => {
          this.logInfo(`onConsole => 事件回调`);
          return this.webClient.onConsole?.(event) ?? false;
        })
    }
    .width('100%')
    .height('100%')
  }

  private  enableDownloadNotification():boolean {
    let r :boolean=false;
    if(this.webClient.onEnableDownloadNotification){
      r= this.webClient.onEnableDownloadNotification();
    }
    return r;
  }

  /**
   * 初始化WebDownloadDelegate，下载任务的状态会通过该类的回调接口通知给用户。
   */
  private initDownloadDelegate() {
    ZzjWebUtils.setDownloadPath(this.options.downloadPath ?? FileUtil.getCacheDirPath()); //ArkWeb文件下载路径
    //下载开始前通知给用户，用户需要在此接口中调用WebDownloadItem.start("xxx")并提供下载路径，否则下载会一直处于PENDING状态。
    this.downloadDelegate.onBeforeDownload(async (item: webview.WebDownloadItem) => {

      const gid =item.getGuid();
      const url = item.getUrl();
      const fileName = item.getSuggestedFileName();

      let savePath = `${ZzjWebUtils.getArkDownloadPath()}/${fileName}`; //下载文件路径
      savePath = ZzjWebUtils.getAvailableFilePath(savePath);

      let handled:boolean =false;
      if(this.downloader&& this.downloader.onFileDownloadStart ){
        handled= this.downloader.onFileDownloadStart(item,url,gid,fileName,savePath);
      }

      try {
        ///data/storage/el2/base/haps/default/cache/223908bohlmboqvcabh4qa.jpg
        item.start(savePath);

        if(!handled && this.enableDownloadNotification()){
          CacheUtil.put<number>(gid, NotificationUtil.generateNotificationId()); //缓存通知id
        }

      } catch (error) {
        logger.error(`下载文件 ${fileName} 时出错: `, error);
        item.cancel();
        CacheUtil.remove(gid);
        if(this.downloader && this.downloader.onFileDownloadFinished) {
          this.downloader.onFileDownloadFinished(item, false);
        }
      }
    });

    //下载过程中的回调，通过该回调的参数可以了解下载进度等信息。
    this.downloadDelegate.onDownloadUpdated((item: webview.WebDownloadItem) => {
      const notificationKey = item.getGuid();
      const fileName = item.getSuggestedFileName();
      const percent = item.getPercentComplete();

      let handled:boolean =false;
      if(this.downloader && this.downloader.onFileDownloadProgress) {
        handled= this.downloader.onFileDownloadProgress(item, item.getUrl(), item.getGuid(), fileName, percent);
      }
      if(!handled && this.enableDownloadNotification()){
        if (percent >= 100) {
          ZzjWebUtils.sendNotification(notificationKey, fileName, 100, 1);
        } else {
          ZzjWebUtils.sendNotification(notificationKey, fileName, percent, 0);
        }
      }
    });

    //下载完成的通知。
    this.downloadDelegate.onDownloadFinish((item: webview.WebDownloadItem) => {
      const notificationKey = item.getGuid();
      const fileName = item.getSuggestedFileName();
      let handled:boolean =false;
      if(this.downloader && this.downloader.onFileDownloadFinished) {
        handled=this.downloader.onFileDownloadFinished(item, false);
      }
      if(!handled&& this.enableDownloadNotification()){
        ZzjWebUtils.sendNotification(notificationKey, fileName, 100, 1);
      }
    });

    //下载失败的通知。
    this.downloadDelegate.onDownloadFailed((item: webview.WebDownloadItem) => {
      const notificationKey = item.getGuid();
      const fileName = item.getSuggestedFileName();
      let handled:boolean =false;
      if(this.downloader&& this.downloader.onFileDownloadFinished) {
        handled= this.downloader.onFileDownloadFinished(item, true);
      }
      if(!handled&& this.enableDownloadNotification()){
        ZzjWebUtils.sendNotification(notificationKey, fileName, 0, -1);
      }
    });

    try {
      this.controller?.setDownloadDelegate(this.downloadDelegate);
    } catch (error) {
      // TODO: Implement error handling.
    }
    //controller.startDownload(url)
  }

  /**
   * 日志打印
   * @param content
   */
  logInfo(content: string): void {
    if (ZzjWebHelper.debug && StrUtil.isNotEmpty(content)) {
      logger.info(content);
    }
  }


}
