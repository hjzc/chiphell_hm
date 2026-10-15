
import { BreakpointSystem,BreakpointTypeEnum, logger } from 'utils';
import { common, ConfigurationConstant } from '@kit.AbilityKit';

import { webview} from '@kit.ArkWeb';
import { BusinessError } from '@kit.BasicServicesKit';
import { SiteFiltersPage} from './SiteFiltersPage';
import { WebToolBar} from  '../view/WebToolBar';
import { WebSite } from '../model/WebSite';
import { AppUtil } from '../utils/AppUtil';
import { DarkModeSettingPage } from './DarkModeSettingPage';
import { ZzjWebOptions } from '../web/Zzj/ZzjWebOptions';
import { ZzjWeb } from '../web/Zzj/ZzjWeb';
import { SiteWebClient } from '../web/SiteWebClient';
import { SiteWebJsObject } from '../web/SiteWebJsObject';
import { ZjStorage } from '../Storage/ZjStorage';
import { env } from '../Storage/ZjEnv';
import { AppStorageV2, display } from '@kit.ArkUI';
import { PersistenceV2 } from '@ohos.arkui.StateManagement';
import { AppSettingsPage } from './AppSettingsPage';
import { IconData, PicturePreview } from 'imagegallery';
import { MPIType } from '../model/ToolBarMorePopModel';
import { StrUtil } from '../utils/StrUtil';
import { DialogAction, DialogHelper } from 'dialog';
import { ToastUtil } from '../utils/ToastUtil';
import { getDBManager } from '../common/DBManager';
import { RecordHistoryPage } from './RecordHistoryPage';
import { JSONUtil } from '../utils/JSONUtil';
import { SetServicePage } from './SetServicePage';
import { Any } from '../utils/UtilConstraint';
import { SimpleWebPage } from './SimpleWebPage';
import { AppStorageKey } from '../common/AppStorageKey';
import { DelayTasks } from '../utils/DelayTasks';
import { NetConnectionManager } from '../common/NetConnectionManager';
import { NotificationUtil } from '../utils/NotificationUtil';
import { WebImageDownloader } from '../model/WebImageDownloader';

//接受序列化失败的回调
PersistenceV2.notifyOnError((key: string, reason: string, msg: string) => {
  logger.error(`PersistenceV2 error key: ${key}, reason: ${reason}, message: ${msg}`);
});

@Entry
@ComponentV2
struct Index {
  @Provider('navPageStack') navPageStack: NavPathStack = new NavPathStack();
  private uiContext: UIContext  = this.getUIContext();
  private abilityContext: common.UIAbilityContext  = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private breakpointSystem: BreakpointSystem = new BreakpointSystem();
  @Local storage: ZjStorage = AppStorageV2.connect(ZjStorage, 'storage', () => new ZjStorage())!;
  //@Local site: WebSite = PersistenceV2.connect(WebSite, 'site',() => new WebSite())!;
  // 使用key:connect2存入数据
  @Local site: WebSite = PersistenceV2.globalConnect({type: WebSite, key:'connect2', defaultCreator:() => new WebSite(), areaMode: 3})!;

  @Local statusBarHeight: number = env.statusBarHeight;
  // 监听断点变化
  @Local currentBreakpoint: string = BreakpointTypeEnum.MD;
  @Local themeMode: ConfigurationConstant.ColorMode = env.themeMode;
  @Local currentColorMode: ConfigurationConstant.ColorMode = env.currentColorMode;

  //初始化 同步一次
  @Param @Once webUrl:ResourceStr = '';
  @Param @Once controller: webview.WebviewController = new webview.WebviewController();

  @Local options: ZzjWebOptions = new ZzjWebOptions(); //必选，Web参数
  @Local webClient: SiteWebClient = new SiteWebClient(this.site,this.storage); //可选，Web事件
  @Local jsObject: SiteWebJsObject = new SiteWebJsObject(); //可选，JS交互
  @Local initDataLoading:boolean = true;
  @Local isLandscape:boolean = false;

