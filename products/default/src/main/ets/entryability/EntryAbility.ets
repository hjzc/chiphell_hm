//数据流转接口导入
import {
  abilityAccessCtrl,
  AbilityConstant,
  bundleManager,
  ConfigurationConstant,
  Permissions,
  UIAbility,
  Configuration,
  Want
} from '@kit.AbilityKit';
import { window, ThemeControl,AppStorageV2 } from '@kit.ArkUI';
import { gAppTheme } from 'uicomponents';
import { AppUtil } from '../utils/AppUtil';
import { ZzjWebHelper } from '../web/Zzj/ZzjWebHelper';
import { logger } from 'utils';
import { AppStorageKey } from '../common/AppStorageKey';
import BuildProfile from 'BuildProfile';
import { DialogHelper } from 'dialog';
import { env } from '../Storage/ZjEnv';
import { ZjStorage } from '../Storage/ZjStorage';
import { RegexUtil } from '../utils/RegexUtil';
import { getDBManager } from '../common/DBManager';
import { PicturePreviewDataModel } from 'imagegallery/src/main/ets/model/PicturePreviewDataModel';
import { getSiteManager } from '../model/Site';
import { fileIo } from '@kit.CoreFileKit';


export default class EntryAbility extends UIAbility {
  private mainWindow: window.Window | null = null;
  storage: ZjStorage = AppStorageV2.connect(ZjStorage, 'storage', () => new ZjStorage())!;

  private initPrefData():void{

    /* 需提前配置自定义编译参数（参考官方文档）
    补充说明：配置文件的优先级 应用是否支持调试由 app.json5 和 build-profile.json5 共同决定：
    app.json5 中配置 debug 字段：2
    {
        "app": {
        "debug": true // true支持调试，false不支持
      }
    }
    若未配置 app.json5 的 debug 字段，则根据 build-profile.json5 的 debuggable 字段判断：
    非Release编译模式：debuggable 默认为 true（支持调试）。
    Release编译模式：debuggable 默认为 false（不支持调试）。
    */
    let kDebug:boolean  = false;

    if (BuildProfile.DEBUG ) {
      kDebug=true;
      console.log('Debug模式');
    } else {
      console.log('Release模式');
    }
    env.debug =kDebug;
    logger.init(kDebug);
    AppUtil.init(this.context);
    getSiteManager().init();
    getDBManager().initDb(this.context);
    ZzjWebHelper.init(this.context, kDebug);
    DialogHelper.setDefaultConfig((config) => {
      config.uiAbilityContext = this.context;
      config.autoCancel = false; //点击遮障层时，是否关闭弹窗，true表示关闭弹窗。
      config.backCancel = false; //点击返回键或手势返回时，是否关闭弹窗；实现onWillDismiss函数时，该参数不起作用。
      config.actionCancel = true; //点击操作按钮时，是否关闭弹窗。false表示不关闭弹窗。
      config.alignment = DialogAlignment.Center; //弹窗的对齐方式。
      config.offset = { dx: 0, dy: 0 }; //弹窗相对alignment所在位置的偏移量。默认值：{ dx: 0, dy: 0 }
      config.maskColor = $r('app.color.harmony_dialog_maskColor'); //自定义蒙层颜色。默认值 0x33000000 0x11000000
      config.backgroundColor =$r('sys.color.background_primary');   // Color.White; //弹窗背板颜色。默认值：Color.White
      config.backgroundBlurStyle = BlurStyle.COMPONENT_ULTRA_THICK ; //弹窗背板模糊材质 NONE
      config.cornerRadius = 20; //设置背板的圆角半径。可分别设置4个圆角的半径。
      config.borderWidth = 1;
      config.borderColor =$r('sys.color.comp_divider');
      // config.maskRect={ x: 'auto', y: 'auto', width: 'auto', height: 'auto' };

      config.title = $r("app.string.dialog_tip"); //弹框标题
      config.primaryButton = $r("app.string.btn_cancel"); //弹框左侧按钮。
      config.secondaryButton = $r("app.string.btn_sure"); //弹框右侧按钮。
      config.imageRes = undefined; //TipsDialog用到，展示的图片。
      config.imageSize = { width: '64vp', height: '64vp' }; //TipsDialog用到，自定义图片尺寸。默认值：64*64vp

      config.loading_loadSize = 60; //加载动画或进度条的大小
      config.loading_loadColor =$r('sys.color.background_primary');// Color.White; //加载动画或进度条的颜色
      config.loading_content = ''; //加载动画的提示文字
      config.loading_fontSize = 16; //文字大小
      config.loading_fontColor =$r('sys.color.font_on_primary');// Color.White; //文字颜色
      config.loading_backgroundColor =$r('app.color.harmony_dialog_loading_backgroundColor'); //'#CC094CD1'; //背景颜色，八位色值前两位为透明度
      config.loading_borderRadius = 10; //背景圆角

      config.toast_fontSize = 16; //文字大小
      config.toast_fontColor =$r('sys.color.font_on_primary');// Color.White; //文字颜色
      config.toast_backgroundColor =$r('app.color.harmony_dialog_toast_backgroundColor');// '#CC56D866'; //背景颜色，建议八位色值前两位为透明度
      config.toast_alignment = Alignment.Center; //土司居中显示
      config.toast_borderRadius = 8; //背景圆角
      config.toast_padding = { left: 16, right: 16, top: 12, bottom: 12 }; //Padding
      config.toast_imageSize = { width: 45, height: 45 }; //Tip图片尺寸。默认值：45*45vp
      config.toast_duration = 2000; //显示时长(1500ms-10000ms)
      config.toast_durationLong = 5000; //显示时长
    });

    this.storage.webTextZoomRatioIndex= AppStorageKey.getWebTextZoomRatioIndex();
    this.storage.webImageMode= AppStorageKey.getWebImageMode();
    env.userAgreementState=AppStorageKey.getUserAgreementState();

  }

