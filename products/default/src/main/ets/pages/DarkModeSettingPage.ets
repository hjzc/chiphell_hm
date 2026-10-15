
import { common } from '@kit.AbilityKit';
import { AppStorageKey } from '../common/AppStorageKey';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import { GlobalThemeSetColorMode } from '../utils/ColorModeChangeFunction';
import { env } from '../Storage/ZjEnv';
import { ZjStorage } from '../Storage/ZjStorage';
import { AppStorageV2 } from '@ohos.arkui.StateManagement';


@Entry
@ComponentV2
export struct DarkModeSettingPage {
  @Consumer('navPageStack') navPageStack: NavPathStack = new NavPathStack();
  @Local themeMode: ConfigurationConstant.ColorMode = env.themeMode;
  @Local statusBarHeight: number = env.statusBarHeight;
  @Local storage: ZjStorage = AppStorageV2.connect(ZjStorage, 'storage', () => new ZjStorage())!;
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  private uiContext: UIContext | null = null;

  private onThemeModeChange(theme:ConfigurationConstant.ColorMode):void{
    if(theme!= this.themeMode){
      GlobalThemeSetColorMode(this.context,theme);
      this.themeMode = theme;
      this.storage.themeMode = theme;
      env.themeMode = theme;
      AppStorageKey.saveThemeMode(theme);
    }
  }

  aboutToAppear(): void {
    this.uiContext = this.getUIContext();

  }

  aboutToDisappear() {
    //主动持久化

  }

  build() {
    NavDestination() {
      Column() {
        Text($r('app.string.follow_system_settings_switch_mode'))
          .fontColor($r('sys.color.font_secondary'))
          .fontSize(14)
          .fontWeight(400)
          .lineHeight(20)
          .margin({ bottom: 16, top: 8 })
          .width('100%')
          .textAlign(TextAlign.Start)
        Row() {
          Text($r('app.string.follow_system_settings'))
            .fontColor($r('sys.color.font_primary'))
            .fontSize(16)
            .fontWeight(500)
            .lineHeight(22)
          Radio({ value: 'Radio1', group: 'radioGroup' })
            .checked(this.themeMode==ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.onThemeModeChange(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
              }
            })
        }
        .rowStyle()
        .justifyContent(FlexAlign.SpaceBetween)

        Row() {
          Text($r('app.string.dark_mode'))
            .fontColor($r('sys.color.font_primary'))
            .fontSize(16)
            .fontWeight(500)
            .lineHeight(22)
          Radio({ value: 'Radio1', group: 'radioGroup' })
            .checked(this.themeMode==ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.onThemeModeChange(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
              }
            })
        }
        .rowStyle()
        .justifyContent(FlexAlign.SpaceBetween)

        Row() {
          Text($r('app.string.light_mode'))
            .fontColor($r('sys.color.font_primary'))
            .fontSize(16)
            .fontWeight(500)
            .lineHeight(22)
          Radio({ value: 'Radio1', group: 'radioGroup' })
            .checked(this.themeMode==ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                this.onThemeModeChange(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
              }
            })
        }
        .rowStyle()
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .padding({ left: 16, right: 16 })

    }
    .title($r('app.string.theme_mode_set'))
    .backgroundColor($r('sys.color.background_primary'))
    .margin({ top: this.uiContext ? this.uiContext.px2vp(this.statusBarHeight) : 0 ,bottom:0 }) // 顶部避让
    .onBackPressed(()=>{
      return false;
    });
    // .onBackPressed(() => {
    //   this.webPageStack.pop();
    //   return true;
    // })
    // .onReady((context: NavDestinationContext) => {
    //     this.webPageStack = context.pathStack;
    // })
  }


}

@Styles
function rowStyle() {
  .width('100%')
  .height(56)
  .backgroundColor($r('sys.color.background_tertiary'))
  .margin({ bottom: 12 })
  .padding({ left: 12, right: 12 })
  .borderRadius(12)
}