  private lastBackKeyTapTime:number = 0;
  private continueBackKeyTapCount:number = 0;
  private checkUserAgreementStateAlertId?:string;

  private netMg ?: NetConnectionManager ;

  private webDownloader:WebImageDownloader = new WebImageDownloader(false);

  @Monitor('webClient.imageIndexToken')
  onWebClientImageIndexTokenChanged(mon: IMonitor) {
    this.gotoWebImageGalleryPage(this.webClient.imageIndex);
  }

  // @Monitor('webClient.isFullScreen')
  // onWebClientIsFullScreenChanged(mon: IMonitor) {
  //
  // }

  @Monitor('storage.themeMode')
  onThemeModeChanged(mon: IMonitor) {
    logger.debug(`theme mode: ${mon.value()?.before} to ${mon.value()?.now}`);
    this.themeMode = this.storage.themeMode;
  }

  @Monitor('storage.currentColorMode')
  onCurrentColorModeChanged(mon: IMonitor) {
    logger.debug(`color mode: ${mon.value()?.before} to ${mon.value()?.now}`);
    this.currentColorMode = this.storage.currentColorMode;
    this.updateWebContentDark(this.isDark());
  }

  @Monitor('storage.webTextZoomRatioIndex')
  onWebTextZoomRatioIndexChanged(mon: IMonitor) {
    logger.debug(`webTextZoomRatioIndex: ${mon.value()?.before} to ${mon.value()?.now}`);
    this.options.textZoomRatio = this.storage.webTextZoomRatio();
  }

  @Monitor('storage.webImageMode')
  onWebImageModeChanged(mon: IMonitor) {
    logger.debug(`webImageMode: ${mon.value()?.before} to ${mon.value()?.now}`);
    this.options.onlineImageAccess = this.storage.isWebImageAccess();
    this.options.imageAccess = this.storage.isWebImageAccess();
  }

  @Monitor('storage.filterListChanged')
  onStorageFilterListChanged(mon: IMonitor) {
    this.webClient.handleFilter();
  }

  @Monitor('storage.openHistoryUrl')
  onStorageOpenHistoryUrlChanged(mon: IMonitor) {
    if (this.storage.openHistoryUrl != null) {
      try {
        this.controller.stop();
      } catch (error) {
        // TODO: Implement error handling.
      }
      try {
        this.controller.loadUrl(this.storage.openHistoryUrl);
      } catch (error) {
        // TODO: Implement error handling.
      }
      this.storage.openHistoryUrl=null;
    }
  }

  //返回按键处理，true表示页面本身处理返回逻辑。false表示使用默认返回逻辑。如果没有返回值，则使用默认返回逻辑
  //5秒内连续三次返回按键，则进入后台
  onBackPress(): boolean {
    let r = this.webClient.backward();
    if (r==false) {
      let ct = new Date() .getTime();
      if (ct - this.lastBackKeyTapTime > 5000) {
        this.lastBackKeyTapTime = ct;
        this.continueBackKeyTapCount = 0;
        r =true;
      }else{
        this.continueBackKeyTapCount +=1;
        if (this.continueBackKeyTapCount > 3) {
          this.lastBackKeyTapTime=ct;
          this.continueBackKeyTapCount =0;
          r =false;
        }else{
          r=true;
        }
      }
    }
    logger.debug('onBackPress:'+r);
    return r;
  }

  // @Monitor('storage.filterList')
  // onStorageFilterChanged(mon: IMonitor) {
  //   logger.debug('dd');
  //   //this.webClient.handleFilter();
  // }
  // @Monitor('storage.currentBreakpoint')
  // onCurrentBreakpointChange(mon: IMonitor) {
  //   logger.debug(`theme mode: ${mon.value()?.before} to ${mon.value()?.now}`);
  //   let value:string|undefined = mon.value()?.now as string;
  //   if(value!==undefined && (value.length>0 ) ){
  //     this.currentBreakpoint = value;
  //     this.storage.currentBreakpoint =value;
  //   }
  // }

