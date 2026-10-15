import { AbilityLifecycleCallback, common, UIAbility, WantAgent, wantAgent } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { logger } from 'utils';
import { NotificationBasicOptions } from '../../entity/NotificationOptions';
import { AppUtil } from '../../utils/AppUtil';
import { CacheUtil } from '../../utils/CacheUtil';
import { FileUtil } from '../../utils/FileUtil';
import { NotificationUtil } from '../../utils/NotificationUtil';
import { PreviewUtil } from '../../utils/PreviewUtil';
import fs from '@ohos.file.fs';

/**
 * ArkWeb内部工具类
 */
export class ZzjWebUtils {

  private static downloadPath: string = ""; //下载文件Path。


  /**
   * 设置下载文件夹路径，仅SDK内部使用 /data/storage/el2/base/haps/default/cache
   */
  static setDownloadPath(path: string) {
    ZzjWebUtils.downloadPath = path;
  }

  /**
   * 获取ArkWeb文件夹下载路径，仅SDK内部使用
   */
  static getArkDownloadPath(): string {
    return ZzjWebUtils.downloadPath;
  }


  /**
   * 注册监听应用内生命周期。
   */
  static onAbilityLifecycle(context: common.UIAbilityContext) {
    try {
      const abilityLifecycleCallback: AbilityLifecycleCallback = {
        onAbilityCreate: (ability: UIAbility): void => {

        },
        onNewWant:(ability: UIAbility): void => {
          let parameters = ability.lastRequestWant.parameters;
          if (parameters) {
            let uri = parameters["uri"] as string;
            let filePreview = parameters["filePreview"];
            if ('filePreview' === filePreview && uri) {
              PreviewUtil.openPreviewEasy(uri)
            }
          }
        },
        onWindowStageCreate: (ability: UIAbility, windowStage: window.WindowStage): void => {
          let parameters = ability.lastRequestWant.parameters;
          if (parameters) {
            let uri = parameters["uri"] as string;
            let filePreview = parameters["filePreview"];
            if ('filePreview' === filePreview && uri) {
              PreviewUtil.openPreviewEasy(uri)
            }
          }
        },
        onWindowStageActive: (ability: UIAbility, windowStage: window.WindowStage): void => {

        },
        onWindowStageInactive: (ability: UIAbility, windowStage: window.WindowStage): void => {

        },
        onWindowStageDestroy: (ability: UIAbility, windowStage: window.WindowStage): void => {

        },
        onAbilityDestroy: (ability: UIAbility): void => {

        },
        onAbilityForeground: (ability: UIAbility): void => {

        },
        onAbilityBackground: (ability: UIAbility): void => {

        },
        onAbilityContinue: (ability: UIAbility): void => {

        }
      }
      context.getApplicationContext().on('abilityLifecycle', abilityLifecycleCallback);
    } catch (err) {
      logger.error(err);
    }
  }


  /**
   * 下载文件，发送通知
   * @param notificationKey
   * @param fileName 文件名
   * @param percent 进度
   * @param state 0-下载中，-1-下载失败，1-下载成功，
   */
  static async sendNotification(notificationKey: string, fileName: string, percent: number, state: number,finish:boolean=false) {
    let notificationId = CacheUtil.get<number>(notificationKey);
    let content = `正在下载：${percent}%`;
    if (state === 1) {
      content = `下载完成`;
    } else if (state === -1) {
      content = `下载失败`;
    }
    let savePath = `${ZzjWebUtils.getArkDownloadPath()}/${fileName}`; //下载文件路径
    let want = await ZzjWebUtils.getDownloadWantAgent(FileUtil.getUriFromPath(savePath));
    let basicOptions: NotificationBasicOptions = {
      id: notificationId,
      title: fileName,
      text: content,
      tapDismissed: state !== 0,
      isAlertOnce: true,
      badgeNumber: 0,
      wantAgent: state == 1 ? want : undefined,
    }
    NotificationUtil.publishBasic(basicOptions);
  }


  /**
   * 创建一个可拉起Ability的Want
   * @returns
   */
  static async getDownloadWantAgent(uri: string): Promise<WantAgent> {
    const context = AppUtil.getContext() as common.UIAbilityContext; //获取当前上下文对象
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: context.abilityInfo.bundleName,
          moduleName: context.abilityInfo.moduleName,
          abilityName: context.abilityInfo.name,
          action: 'action_notice',
          parameters: {
            "uri": uri,
            "filePreview": "filePreview"
          }
        }
      ],
      actionType: wantAgent.OperationType.START_ABILITY | wantAgent.OperationType.SEND_COMMON_EVENT,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
    };
    return wantAgent.getWantAgent(wantAgentInfo);
  }

  /**
   * 获取可用的文件路径。
   * 如果原路径对应的文件不存在，直接返回原路径；
   * 如果已存在，则在文件名（不含扩展名）后追加数字 1、2、3…，直到找到不存在的路径。
   * @param originalPath 原始文件完整路径
   * @returns 可用的文件完整路径
   */
  public static getAvailableFilePath(originalPath: string): string {

    if (!ZzjWebUtils.accessSync(originalPath)) {
      return originalPath;
    }

    const lastSlashIndex = originalPath.lastIndexOf('/');
    let dir = '';
    let fileName = originalPath;
    if (lastSlashIndex !== -1) {
      dir = originalPath.substring(0, lastSlashIndex + 1); // 包含末尾的 '/'
      fileName = originalPath.substring(lastSlashIndex + 1);
    }

    // 3. 分离主文件名和扩展名（最后一个点之后为扩展名）
    const lastDotIndex = fileName.lastIndexOf('.');
    let baseName = fileName;
    let ext = '';
    // lastDotIndex > 0 避免把 .hidden 这类文件误判为有扩展名
    if (lastDotIndex > 0) {
      baseName = fileName.substring(0, lastDotIndex);
      ext = fileName.substring(lastDotIndex); // 包含点，如 ".jpg"
    }

    // 4. 循环尝试 baseName + 数字 + ext
    let counter = 1;
    let newPath = '';
    do {
      newPath = dir + baseName + counter + ext;
      counter++;
    } while (ZzjWebUtils.accessSync(newPath));

    return newPath;
  }

  static accessSync(path:string):boolean{
    let r:boolean =false;
    try {
      r=fs.accessSync(path);
    } catch (error) {
      // TODO: Implement error handling.
    }
    return r;
  }


}