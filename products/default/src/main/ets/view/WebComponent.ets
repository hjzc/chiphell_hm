//
// import { webview } from '@kit.ArkWeb';
// import { BusinessError } from '@kit.BasicServicesKit';
// import { logger } from 'utils';
// import { WebSite } from '../model/WebSite';
//
//
// @Component
// export struct WebComponent {
//   private  srpToken :string = 'com.zorro.web.component';
//
//   private needReloadWhenVisible: boolean = false ;  // Web组件不可见时render退出后阻止重新加载页面，在可见时重新加载页面。
//   private webIsVisible: boolean = false;            // 判断Web组件是否可见。
//   // 此处是将子进程异常崩溃和其它异常原因做了区分，应用开发者可根据实际业务特点，细化对应异常的处理策略。
//   private renderReloadMaxForCrashed: number = 5;    // 设置因为异常崩溃后重新加载的最大重试次数，应用可根据业务特点，自行设置试错上限。
//   private renderReloadCountForCrashed: number = 0;  // 异常崩溃后重新加载的次数。
//   private renderReloadMaxForOthers: number = 10;    // 设置因为其它异常原因退出的最大重试次数，应用可根据业务特点，自行设置试错上限。
//   private renderReloadCountForOthers: number = 0;   // 其它异常原因退出后重新加载的次数。
//
//   // 创建Web组件。
//   @Link webUrl: string | null;
//   @Link progress:number;
//   @Link controller: webview.WebviewController;
//   @Link site:WebSite;
//
//   //@Require @Param controller: webview.WebviewController;
//  // @Require @Param src: ResourceStr;
//  //  @Param options: ZzjWebOptions ;
//  //  @Param webClient: ZzjWebClient ;
//  //  @Param arkJsObject: ZzjWebJsObject | ZzjWebJsObject[] ;
//  //  @Local arkJsObjects: ZzjWebJsObject[] ; //需要注册的接口对象
//
//   private handleUaFlag:boolean = false;
//   private progressDelayTimerId: number = -1;
//
//
//
//   customUAChange():void{
//     logger.debug('customUAChange');
//     this.setWebCustomUserAgent();
//   }
//
//   private  setWebCustomUserAgent():void{
//     try {
//       this.controller.setCustomUserAgent(this.site.getUserAgent());
//     } catch (error) {
//       logger.error('ErrorCode: ', JSON.stringify(error));
//     }
//   }
//
//   aboutToAppear(): void {
//
//   }
//
//   private clearProgressDelayTimer(){
//     if(this.progressDelayTimerId>-1){
//       clearTimeout(this.progressDelayTimerId);
//       this.progressDelayTimerId = -1;
//     }
//   }
//
//   // build(){
//   //   // ZzjWeb({
//   //   //   controller: this.controller,
//   //   //   src: this.webUrl,
//   //   //   options: this.options,
//   //   //   webClient: this.webClient,
//   //   //   arkJsObject: this.jsObject
//   //   // })
//   // }
//
//   build() {
//     Column() {
//
//
//       Web({ src: this.webUrl, controller: this.controller , sharedRenderProcessToken: this.srpToken})
//         .width('100%')
//         .onVisibleAreaChange([0, 1.0], (isVisible) => {
//           this.webIsVisible = isVisible;
//           if (isVisible && this.needReloadWhenVisible) { // Web组件可见时重新加载页面。
//             this.needReloadWhenVisible = false;
//             try {
//               this.controller.loadUrl(this.webUrl);
//             } catch (error) {
//               logger.error('load url error: ', JSON.stringify(error));
//             }
//           }
//         })
//         // 应用监听渲染子进程异常退出回调，并进行异常处理。
//         .onRenderExited((event) => {
//           if (!event) {
//             return;
//           }
//           if (event.renderExitReason == RenderExitReason.ProcessCrashed) {
//             if (this.renderReloadCountForCrashed >= this.renderReloadMaxForCrashed) {
//               // 设置重试次数上限保护，避免必现问题导致页面被循环加载。
//               return;
//             }
//             console.info('renderReloadCountForCrashed: ' + this.renderReloadCountForCrashed);
//             this.renderReloadCountForCrashed++;
//           } else {
//             if (this.renderReloadCountForOthers >= this.renderReloadMaxForOthers) {
//               // 设置重试次数上限保护, 避免必现问题导致页面被循环加载。
//               return;
//             }
//             console.info('renderReloadCountForOthers: ' + this.renderReloadCountForOthers);
//             this.renderReloadCountForOthers++;
//           }
//           if (this.webIsVisible) {
//             // Web组件可见则立即重新加载。
//             try {
//               this.controller.loadUrl(this.webUrl);
//             } catch (error) {
//               logger.error('load url error: ', JSON.stringify(error));
//             }
//             return;
//           }
//           // Web组件不可见时不立即重新加载。
//           this.needReloadWhenVisible = true;
//         })
//         .onRenderProcessNotResponding((data) => {
//           console.log("onRenderProcessNotResponding: [jsStack]= " + data.jsStack +
//             ", [process]=" + data.pid + ", [reason]=" + data.reason);
//         })
//         .onRenderProcessResponding(() => {
//           console.log("onRenderProcessResponding again");
//         })
//         .onControllerAttached(() => {
//           // 推荐在此loadUrl、设置自定义用户代理、注入JS对象等
//           console.info('onControllerAttached execute')
//           if(this.handleUaFlag==false){
//             try {
//               if(this.site.defaultUA==null){
//                 let userAgent = this.controller.getUserAgent();
//                 if (userAgent!=null) {
//                   this.site.defaultUA = userAgent;
//                 }
//               }
//               if(this.site.getUserAgent() !== this.site.defaultUA){
//                 this.setWebCustomUserAgent();
//               }
//               this.handleUaFlag =true;
//             } catch (error) {
//               logger.error('onControllerAttached error: ', JSON.stringify(error));
//               //console.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
//             }
//           }
//         })
//         .onLoadIntercept((event) => {
//           if (event) {
//             console.info('onLoadIntercept url:' + event.data.getRequestUrl())
//             console.info('url:' + event.data.getRequestUrl())
//             console.info('isMainFrame:' + event.data.isMainFrame())
//             console.info('isRedirect:' + event.data.isRedirect())
//             console.info('isRequestGesture:' + event.data.isRequestGesture())
//           }
//           // 返回true表示阻止此次加载，否则允许此次加载
//           return false;
//         })
//         .onOverrideUrlLoading((webResourceRequest: WebResourceRequest) => {
//           if (webResourceRequest && webResourceRequest.getRequestUrl() == "about:blank") {
//             return true;
//           }
//           return false;
//         })
//         .onInterceptRequest((event) => {
//           // if (event) {
//           //   console.info('url:' + event.request.getRequestUrl());
//           // }
//           // let head1: Header = {
//           //   headerKey: "Connection",
//           //   headerValue: "keep-alive"
//           // }
//           // let head2: Header = {
//           //   headerKey: "Cache-Control",
//           //   headerValue: "no-cache"
//           // }
//           // // 将新元素追加到数组的末尾，并返回数组的新长度。
//           //
//           // responseWeb: WebResourceResponse = new WebResourceResponse();
//           // heads: Header[] = new Array();
//           //
//           // let length = this.heads.push(head1);
//           // length = this.heads.push(head2);
//           // console.info('The response header result length is :' + length);
//           // this.responseWeb.setResponseHeader(this.heads);
//           // this.responseWeb.setResponseData(this.webData);
//           // this.responseWeb.setResponseEncoding('utf-8');
//           // this.responseWeb.setResponseMimeType('text/html');
//           // this.responseWeb.setResponseCode(200);
//           // this.responseWeb.setReasonMessage('OK');
//           // // 返回响应数据则按照响应数据加载，无响应数据则返回null表示按照原来的方式加载
//           // return this.responseWeb;
//           return null;
//         })
//
//         .onProgressChange( (event) =>{
//           if (event) {
//             console.info('newProgress:' + event.newProgress);
//             this.progress = event.newProgress;
//             if (event.newProgress == 100) {
//               if(this.progressDelayTimerId < 0 ){
//                 this.progressDelayTimerId=setTimeout(() => {
//                   if(this.progress==100){
//                     this.progress +=1;
//                   }
//                 }, 1000);
//               }
//             }else if(this.progress!=100){
//                this.clearProgressDelayTimer();
//             }
//           }
//         })
//         .onPageBegin((event) => {
//           if (event) {
//             console.info('onPageBegin url:' + event.url);
//           }
//         })
//         .onFirstContentfulPaint(event => {
//           //网页首次内容绘制的回调函数。首次绘制文本、图像、首次绘制文本、图像、非空白Canvas或SVG的时间点。
//           if (event) {
//             console.info("onFirstContentfulPaint:" + "[navigationStartTick]:" +
//             event.navigationStartTick + ", [firstContentfulPaintMs]:" +
//             event.firstContentfulPaintMs);
//           }
//         })
//         .onFirstMeaningfulPaint(event =>{
//           //网页绘制页面主要内容的回调函数。首次绘制主要内容的时间点。
//         })
//         .onLargestContentfulPaint(event =>{
//           //网页绘制页面主要内容的回调函数。首次绘制主要内容的时间点。
//         })
//         .onPageEnd((event) => {
//           // 推荐在此事件中执行JavaScript脚本
//           if (event) {
//             console.info('onPageEnd url:' + event.url);
//           }
//         })
//         .onPageVisible((event) => {
//           console.info('onPageVisible url:' + event.url);
//         })
//         .onRenderExited((event) => {
//           if (event) {
//             console.info('onRenderExited reason:' + event.renderExitReason);
//           }
//         })
//         .onDisAppear(() => {
//           // try {
//           //   this.getUIContext().getPromptAction().showToast({
//           //     message: 'The web is hidden',
//           //     duration: 2000
//           //   })
//           // } catch (error) {
//           //   // TODO: Implement error handling.
//           // }
//         })
//     }
//   }
//
// }