  onWillApplyTheme(theme: Theme) {
    logger.debug('Index onWillApplyTheme:',`${this.currentColorMode}`);
  }

  private updateDisplay(){
    try {
      let defaultDisplay = display.getDefaultDisplaySync();
      let rotation = defaultDisplay.rotation; // 获取顺时针旋转角度（0/90/180/270）

      // 根据 rotation 处理业务逻辑
      //显示器旋转度的枚举值。值0表示显示器屏幕顺时针旋转0°。值1表示显示器屏幕顺时针旋转90°。值2表示显示器屏幕顺时针旋转180°。值3表示显示器屏幕顺时针旋转270°。
      switch (rotation) {
        case 0: // 竖屏
          logger.debug('竖屏portrait 0显示器屏幕顺时针旋转0°');
          this.isLandscape =false;
          break;
        case 1: // 竖屏
          logger.debug('横屏landscape 1显示器屏幕顺时针旋转90°');
          this.isLandscape =true;
          break;
        case 2: // 竖屏
          logger.debug('竖屏portrait 2显示器屏幕顺时针旋转180°');
          this.isLandscape =false;
          break;
        case 3: // 竖屏
          logger.debug('横屏landscape 3屏幕顺时针旋转270°。');
          this.isLandscape =true;
          break;
        // case 90: // 横屏（逆时针旋转90°）
        //   logger.debug('横屏（逆时针旋转90°）landscape ');
        //   break;
        // case 180: // 倒竖屏
        //   logger.debug('倒竖屏portrait');
        //   break;
        // case 270: // 横屏（顺时针旋转90°）
        //   logger.debug('横屏（顺时针旋转90°）landscape');
          break;
      }
    } catch (error) {
      // TODO: Implement error handling.
    }
  }

  aboutToAppear() {
    //AppStorage.set('referer', this.site.siteUrl());
    // 注册屏幕旋转监听
    display.on('change', () => {
      this.updateDisplay();
    });
    this.updateDisplay();

    if(this.uiContext==undefined || this.uiContext==null){
      this.uiContext=this.uiContext = this.getUIContext();
    }
    if(this.abilityContext==undefined || this.abilityContext==null){
      this.abilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    }
    this.initDataLoading = true;
    this.webClient.progress=10;

    StrUtil.rawUtf8FileToString(this.uiContext.getHostContext() as common.UIAbilityContext, this.site.startJSFileName(), (context:common.UIAbilityContext,content:string|null)=>{
      this.webClient.progress=30;
      if(content!= null){
        let pre :string  = this.site.startJSPre(env.debug);
        let script:string  = pre +  content;
        let item:ScriptItem  = {
          script:script,
          scriptRules:['*']  //对所有的页面生效
        };
        this.options.javaScriptOnDocumentStart.push(item);
        this.webClient.progress=40;
      }
      StrUtil.rawUtf8FileToString(context, this.site.endJSFileName(), (context:common.UIAbilityContext,script:string|null)=>{
        this.webClient.progress=50;
        if(script!= null){
          let endItem:ScriptItem  = {
            script:script,
            scriptRules:['*']  //对所有的页面生效
          };
          this.options.javaScriptOnDocumentEnd.push(endItem);
          this.webClient.progress=60;
       }
        getDBManager().readFilterList(this.abilityContext!).then(
         (value)=>{
           this.webClient.progress = 100
           this.initDataLoading = false;
           this.webClient.progress = 1;
           this.storage.filterList = value;
         }
       );
     });
    });

    this.breakpointSystem.setOnChanged((bps :string)=>{
      this.currentBreakpoint = bps;
      this.storage.currentBreakpoint = bps;
    }) ;
    this.breakpointSystem.register();
    this.site.isPhone  = AppUtil.isPhoneDevice();
    this.webUrl = this.site.firstLoadUrl();

    //TODO：pc mode 字被放大
    this.options.textAutosizing = false;
    //支持暗黑模式
    this.options.darkMode = WebDarkMode.On;

    this.options.fileAccess = true;
    this.options.textZoomRatio = this.storage.webTextZoomRatio();

    this.options.onlineImageAccess = this.storage.isWebImageAccess();
    this.options.imageAccess = this.storage.isWebImageAccess();

   // this.options.mixedMode = MixedMode.All;

    this.updateWebContentDark(this.isDark());

    this.jsObject.onEvent = (event:number,param: string | undefined | null)=>{
      this.handle_js_event(event,param);
    } ;

    //net check
    this.netMg = new NetConnectionManager((valid: boolean) => {
      this.onNetConnectChanged(valid);
    });
  }