  //系统默认判断规则
  //     如果应用调用上述setColorMode接口主动设置了深浅色，则以接口效果优先。
  //     应用没有调用setColorMode接口时：
  //     如果应用工程dark目录下有深色资源，则系统组件在深色模式下会自动切换成为深色。
  //     如果应用工程dark目录下没有任何深色资源，则系统组件在深色模式下仍会保持浅色体验。
  private setAppThemeMode() {
    //如果应用全部都是由系统组件/系统颜色开发，且想要跟随系统切换深浅色模式时，请参考以下示例修改代码来保证应用体验。会调用 onConfigurationUpdate
    //this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    let rc :ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    let sv = AppStorageKey.getThemeModeNumber();
    if (sv == null) {
      //在 AbilityStage 的 onCreate() 生命周期中获取APP当前的颜色模式并保存到 AppStorage。
      AppStorageKey.saveThemeMode(rc);
    }else{
      rc = AppStorageKey.convertColorMode(sv);
    }
    try {
      env.themeMode= rc;
      this.storage.themeMode = rc;
      this.context.getApplicationContext().setColorMode(rc);
      logger.debug('set theme mode:', JSON.stringify(rc) ?? '');
    } catch (error) {
      logger.error('Failed to set theme mode. Cause: ', JSON.stringify(error));
    }
  }

  // private debug_printColorMode(){
  //   const  cm = this.context.config.colorMode;
  //   logger.debug('the context.config.colorMode:', JSON.stringify(cm) ?? '');
  // }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    env.language = this.context.config.language;
    if(this.context.config.colorMode !== undefined){
      env.currentColorMode = this.context.config.colorMode;
    }
    env.fontSizeScale = this.context.config.fontSizeScale;
    env.fontWeightScale = this.context.config.fontWeightScale;

    if(this.storage.currentColorMode != env.currentColorMode){
      this.storage.currentColorMode = env.currentColorMode;
    }

    env.bundleName=  this.context.abilityInfo.bundleName;

