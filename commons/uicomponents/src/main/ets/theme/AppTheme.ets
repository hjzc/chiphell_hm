import { CustomColors,CustomDarkColors, CustomTheme } from '@kit.ArkUI';
import { uiAppearance } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

//https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-arkui-theme
export class AppColors implements CustomColors {
  //⾃定义主题⾊
  //  brand: ResourceColor = '#FF75D9'; // 品牌色
   // background_primary: ResourceColor  = '#FF00FF';

  // fontPrimary = 0xFFD53032;
  // iconOnPrimary = 0xFFD53032;
  // iconFourth = 0xFFD53032;
}

export class AppDarkColors implements CustomDarkColors {
  //⾃定义主题⾊
 // brand: ResourceColor = '#0075D9';
 // background_primary: ResourceColor  = '#FFFF00';
}

export class AppTheme implements CustomTheme {
   colors?: CustomColors ;
   darkColors?:CustomColors ;

  constructor(colors: CustomColors,darkColors: CustomDarkColors) {
    this.colors = colors;
    this.darkColors = darkColors;
  }

  public getDarkMode():number{
    let ret = -1;
    try {
      let darkMode = uiAppearance.getDarkMode();
      if(darkMode == uiAppearance.DarkMode.ALWAYS_DARK){
        ret = 0;
      }else{
        ret = 1;
      }
     // console.info('Get dark-mode ' + darkMode);
    } catch (error) {
      let message = (error as BusinessError).message;
      console.error('Get dark-mode failed, ' + message);
    }
    return ret;
  }


  // @StorageLink('currentColorMode') currentColorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  // applyTheme(mode: number) {
  //   try {
  //     // 1. 更新本地状态
  //     this.currentColorMode = mode
  //     // 2. 设置应用全局颜色模式
  //     this.getContext().getApplicationContext().setColorMode(mode)
  //   } catch (e) {
  //     // 错误处理，避免影响主流程
  //   }
  // }

}
// 在页面build之前执行ThemeControl.setDefaultTheme，设置App默认样式风格为BlueColorsTheme。
//ThemeControl.setDefaultTheme(gAppTheme);
export let gAppTheme: CustomTheme = new AppTheme(new AppColors(),new AppDarkColors());