  onNetConnectChanged(connected :boolean): void {
    logger.debug( `internet connect state: ${connected} `);
  }


  onPageShow(): void {
    DelayTasks.addDelayRun("checkUserAgreementState",1000,()=>{
      this.checkUserAgreementState();
    });
  }

  onPageReShow(): void {
    // DelayTasks.addDelayRun("checkUserAgreementState",1000,()=>{
    //   this.checkUserAgreementState();
    // });
  }

  onPageHide(): void {

  }

  private  checkUserAgreementState(){
    if(env.userAgreementState != 0 && (this.checkUserAgreementStateAlertId==null  ||  !DialogHelper.isShowing(this.checkUserAgreementStateAlertId))  ) {
      this.checkUserAgreementStateAlertId=DialogHelper.showAlertDialog({
        primaryTitle:$r('app.string.tips'),
        secondaryTitle: $r('app.string.set_privacy_policy_check_tip'),
        content:$r('app.string.set_privacy_policy_check_content'),
        onAction: (action) => {
          if(action==DialogAction.ONE){
            if (env.userAgreementState != 0) {
              DelayTasks.addDelayRun("checkUserAgreementState",1000,()=>{
                this.checkUserAgreementState();
              });
            }
          }

          if(action==DialogAction.TWO){
            DelayTasks.addDelayRun("push user agreement page",1000,()=>{
              this.navPushPathByName('SetServicePage',null,(name:string,popInfo:PopInfo)=>{
                if (env.userAgreementState != 0) {
                  this.alertCheckUserAgreement();
                }
              });
            });
          }
        }
      });
    }
  }

  private alertCheckUserAgreement(){
    DialogHelper.showAlertDialog({
      uiContext:this.getUIContext(),
      content: $r('app.string.set_privacy_policy_check_ok'),
      onAction: (action) => {
        if (action == DialogAction.CANCEL) {
          DelayTasks.addDelayRun("checkUserAgreementState",1000,()=>{
            this.checkUserAgreementState();
          });
        } else if (action == DialogAction.SURE) {
         env.userAgreementState = 0;
         AppStorageKey.saveUserAgreementState(0);
         DelayTasks.addDelayRun("push user agreement page",500,()=>{
           //TODO:check 通知权限
           //NotificationUtil.authorizeNotification();
         });
        }
      }
    })
  }

