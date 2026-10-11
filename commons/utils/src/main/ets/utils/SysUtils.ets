import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { logger } from './Logger';
import { window } from '@kit.ArkUI';
export interface  AbilityConfigType {
  bundleName: string;
  abilityName: string;
}

enum FWindowMode{
  FullNormal,//窗口全屏布局(显示状态栏和导航栏)模式
  FullAll,   //窗口全屏布局(隐藏状态栏和导航栏)模式
  SafeNormal //窗口非全局布局，组件安全区模式
}

export class SysUtils{
  /**
   *
   * import { getResourceString } from '../../../../utils/ResourceUtils';
   *
   * getResourceString Converts data of the Resource type to data of the string type
   * @param context
   * @param ResourceData
  *
  * 使用方法：
   *  let objectTitle: string = getResourceString(this.getUIContext().getHostContext() as common.UIAbilityContext, $r('app.string.class_object'))
   *
   * 在string文件中声明
   * {
   *  "name": "class_object",
   *  "value": "Object"
   *  },
   *
   */
  static  getResourceString(context: common.UIAbilityContext, resourceData: Resource): string {
    let stringData: string = '';
    try {
      stringData = context.resourceManager.getStringSync(resourceData.id);
    } catch (error) {
      let err = error as BusinessError;
      logger.error(`getResourceString failed. code=${err.code}, message=${err.message}`);
    }
    return stringData;
  }


  //跳转到其他窗口
  //
  //需要在module.json5 声明这个ablity
  // {
  //   "name": "StoragePropAbility",
  // "srcEntry": "./ets/storagepropability/StoragePropAbility.ets",
  // "description": "$string:storagepropability_desc",
  // "icon": "$media:icon",
  // "label": "$string:storagepropability_label",
  // "startWindowIcon": "$media:icon",
  // "startWindowBackground": "$color:start_window_background",
  // "exported": true
  // },
  //使用
  //.onClick(() => {
  //         startSpecifiedAbility(this.getUIContext().getHostContext() as common.UIAbilityContext, 'StoragePropAbility');
  //       })
  static  startSpecifiedAbility(context: common.UIAbilityContext, abilityName: string): void {
    let bundleName =  context.abilityInfo.bundleName;
    let abilityConfig: AbilityConfigType = {
      bundleName: bundleName??'com.redpig.chiphell',
      abilityName: abilityName
    };
    try {
      context.startAbility(abilityConfig, (err) => {
        if (err.code) {
          // Handle business logic errors.
          logger.error(`startAbility failed, code is ${err.code}, message is ${err.message}`);
          return;
        }
        // Perform normal services.
        logger.info('startAbility succeed');
      });
    }catch (err ) {
      // 处理入参错误异常
      let code = (err as BusinessError).code;
      let message = (err as BusinessError).message;
      logger.info(`startAbility failed, code is ${code}, message is ${message}`);
    }
  }


  static setWindowMode(ablContext:common.UIAbilityContext, mode:FWindowMode ,path:string|null) {
    let windowStage: window.WindowStage = ablContext.windowStage;
    if (!windowStage){
      return;
    }
    windowStage.getMainWindow((err: BusinessError, data: window.Window) => {
      if (err.code) {
        logger.error(`获得窗口失败: ${JSON.stringify(err)}`);
        return;
      }
      let mainWindow: window.Window = data;
      if(!mainWindow){
        logger.error('获得窗口失败');
        return;
      }
      mainWindow.setWindowLayoutFullScreen((mode == FWindowMode.FullNormal) || (mode == FWindowMode.FullAll)).catch(() => {
        // 显示状态栏和导航栏
        mainWindow?.setSpecificSystemBarEnabled('status', (mode == FWindowMode.FullNormal) || (mode == FWindowMode.SafeNormal)).catch(() => {
          // TODO: Implement error handling.
        });
        mainWindow?.setSpecificSystemBarEnabled('navigationIndicator', (mode == FWindowMode.FullNormal) || (mode == FWindowMode.SafeNormal)).catch(() => {
          // TODO: Implement error handling.
        });
        // 加载对应页面
        if(path!=null){
          windowStage.loadContent(path, (err) => {
            if (err.code) {
              logger.error(`加载页面失败: ${JSON.stringify(err)}`);
              return;
            }
          });
        }
      });
    });
  }


}