    let resDir: string = this.context.resourceDir;
    // // 直接检查证书文件在设备上是否存在 /data/storage/el1/bundle/default/resources/resfile/domainCaCert/sectigo_chain.pem
    let certPath: string = `${resDir}/domainCaCert/sectigo_chain.pem`;
   // this.updateCAPaths('root',certPath);
    if(AppUtil.fileExist(certPath)){
      this.updateCAPaths('static.chiphell.com',certPath);
    }
    // let exist: boolean = fileIo.accessSync(certPath);

    //页面中访问
    // let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // let resDir: string = context.resourceDir;

    this.initPrefData();

    try {

      //this.debug_printColorMode();
      this.setAppThemeMode();
      //this.debug_printColorMode();

    } catch (err) {
      logger.error('Failed to set colorMode. Cause:', JSON.stringify(err));
    }

    //在上文中介绍到ohos.permission.DISTRIBUTED_DATASYNC权限为user_grant类型的权限，
    // 该类型权限不仅需要在安装包中申请权限，还需要在应用动态运行时请求用户授权。在用户手动允许授权后，应用才会真正获取相应权限，
    // 从而成功访问操作目标对象。实现的思路是使用checkAccessToken()方法获取到当前的授权状态，
    // 如果未授权就使用requestPermissionsFromUser()方法来向用户申请权限。
    this.checkDataSyncPermissions();
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      //之后当是迁移启动应用时， 需要显式地调用restoreWindowStage()方法手动地去触发页面的恢复，这样页面才能正常显示。
      try {
        this.context.restoreWindowStage(new LocalStorage());
      } catch (error) {
        logger.error('restoreWindowStage. Cause: ', JSON.stringify(error));
      }
    }
    logger.info('Ability onCreate');
  }

  //函数被调用是： 系统修改了显示的主题模式 或者用户主动设置 this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
  onConfigurationUpdate(newConfig: Configuration): void {
    //在 AbilityStage 的 onConfigurationUpdate() 生命周期中获取最新变更的颜色模式并刷新到 AppStorage。
    super.onConfigurationUpdate(newConfig);
    // 主题更新了
    //AppStorage.setOrCreate('currentColorMode', newConfig.colorMode);
    if(newConfig.colorMode!== undefined){
      //if(env.colorMode != newConfig.colorMode){
        env.currentColorMode = newConfig.colorMode;
      //}
     // if(this.storage.currentColorMode != env.colorMode){
        this.storage.currentColorMode = newConfig.colorMode;
     // }
    }
    logger.info('the newConfig.colorMode is:', JSON.stringify(env.currentColorMode ) ?? '');
  }

  onMemoryLevel(level: AbilityConstant.MemoryLevel): void{
    super.onMemoryLevel(level);
  }

  onDestroy(): void {
    logger.info('Ability onDestroy');
  }


  //当应用进入横屏状态时，系统默认会隐藏状态栏以提供更大的内容展示区域。这是鸿蒙系统的设计规范，尤其在视频播放、游戏等全屏场景中常见。
  // 在横屏操作后调用此方法
  private showStatusBar() {
     // const win = window.getLastWindow(this.context);
      this.mainWindow?.setWindowSystemBarEnable(['status']).then(()=>{

      }).catch(() => {
        // TODO: Implement error handling.
        logger.error('showStatusBar error: ');
      }); // 显式启用状态栏
  }

  private updateCAPaths(domain:string, caPath:string) {
    env.updateCAPaths(domain, caPath);
    PicturePreviewDataModel.updateCAPaths(domain, caPath);
  }

  ///不只用这种方式，pem文件放在resfile 目录下更好
  private  installDomainPemAndSets(pemName:string, dom:string) {
    let capath = AppUtil.InstallPemFileToSandbox(this.context,pemName,BuildProfile.DEBUG);
    if(capath.length>4){
      // /data/storage/el1/base/haps/default/files/certs/static-chiphell-com.pem
      this.updateCAPaths(dom,capath);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    logger.info( 'Ability onWindowStageCreate');
    // 获取主窗口实例
    try {
      this.mainWindow = windowStage.getMainWindowSync();
    } catch (error) {
      // TODO: Implement error handling.
    }
    if (!this.mainWindow) {
      logger.error('获取主窗口失败');
      return;
    }

   this.mainWindow.setWindowLayoutFullScreen(true).then(()=>{
     // this.mainWindow?.setSpecificSystemBarEnabled('status', true);
     // this.mainWindow?.setSpecificSystemBarEnabled('navigationIndicator', true);
     logger.info('窗口已设置为全屏布局');
   }).catch(() => {


   });

    try {
      const rect = this.mainWindow.getWindowProperties();
      const windowHeight = rect.windowRect.height; // 窗口总高度（px）
      env.windowHeight = windowHeight;
      logger.info(`Window height: ${windowHeight}`);

    } catch (error) {
      // TODO: Implement error handling.
    }


    //zorro 请求全屏
   // this.requestFullScreen(windowStage, this.context);
    //已经选中一个site，则直接进入index page
    let startPage ="pages/Index";// 'pages/SiteManagerPage';
    windowStage.loadContent(startPage, (err) => {
      if (err.code) {
        logger.error( 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      ///zorro 保存一个全局的 ui context
      try {
        if(this.mainWindow!=null){
         // let windowClass = this.mainWindow;// windowStage.getMainWindowSync();
          AppStorage.setOrCreate('UIContext',this.mainWindow.getUIContext());
        }
      } catch (error) {
        // TODO: Implement error handling.
      }
      // 在onWindowStageCreate()方法中setDefaultTheme
      //设置windows 主题
      ThemeControl.setDefaultTheme(gAppTheme);
      // 初始化避让区数据监听

     // @Local prop: Storage = PersistenceV2.connect(Storage, () => new Storage())!;
      this.initAvoidAreaListener();

      // if(BuildProfile.DEBUG){
      //   ////data/storage/el1/bundle/default/resources/resfile/sectigo_chain.pem
      //   let scpath = AppUtil.getEntryResourceResFilePath('default','sectigo_chain.pem');
      //   if(scpath){
      //     AppUtil.readTextSync(scpath);
      //   }
      // }

     // this.installDomainPemAndSets('sectigo_chain.pem','static.chiphell.com');

     // AppUtil.InstallPrivateCertificate(this.context,'static-chiphell-com.pem','static.chiphell.com');

      //PersistenceV2必须与UI实例关联，持久化操作需在UI实例初始化完成后调用（即loadContent回调触发后）。
      // let v= PersistenceV2.connect(ZjStorage,'storage', () => this.storage);
      // PersistenceV2.save(ZjStorage);

      // 推荐在 DEBUG 模式下使用 - 动态加载
      // # 查看模拟器设备
      //   > hdc list targets   # 输出: 127.0.0.1:5555
      // # 转发端口 fport tcp:<localPort> tcp:<serverPort>
      //   hdc -t 127.0.0.1:5555 fport tcp:7777 tcp:7777
      // # 输出: Forwardport result:OK 表示成功  http://127.0.0.1:7777

     // // oh-package.json5 增加依赖： "@cxy/sandboxfinder": "^1.0.1",
     //  if (BuildProfile.DEBUG) {
     //    import('@cxy/sandboxfinder').then(async (ns: ESObject) => {
     //      // 默认绑定到端口 7777
     //      ns.SandboxFinder.run()
     //    });
     //    // 避免服务挂起，设置不息屏
     //    windowStage.getMainWindowSync().setWindowKeepScreenOn(true)
     //  }


      // 推荐在 DEBUG 模式下使用 - 动态加载。"@hadss/debug-db": "^1.0.0-rc.11"
      // if (BuildProfile.DEBUG) {
      //   // # 查看模拟器设备
      //   //   > hdc list targets   # 输出: 127.0.0.1:5555
      //   // # 转发端口 fport tcp:<localPort> tcp:<serverPort>
      //   //   hdc -t 127.0.0.1:5555 fport tcp:8080 tcp:8080
      //   // # 输出: Forwardport result:OK 表示成功
      //   // 转发成功后，访问： http://127.0.0.1:8080/index.html , 如果无法访问，请排查下是否有开启网络代理工具，建议关闭后再试试
      //   import('@hadss/debug-db').then(async (ns: ESObject) => {
      //     await ns.DebugDB.initialize(this.context, { port: 8080, defaultStart: true });
      //   });
      // }

      logger.info( 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    logger.info( 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    logger.info('Ability onForeground');

    //从后台回来，推出一个EntryAbility
    // let want: Want = {
    //   bundleName: this.context.abilityInfo.bundleName??'com.example.myapplication',
    //   abilityName: 'EntryAbility'
    // };
    //    let options: StartOptions = {
    //       displayId: 0,
    //     };
    // try {
    //   this.context.startAbility(want, StartOptions,(err: BusinessError) => {
    //     if (err.code) {
    //       // 处理业务逻辑错误
    //       console.error(`startAbility failed, code is ${err.code}, message is ${err.message}`);
    //       return;
    //     }
    //     // 执行正常业务
    //     console.info('startAbility succeed');
    //   });
    // } catch (err) {
    //   // 处理入参错误异常
    //   let code = (err as BusinessError).code;
    //   let message = (err as BusinessError).message;
    //   console.error(`startAbility failed, code is ${code}, message is ${message}`);
    // }


  }

  onBackground(): void {
    // Ability has back to background
    logger.info( 'Ability onBackground');
  }

  //返回true表示UIAbility将会被移到后台不销毁，返回false表示UIAbility将正常销毁。
  onBackPressed(): boolean {
    return true;
  }

  //数据流转，源端接口实现
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult | Promise<AbilityConstant.OnContinueResult> {
    return AbilityConstant.OnContinueResult.AGREE;
  }

  //多设备数据流转的权限申请
  async checkDataSyncPermissions(): Promise<void> {
    const permissions: Array<Permissions> = ['ohos.permission.DISTRIBUTED_DATASYNC'];
    const accessManager = abilityAccessCtrl.createAtManager();
    try {
      const bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION;
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleFlags);
      const grantStatus = await accessManager.checkAccessToken(bundleInfo.appInfo.accessTokenId, permissions[0]);

      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        accessManager.requestPermissionsFromUser(this.context, permissions).catch(() => {
          // TODO: Implement error handling.
        });
      }
    } catch (err) {
      logger.error('EntryAbility', 'checkPermissions', `Catch err: ${err}`);
      return;
    }
  }

  //https://developer.huawei.com/consumer/cn/blog/topic/03190979953248148
  // private  requestFullScreen(windowStage: window.WindowStage, context: Context): void {
  //   // let windowClass = windowStage.getMainWindowSync();
  //   //  windowClass.setWindowLayoutFullScreen(true).then(() => {
  //   //    console.info("窗口已设置为全屏布局");
  //   //  });
  //   windowStage.getMainWindow((err: BusinessError, data: window.Window) => {
  //     if (err.code) {
  //       return;
  //     }
  //     let windowClass: window.Window = data;
  //     windowClass.setWindowLayoutFullScreen(true).catch(() => {
  //       logger.info( '窗口已设置为全屏布局');
  //     });
  //   });
  // }

  // 初始化避让区监听
  private initAvoidAreaListener() {
    if (!this.mainWindow) return;
    // 初始获取避让区数据
    this.updateAvoidAreaData();
    // 监听避让区变化
    this.mainWindow.on('avoidAreaChange', (data) => {
      console.info(`避让区变化: ${JSON.stringify(data)}`);
      if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
       // AppStorage.setOrCreate('statusBarHeight', data.area.topRect.height);
        //AppStorageV2.
        env.statusBarHeight = data.area.topRect.height;
        this.storage.statusBarHeight = data.area.topRect.height;

        logger.debug(`TYPE_SYSTEM 获取避让区数据:statusBarHeight= ${env.statusBarHeight} `);
      }
      else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
        env.navBarHeight = data.area.bottomRect.height;
        env.bottomRectHeight=data.area.bottomRect.height;
        this.storage.navBarHeight = data.area.bottomRect.height;
        this.storage.bottomRectHeight = data.area.bottomRect.height;
        logger.debug(`TYPE_NAVIGATION_INDICATOR 获取避让区数据:navBarHeight= ${env.navBarHeight} `);
        //AppStorage.setOrCreate('navBarHeight', data.area.bottomRect.height);
      }
    });
  }

  // 更新避让区数据到全局存储
  private updateAvoidAreaData() {
    if (!this.mainWindow) return;
    try {
      // 获取状态栏区域
      const systemArea = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
    //  AppStorage.setOrCreate('statusBarHeight', systemArea.topRect.height);
      env.statusBarHeight = systemArea.topRect.height;
      this.storage.statusBarHeight = systemArea.topRect.height;
      logger.debug(`TYPE_SYSTEM 获取避让区数据:statusBarHeight= ${env.statusBarHeight} `);

      // 获取导航栏区域
      const navArea = this.mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      env.navBarHeight = navArea.bottomRect.height;
      env.bottomRectHeight=navArea.bottomRect.height;
      this.storage.navBarHeight = navArea.bottomRect.height;
      this.storage.bottomRectHeight = navArea.bottomRect.height;
      logger.debug(`TYPE_NAVIGATION_INDICATOR 获取避让区数据:navBarHeight= ${env.navBarHeight} `);
      // AppStorage.setOrCreate('navBarHeight', navArea.bottomRect.height);

    } catch (err) {
      logger.error(`获取避让区数据失败: ${JSON.stringify(err)}`);
    }
  }

  // // 切换到窗口全屏布局(不隐藏避让区)模式
  // public switchToFullScreenNormal() {
  //   if (!this.mainWindow) return;
  //   // 开启全屏布局
  //   this.mainWindow.setWindowLayoutFullScreen(true).then(() => {
  //     // 显示状态栏和导航栏
  //     this.mainWindow?.setSpecificSystemBarEnabled('status', true);
  //     this.mainWindow?.setSpecificSystemBarEnabled('navigationIndicator', true);
  //     // 加载对应页面
  //     this.context?.getWindowStage().then((stage) => {
  //       stage.loadContent(pageMap.FULL_SCREEN_NORMAL);
  //     });
  //   });
  // }
  //
  // // 切换到窗口全屏布局(隐藏避让区)模式
  // public switchToFullScreenHidden() {
  //   if (!this.mainWindow) return;
  //
  //   // 开启全屏布局
  //   this.mainWindow.setWindowLayoutFullScreen(true).then(() => {
  //     // 隐藏状态栏和导航栏
  //     this.mainWindow?.setSpecificSystemBarEnabled('status', false);
  //     this.mainWindow?.setSpecificSystemBarEnabled('navigationIndicator', false);
  //     // 加载对应页面
  //     this.context?.getWindowStage().then((stage) => {
  //       stage.loadContent(pageMap.FULL_SCREEN_HIDDEN);
  //     });
  //   });
  // }
  //
  // // 切换到组件安全区模式
  // public switchToSafeAreaMode() {
  //   if (!this.mainWindow) return;
  //   // 关闭全屏布局(使用默认安全区布局)
  //   this.mainWindow.setWindowLayoutFullScreen(false).then(() => {
  //     // 显示状态栏和导航栏
  //     this.mainWindow?.setSpecificSystemBarEnabled('status', true);
  //     this.mainWindow?.setSpecificSystemBarEnabled('navigationIndicator', true);
  //     // 设置窗口背景色(用于安全区方案)
  //     this.mainWindow?.setWindowBackgroundColor('#d5d5d5');
  //     // 加载对应页面
  //     this.context?.getWindowStage().then((stage) => {
  //       stage.loadContent(pageMap.SAFE_AREA_MODE);
  //     });
  //   });
  // }



}