  private isDark():boolean {
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  private updateWebContentDark(dark:boolean):void{
     if(dark){
       this.options.forceDarkAccess =true;
     }else{
       this.options.forceDarkAccess =false;
     }
  }

  aboutToDisappear() {
    //主动持久化
    PersistenceV2.save(WebSite);
    this.breakpointSystem.unregister();
    logger.debug('aboutToDisappear');
  }

  build() {
    Navigation(this.navPageStack) {
      if ( this.initDataLoading){
        Column() {
          Progress({ value: this.webClient.progress, total: 100, type: ProgressType.Ring })
            .width(50)
            .height(50)
            .color($r('sys.color.font_on_primary'))          // 进度颜色
            .backgroundColor($r('sys.color.background_primary')) // 背景色
            .style({ strokeWidth: 5 }) // 环宽度
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
      else{
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
            downloader:this.webDownloader
          })
            .layoutWeight(2)

          WebToolBar({accessSiteType:this.site.accessType ,  click: (index:number)=>{
            this.onToolBarEvent(index);
          } })
            .height(this.webClient.isFullScreen ? 0: (this.isLandscape ?56:60) )
            .visibility( this.webClient.isFullScreen ? Visibility.Hidden : Visibility.Visible)
           // .height('8%')
            //.position({ y: '92%' }) // 定位到页面底部90%位置
            //.layoutWeight(2)
            //.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
          //.height(this.uiContext ? this.uiContext.px2vp(200))
          // // 通过全模态接口，绑定模态展示界面MyContentCoverBuilder。transition属性支持自定义转场效果，此处定义了x轴横向入场
          // .bindContentCover($$this.isPresent, this.MyContentCoverBuilder(), {
          //   transition: TransitionEffect.translate({ x: 500 }).animation({ curve: curves.springMotion(0.6, 0.8) })
          // })
        }
        .width('100%')
        //.height('100%') //保证web全屏播放时候可以，全屏
        //.alignItems(HorizontalAlign.Center)
       // .justifyContent(FlexAlign.Start)
       // .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
        //web view 全屏播放视频的时候this.webClient.isFullScreen为true，当旋转到横屏的时候，设置top为0
        .margin({
          top:  ( this.isLandscape || this.webClient.isFullScreen)?0 :(this.uiContext.px2vp(this.statusBarHeight ) ),

          bottom:0
         // bottom: (this.uiContext ? this.uiContext.px2vp(this.statusBarHeight) : 0)

        }) // 顶部避让
      }
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .margin({ bottom: 0 }) // 顶部避让
    // .navBarPosition( this.currentBreakpoint === BreakpointTypeEnum.LG ?
    //   NavBarPosition.Start :
    //   NavBarPosition.End)
    //.hideNavBar(true)
    .mode(NavigationMode.Stack)//不分频幕
    .navDestination(this.myRouter)
    .hideToolBar(true)
    //.toolbarConfiguration(this.tabBuilder)
  }

  // // 自定义底部导航
  // @Builder
  // tabBuilder() {
  //   Row() {
  //     ForEach(['首页', '活动', '我的'], (item: string, index) => {
  //       Column() {
  //         Text(item)
  //           .fontColor(this.selectIndex === index ? Color.Red : Color.Black)
  //           .fontSize(this.selectIndex === index ? 25 : 18)
  //       }
  //       .height("100%")
  //       .layoutWeight(1)
  //       .justifyContent(FlexAlign.End)
  //       .padding({ top: 5, bottom: 5 })
  //       .onClick(() => {
  //         this.selectIndex = index;
  //       })
  //     })
  //   }
  //   .height(50)
  //   .width('100%')
  // }

  //@Consume('webPageStack') webPageStack: NavPathStack = new NavPathStack();;
  //this.webPageStack.pushPathByName('darkModeSetting', null);
  @Builder
  myRouter(name: string, param: Any) {
    if(name === 'AppSettingsPage'){
      AppSettingsPage();
    }
    else if(name === 'darkModeSetting'){
      DarkModeSettingPage();
    }
    else if (name === 'SiteFiltersPage') {
      SiteFiltersPage();
    }
    else if (name === 'RecordHistoryPage') {
      RecordHistoryPage();
    }
    else if (name === 'SetServicePage') {
      SetServicePage();
    }
    else if (name === 'SimpleWebClient') {
      if(param && (param as  string)){
        SimpleWebPage({webUrl: (param as  string) });
      }
    }
  }

  private  navPushPathByName(name:string, param:Any, result?:(name:string,popInfo:PopInfo)=>void ){
    try{
      this.navPageStack.pushPathByName(name, param, (popInfo:PopInfo)=>{
        this.onPageReShow();
        if(result){
          result(name,popInfo);
        }
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

  private  gotoAppFiltersPage():void{
    this.navPushPathByName('SiteFiltersPage',null);
  }
  private  gotoRecordHistoryPage():void{
    this.navPushPathByName('RecordHistoryPage',null);
  }

  private  gotoWebImageGalleryPage(index:number = 1):void{
    let lens :number = this.webClient.imageCount;
    if(lens>0){
      let idx = index;
      if(idx > lens){
        idx = lens -1;
      }
      let iconDataList:IconData[] = this.webClient.getImageUrlList().map(
        (url) =>{
          let img: IconData = new IconData();
          img.url = url;
          return img;
        }
      );

      PicturePreview.open(
        {
          iconDatas:iconDataList,
          index:idx,
          functionData:{
            indicator: true,
            backIcon: undefined,
            saveIcon: undefined,
            saveAlbum: true,
            isClickClose: true,
            isNavigationImage: true,
            continueTime: 3000,
            isBack: true,
            isNavSave:true,
          },
          styleData:{
            isMaskGradient: true,
            isTransition: true,
            isIndicatorColorVariation: true,
            isZoom: true,
            saveLocation: FlexAlign.End,
            maxScale: 3
          },
          toolBuild:undefined,
          listener:{
            onChange: (index: number, data: IconData) => {
              logger.debug('on change index',''+index );
              this.webClient.imageIndex = index;
            },
            onLongPress: (index: number, iconData: IconData) => {
              //返回false 不处理。让组建自己处理
              return false;
            },
          },
          downloadIntercept: this.webDownloader
        }
      );

      // PicturePreview.open({
      //   iconDatas: iconDatas,
      //   index: 0,
      // });

    }
  }

  private copyWebSiteInfo(titleOrLink:boolean):void{
    let content = titleOrLink? this.site.title:(this.site.lastUrl.length>5?this.site.lastUrl:this.site.startUrl);
    AppUtil.copyTextToPasteboard(content,(success:boolean)=>{
      let r =  success==true?$r('app.string.copy_success',2):$r('app.string.copy_failed',2);
      try {
        let testStr = this.abilityContext!.resourceManager.getStringSync(r.id);
        ToastUtil.showToast(this.uiContext!, testStr);
      } catch (error) {
      }
    });
  }

  // private testDownloadImage(){
  //   // let uiContext: UIContext = this.getUIContext();
  //   // BCDownloader.getInstance().start(uiContext,
  //   //   'https://static.chiphell.com/forum/202610/08/223908bohlmboqvcabh4qa.jpg',
  //   //   'https://www.chiphell.com/thread-2906782-1-1.html',
  //   // );
  //   //
  //   this.controller.startDownload('https://static.chiphell.com/forum/202610/08/223908bohlmboqvcabh4qa.jpg');
  // }

  private  onToolBarEvent(type:number|MPIType){
    switch (type){
      case 0: {
       //  this.testDownloadImage();
         this.webClient.backwardToNoThread();
         //getDBManager().test();
        break;
      }
      case 1:
        this.webClient.gotoHome();
        //goto home
        break;
      case 2:
        this.webClient.backward();
        break;
      case 3: {
        this.webClient.goRefresh();
      }
        break;
      case MPIType.SETTING:
        this.gotoAppSettingsPage();
        break;
      case MPIType.LOGIN:
        this.webClient.gotoLogin();
        break;
      case MPIType.FORUM:
        this.webClient.gotoForum();
        break;
      case MPIType.FILTER:
      this.gotoAppFiltersPage();
        break;
      case MPIType.BROWSER:
        this.webClient.gotoOtherBrowser();
        break;

      case MPIType.HISTORY:
        {
          this.gotoRecordHistoryPage();
          break;
        }
      case MPIType.UA:
        {
          this.webClient.switchUserAgent();
          break;
        }
      case MPIType.COPY:
        {
          //弹窗2选一
          DialogHelper.showBottomSheetDialog({
            sheets: [$r('app.string.copy_title'), $r('app.string.copy_link')],
            onAction: (index) => {
              this.copyWebSiteInfo(index==0);
            }
          })
        }
        break;
      case MPIType.GALLERY:
        {
           this.gotoWebImageGalleryPage(this.webClient.imageIndex);
        }
        break;
    }
  }

  //{"src":"arkweb-error://webdata/"}
  private handle_js_event(event:number,param: string | undefined | null):void
  {
    if (event==1) {
      this.webClient.saveToFavorites();
    }else if (event==2) {
      if (param == null || param == undefined || param.length ==0 || param=='{}' || param=='{"src":"arkweb-error://webdata/"}') {
        this.webClient.backToUrl = undefined;
      }else{
        try {
          let backInfo : Map<string, Object>=  JSONUtil.jsonToMap(param);
          let src =  backInfo.get('src') as  string;
          let url =  backInfo.get('url') as  string;
          //backForumInfo: {"src":"data:text/html;ch
          if (url && (url.startsWith( this.site.siteUrl(),0)) && (src == this.site.lastUrl || src == this.site.startUrl)) {
            this.webClient.backToUrl =url;
            logger.debug('set back to url:', url);
          }
        }catch (e) {
        }
      }
    }
  }

//
//   @Builder
//   MyContentCoverBuilder() {
//     Column() {
//       ThumbnailPicture()
//       Row() {
//         Text('选择乘车人')
//           .fontSize(20)
//           .fontColor(Color.White)
//           .width('100%')
//           .textAlign(TextAlign.Center)
//           .padding({ top: 30, bottom: 15 })
//       }
//       .backgroundColor(0x007dfe)
//
//       Row() {
//         Text('+ 添加乘车人')
//           .fontSize(16)
//           .fontColor(0x333333)
//           .margin({ top: 10 })
//           .padding({ top: 20, bottom: 20 })
//           .width('92%')
//           .borderRadius(10)
//           .textAlign(TextAlign.Center)
//           .backgroundColor(Color.White)
//       }
//
//       Column() {
//         ForEach(this.personList, (item: PersonList, index: number) => {
//           Row() {
//             Column() {
//               if (index % 2 == 0) {
//                 Column()
//                   .width(20)
//                   .height(20)
//                   .border({ width: 1, color: 0x007dfe })
//                   .backgroundColor(0x007dfe)
//               } else {
//                 Column()
//                   .width(20)
//                   .height(20)
//                   .border({ width: 1, color: 0x007dfe })
//               }
//             }
//             .width('20%')
//
//             Column() {
//               Text(item.name)
//                 .fontColor(0x333333)
//                 .fontSize(18)
//               Text(item.cardNum)
//                 .fontColor(0x666666)
//                 .fontSize(14)
//             }
//             .width('60%')
//             .alignItems(HorizontalAlign.Start)
//
//             Column() {
//               Text('编辑')
//                 .fontColor(0x007dfe)
//                 .fontSize(16)
//             }
//             .width('20%')
//           }
//           .padding({ top: 10, bottom: 10 })
//           .border({ width: { bottom: 1 }, color: 0xf1f1f1 })
//           .width('92%')
//           .backgroundColor(Color.White)
//         })
//       }
//       .padding({ top: 20, bottom: 20 })
//
//       Text('确认')
//         .width('90%')
//         .height(40)
//         .textAlign(TextAlign.Center)
//         .borderRadius(10)
//         .fontColor(Color.White)
//         .backgroundColor(0x007dfe)
//         .onClick(() => {
//           this.isPresent = !this.isPresent;
//         })
//     }
//     .size({ width: '100%', height: '100%' })
//     .backgroundColor(0xf5f5f5)
//   }
 }
