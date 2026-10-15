
import { common } from '@kit.AbilityKit';
import { env } from '../Storage/ZjEnv';
import { ZjStorage } from '../Storage/ZjStorage';
import { AppStorageV2 } from '@ohos.arkui.StateManagement';
import { NavBarItemData, SetNavItemView } from '../view/SetNavItemView';
import { BreakpointType, logger } from 'utils';
import { BusinessError } from '@kit.BasicServicesKit';

import { SettingsModel } from '../model/SetingsModel';
import { LoadingView } from '../view/LoadingView';
import { DialogAction, DialogHelper } from 'dialog';
import { AppStorageKey } from '../common/AppStorageKey';

@ComponentV2
export struct AppSettingsPage {
  @Consumer('navPageStack') navPageStack: NavPathStack = new NavPathStack();
  @Local statusBarHeight: number = env.statusBarHeight;
  @Local storage: ZjStorage = AppStorageV2.connect(ZjStorage, 'storage', () => new ZjStorage())!;
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private uiContext: UIContext | null = null;
  @Local navBarList: NavBarItemData[] = [];
  //@Local webTextZoomRatioIndex:number = this.storage.webTextZoomRatioIndex;
  private  clearAll :boolean = false;
  loadingView:LoadingView = new LoadingView()

  @Monitor('storage.themeMode')
  onThemeModeChanged(mon: IMonitor) {
    this.navBarList[1].trailing = this.storage.isDark() ? $r('app.string.dark_mode') :$r('app.string.light_mode');
  }

  aboutToAppear(): void {
    this.uiContext = this.getUIContext();
    this.navBarList.push(
      new NavBarItemData( 0 , '',  $r('app.string.clean_cache'), '')
    );
    this.navBarList.push( new NavBarItemData(1,'',  $r('app.string.theme'),this.storage.isDark() ?$r('app.string.dark_mode') :$r('app.string.light_mode') ));
    this.navBarList.push( new NavBarItemData(2,'',  $r('app.string.theme_font_size'),this.storage.webTextZoomRatioDesc() ));
    this.navBarList.push( new NavBarItemData(3,'',  $r('app.string.web_set_image_mode'),this.storage.webImageModeDesc() ));
    this.navBarList.push( new NavBarItemData(4,'',  $r('app.string.web_record'),'' ));
    this.navBarList.push( new NavBarItemData(5,'',  $r('app.string.web_replay_user_filter'),'' ));
    this.navBarList.push( new NavBarItemData(6,'',  $r('app.string.set_terms_of_service'),'' ))

  }

  aboutToDisappear() {

  }

  build() {
    NavDestination() {
      Column() {
        List({ space: 12 }) {
          ForEach(this.navBarList, (item: NavBarItemData, index: number) => {
            // if(index == 1){
            //   item.trailing = this.storage.isDark() ?'暗色':'浅色';
            // }
            SetNavItemView( { item:item,click: (index:number)=>{
                this.onClickSetNavItemView(index);
            }});

          }, (item: NavBarItemData, index: number) =>`${item}-${index}` )
        }
        .width('100%')
        .height('100%')
        //设置List组件在sm、md、lg断点下List组件分别呈1列、1列、2列显示。依然可以使用List的lanes属性结合断点来实现效果。
        .lanes(new BreakpointType<number>({ sm:1, md: 1, lg: 2, xl: 2 }).getValue(this.storage.currentBreakpoint))
        .borderRadius(16)
        .padding({ left: 12,top:12, right: 12 })
      }
      .padding({ left: 16, right: 16 })

    }
    .title($r('app.string.app_settings'))
    .backgroundColor($r('sys.color.background_primary'))
    .margin({ top: this.uiContext ? this.uiContext.px2vp(this.statusBarHeight) : 0 ,bottom:0 }) // 顶部避让

    .onBackPressed(()=>{
      return false;
    });
  }

