
import { common } from '@kit.AbilityKit';
import { env } from '../Storage/ZjEnv';
import { ZjStorage } from '../Storage/ZjStorage';
import { AppStorageV2 } from '@ohos.arkui.StateManagement';
import { NavBarItemData, SetNavItemView } from '../view/SetNavItemView';
import { BreakpointType, logger } from 'utils';
import { BusinessError } from '@kit.BasicServicesKit';
import { DelayTasks } from '../utils/DelayTasks';

@ComponentV2
export struct SetServicePage {
  @Consumer('navPageStack') navPageStack: NavPathStack = new NavPathStack();
  @Local statusBarHeight: number = env.statusBarHeight;
  @Local storage: ZjStorage = AppStorageV2.connect(ZjStorage, 'storage', () => new ZjStorage())!;
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private uiContext: UIContext | null = null;
  @Local navBarList: NavBarItemData[] = [];

  aboutToAppear(): void {
    this.uiContext = this.getUIContext();
    this.navBarList.push( new NavBarItemData(0,'',  $r('app.string.set_policies_user_agreement'),'' ))
    this.navBarList.push( new NavBarItemData(1,'',  $r('app.string.set_privacy_policy'),'' ))
    this.navBarList.push( new NavBarItemData(2,'',  $r('app.string.set_user_info_policy'),'' ))
  }

  aboutToDisappear() {

  }

  onClickSetNavItemView(index:number):void{
    let url:ResourceStr  = 'https://cliff.imwork.net:19999/chiphell/policies/';
    switch (index){
      case 0:{
        url += "user_agreement.html";
      }
        break;
      case 1:
        {
          url += "privacy_policy.html";
        }
        break;
      case 2:
        {
          url += "personal_information_collection_checklist.html";
        }
        break;
    }

    try{
      this.navPageStack.pushPathByName('SimpleWebClient', url);
    }catch(error){
      logger.error(`ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
    }


  }


  build() {
    NavDestination() {
      Column() {
        List({ space: 12 }) {
          ForEach(this.navBarList, (item: NavBarItemData, index: number) => {
            SetNavItemView( { item:item,click: (index:number)=>{
              this.onClickSetNavItemView(index);
            }});

          }, (item: NavBarItemData, index: number) =>`${item}-${index}` )
        }
        .width('100%')
        //设置List组件在sm、md、lg断点下List组件分别呈1列、1列、2列显示。依然可以使用List的lanes属性结合断点来实现效果。
        .lanes(new BreakpointType<number>({ sm:1, md: 1, lg: 2, xl: 2 }).getValue(this.storage.currentBreakpoint))
        .borderRadius(16)
        .padding({ left: 12,top:12, right: 12 })
      }
      .padding({ left: 16, right: 16 })

    }
    .title($r('app.string.set_terms_of_service'))
    .backgroundColor($r('sys.color.background_primary'))
    .margin({ top: this.uiContext ? this.uiContext.px2vp(this.statusBarHeight) : 0 ,bottom:0 }) // 顶部避让

    .onBackPressed(()=>{

      DelayTasks.addDelayRun("checkUserAgreementState",200,()=>{
        this.navPageStack.pop(1);
      });
      return true;
    });
  }

}