  onClickSetNavItemView(index:number):void{
    switch (index){
      case 0:{
        //弹窗确认
        DialogHelper.showConfirmDialog({
          checkTips: $r('app.string.page_settings_clean_cache_check_tips'),
          content: $r('app.string.page_settings_clean_cache_check_content'),
          isChecked:this.clearAll,
          onCheckedChange: (check) => {
              this.clearAll= check;
          },
          onAction: (action) => {
            if(action==DialogAction.TWO){
              this.loadingView.showLoading();
              SettingsModel.clearCache(this.context , this.clearAll ,()=>{
                setTimeout(() => {
                  this.loadingView.hide();
                }, 1000)
              });
            }
          }
        });

        // DialogHelper.showAlertDialog({
        //   uiContext:this.getUIContext(),
        //   content: "确定清除应用缓存文件吗？",
        //   onAction: (action) => {
        //     if (action == DialogAction.SURE) {
        //       this.loadingView.showLoading()
        //       SettingsModel.clearCache(()=>{
        //         setTimeout(() => {
        //           this.loadingView.hide()
        //         }, 1000)
        //       });
        //     }
        //   }
        // })


      }
        break;
      case 1:
        {
          try{
            this.navPageStack.pushPathByName('darkModeSetting', null);
          }catch(error){
            logger.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          }
        }
        break;
      case 2:
        {
          //自定义标题，内容，底部弹出框
          let descList =  ZjStorage.webTextZoomRatioDescList()
          DialogHelper.showSelectDialog({
            title:$r('app.string.web_font_set_alert_desc') ,
           // content: "选择文本大小",
            selectedIndex: this.storage.webTextZoomRatioIndex, //设置选中索引
            autoCancel: true, //点击遮障层时，不关闭弹窗
            confirm:$r('app.string.confirm'),
            radioContent: [
              {
                title: descList[0],
                action: () => {
                }
              },
              {
                title: descList[1],
                action: () => {
                }
              },
              {
                title: descList[2],
                action: () => {
                }
              }],
            onCheckedChanged: (index) => {

            },
            onAction: (action, dialogId, value) => {
              let index:number = parseInt(value);
              if((index>=0 )&&( index<=2) && (index!= this.storage.webTextZoomRatioIndex)){
                AppStorageKey.saveWebTextZoomRatioIndex(index);
                this.storage.webTextZoomRatioIndex = index;
                this.navBarList[2].trailing =  this.storage.webTextZoomRatioDesc();
              }
            }
          })
        }
        break;
      case 3:
        {
          //自定义标题，内容，底部弹出框
          let descList =  ZjStorage.webImageModeDescList()
          DialogHelper.showSelectDialog({
            title:$r('app.string.web_set_image_mode') ,
            // content: "选择文本大小",
            selectedIndex: this.storage.webImageMode, //设置选中索引
            autoCancel: true, //点击遮障层时，不关闭弹窗
            confirm:$r('app.string.confirm'),
            radioContent: [
              {
                title: descList[0],
                action: () => {
                }
              },
              {
                title:descList[1],
                action: () => {
                }
              }],
            onCheckedChanged: (index) => {

            },
            onAction: (action, dialogId, value) => {
              let index:number = parseInt(value);
              if((index>=0 )&&( index<=1) && (index!= this.storage.webImageMode)){
                AppStorageKey.saveWebImageMode(index);
                this.storage.webImageMode = index;
                this.navBarList[3].trailing =descList[index];
              }
            }
          })
        }
        break;
      case 4:
        try{
          this.navPageStack.pushPathByName('RecordHistoryPage', null);
        }catch(error){
          logger.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
        }
        break;
      case 5:
        try{
          this.navPageStack.pushPathByName('SiteFiltersPage', null);
        }catch(error){
          logger.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
        }
        break;
     case 6:
       try{
         this.navPageStack.pushPathByName('SetServicePage', null);
       }catch(error){
         logger.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
       }
       break;
    }
  }

}
