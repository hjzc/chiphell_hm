import { logger } from "utils";
import { resourceManager } from "@kit.LocalizationKit";
import { common, contextConstant } from "@kit.AbilityKit";
import { deviceInfo } from "@kit.BasicServicesKit";
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  fileIo, ReadOptions
} from '@kit.CoreFileKit';
import fs, { ReadTextOptions } from '@ohos.file.fs';
import { FileUtil } from "./FileUtil";
import { certificateManager } from "@kit.DeviceCertificateKit";
import { hilog } from "@kit.PerformanceAnalysisKit";
import BuildProfile from "default/BuildProfile";
import { retrieval } from "@kit.DataAugmentationKit";

export  class AppUtil {
  static certDir:string =  'certs';
  private static context: common.UIAbilityContext; //common.UIAbilityContext，上下文

  static init(context: common.UIAbilityContext) {
    AppUtil.context = context;
  }
  //let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
  static getContext(): common.UIAbilityContext {
    if (!AppUtil.context) {
      AppUtil.context = getContext() as common.UIAbilityContext; //兜底
      logger.error("请在UIAbility的onCreate方法中调用AppUtil的init方法初始化！");
    }
    return AppUtil.context;
  }

  static  getApplicationContext(): common.ApplicationContext{
    return AppUtil.context.getApplicationContext();
  }

  static getResourceManager(): resourceManager.ResourceManager {
    return AppUtil.getContext().resourceManager;
  }

  static getDeviceCapabilitySync(): resourceManager.DeviceCapability {
    return AppUtil.getResourceManager().getDeviceCapabilitySync();
  }

  static async getMediaContent(resId: number | Resource, density?: number): Promise<Uint8Array> {
    if (density !== undefined) {
      if (typeof resId === 'number') {
        return AppUtil.getResourceManager().getMediaContent(resId, density);
      } else {
        return AppUtil.getResourceManager().getMediaContent(resId, density);
      }
    } else {
      if (typeof resId === 'number') {
        return AppUtil.getResourceManager().getMediaContent(resId);
      } else {
        return AppUtil.getResourceManager().getMediaContent(resId);
      }
    }
  }
  ///在工程 resources 下创建 resfile 文件夹
  static getEntryResourceResFilePath(model:string, fileName:string) :string {
    //"/data/storage/el1/bundle/default/resources/resfile/sectigo_chain.pem";
    let context = AppUtil.getContext() as common.UIAbilityContext;
    if (context) {
      ///data/storage/el1/bundle/default/resources/resfile
      let resourceDir = context.resourceDir;
      if(resourceDir.length>0){
        return resourceDir + '/'+fileName;
      }
    }
    return '/data/storage/el1/bundle/'+model+'/resources/resfile/'+fileName;
  }



  static  copyRawFileToSandbox(context: Context, rawFileName: string,sandBoxDir:string):Promise<string|null>  {
    return new Promise<string|null>(resolve => {
       try {
         // 读取rawfile中的db文件
         context
           .resourceManager
           .getRawFd(rawFileName, (error, value) => {
             if (error || !value) {
               logger.info('read rawfile error');
               resolve(null);
               return;
             }
             logger.info(`read rawfile length:${value?.length}`);
             AppUtil.saveFileToSandbox(context, value, rawFileName ,sandBoxDir).then((val)=>{
               resolve(val);
             });
           });
       } catch (error) {
         const err: BusinessError = error as BusinessError;
         logger.info('callback getRawFd failed: ' + err.code + ', ' + err.message);
         resolve(null);
       }
     });

  }

  private static async saveFileToSandbox(context: Context, file: resourceManager.RawFileDescriptor, rawFileName: string,sandBoxDir:string):Promise<string|null> {
    let cacheFile: fs.File | null = null
    let targetFile :string|null =null;
    try {
      //    /data/storage/el2/base/files/cert
     // let dirPath = context.getApplicationContext().filesDir + '/'+ sandBoxDir;
      ///data/storage/el2/base/haps/default/files
      let dirPath = context.filesDir + '/'+ sandBoxDir;
      if (!fs.accessSync(dirPath)) {
        fs.mkdirSync(dirPath);
      }
      // dirPath = dirPath + '/rdb';
      // fs.mkdirSync(dirPath);
      // 创建数据库沙箱目录 /data/storage/el2/base/files/cert/cacert.pem
      targetFile = dirPath +  '/'+ rawFileName;
      if (!fs.accessSync(targetFile)) {
        cacheFile = await fs.open(targetFile, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        // 读取缓冲区大小
        const bufferSize = 10224 * 1024;
        let buffer = new ArrayBuffer(bufferSize);

        // 要copy的文件的offset和length
        let currentOffset = file.offset;

        let readOption: ReadOptions = {
          offset: currentOffset, // 期望读取文件的位置。可选，默认从当前位置开始读
          length: bufferSize // 每次期望读取数据的长度。可选，默认缓冲区长度
        }
        // 后面len会一直减，直到没有
        while (true) {
          let readLength = await fs.read(file.fd, buffer, readOption);
          await fs.write(cacheFile.fd, buffer, { length: readLength })
          // 判断后续内容，修改读文件的参数
          // buffer没读满代表文件读完了
          if (readLength < bufferSize) {
            break;
          }
          if (readOption.offset !== undefined) {
            readOption.offset += readLength;
          }
        }
        logger.info( 'Copy Success!!!');
      }else{
        logger.info( 'file exist !!!');
      }
      //return targetFile;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      logger.info( 'saveFileToSandbox err: ' + err.code + ', ' + err.message);
      targetFile= null;
    } finally {
      logger.info( 'close file!!!')
      if (cacheFile!= null) {
        fs.close(cacheFile).catch(() => {
          // TODO: Implement error handling.
        });
        cacheFile=null;
      }
      return targetFile;
    }
  }

  static  copyRawPemFileToSandbox(context: Context, rawFileName: string,sandBoxDir:string,cover:boolean):string {
    let area: contextConstant.AreaMode = context.area;
    context.area = contextConstant.AreaMode.EL1;// 0;
    let filePath = '';
    try {
      const keyPem = context.resourceManager.getRawFileContentSync(rawFileName);
      let filesDir: string = context.filesDir;
      if(sandBoxDir.length>0){
        filesDir = filesDir + '/'+sandBoxDir;
        if (!FileUtil.accessSync(filesDir)) {
          FileUtil.mkdirSync(filesDir);
        }
      }
      filePath = filesDir + '/'+rawFileName;
      if(cover || !FileUtil.accessSync(filePath)){
        let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        // fs.writeSync(file.fd, keyPem.buffer);
        // 从 Uint8Array 中截取有效的 ArrayBuffer 片段,因为 getRawFileContentSync 返回的 Uint8Array 可能只是某个更大缓冲区的一个视图。
        const arrayBuffer = keyPem.buffer.slice(keyPem.byteOffset, keyPem.byteOffset + keyPem.byteLength);
        fs.writeSync(file.fd, arrayBuffer);
        fs.fsyncSync(file.fd);
        fs.closeSync(file);
        //console.info('cert file size: ' + fs.statSync(filePath).size + ', raw size: ' + keyPem.byteLength);
      }
    } catch (error) {
      // TODO: Implement error handling.
      console.error('copyRawPemFileToSandbox error: ' + JSON.stringify(error));
    }
    context.area = area;
    return filePath;
  }

  //    /data/storage/el1/base/haps/default/certs/static-chiphell-com.pem
  //    /data/storage/el1/base/haps/default/files/certs/static-chiphell-com.pem
  static  InstallPemFileToSandbox(context: Context, rawFileName: string,cover:boolean):string {
    return AppUtil.copyRawPemFileToSandbox(context,rawFileName,AppUtil.certDir,cover);
  }

  /// 获得证书安装（InstallPemFileToSandbox）在沙盒后的路径
  static  getInstalledPemFileInSandbox(model:string,rawFileName: string):string {
    let context = AppUtil.getContext() as common.UIAbilityContext;
    if (context) {
      // /data/storage/el1/base/haps/+ model +/files/
      let filesDir: string = context.filesDir;
      return filesDir + '/'+rawFileName;
    }
    return '/data/storage/el1/base/haps/'+model+'/files/'+AppUtil.certDir +'/'+rawFileName;
  }


  static  InstallPrivateCertificate(context: Context, rawFileName: string,domain:string):Promise<string|null>{
    return new Promise<string|null>(resolve => {
      //注：badssl.com-client.p12需要替换为实际使用的证书文件
      try {
        let value: Uint8Array = context.resourceManager.getRawFileContentSync(rawFileName);
        certificateManager.installPrivateCertificate(value, domain, "1",
          async (err: BusinessError, data: certificateManager.CMResult) => {
            let uri:string|null = null;
            console.info(`installPrivateCertificate, uri==========${JSON.stringify(data.uri)}`)
            if (!err && data.uri) {
              uri = data.uri;
            }
            resolve(uri);
          });
      } catch (error) {
        // TODO: Implement error handling.
        resolve(null);
      }
    });
  }


  /**
   * 获取当前设备类型
   * resourceManager.DeviceType:
   *   DEVICE_TYPE_PHONE手机。
   *   DEVICE_TYPE_TABLET 平板。
   *   DEVICE_TYPE_CAR 汽车。
   *   DEVICE_TYPE_PC 电脑。
   *   DEVICE_TYPE_TV 电视。
   *   DEVICE_TYPE_WEARABLE 穿戴。
   *   DEVICE_TYPE_2IN1 2IN1。
   * @returns
   */
  static getDeviceType(): number {
    return AppUtil.getDeviceCapabilitySync().deviceType;
  }

  static isPhoneDevice(): boolean {
    return AppUtil.getDeviceType() === resourceManager.DeviceType.DEVICE_TYPE_PHONE;
  }
  static is2N1Device(): boolean {
    return AppUtil.getDeviceType() === resourceManager.DeviceType.DEVICE_TYPE_2IN1;
  }
  static isPCDevice(): boolean {
    return AppUtil.getDeviceType() === resourceManager.DeviceType.DEVICE_TYPE_PC;
  }
  /**
   * 获取当前设备类型
   * @returns
   */
  static getDeviceTypeStr(): string {
    let deviceType = AppUtil.getDeviceType();
    switch (deviceType) {
      case resourceManager.DeviceType.DEVICE_TYPE_PHONE:
        return "手机";
      case resourceManager.DeviceType.DEVICE_TYPE_TABLET:
        return "平板";
      case resourceManager.DeviceType.DEVICE_TYPE_PC:
        return "电脑";
      case resourceManager.DeviceType.DEVICE_TYPE_TV:
        return "电视";
      case resourceManager.DeviceType.DEVICE_TYPE_CAR:
        return "汽车";
      case resourceManager.DeviceType.DEVICE_TYPE_WEARABLE:
        return "穿戴";
      case resourceManager.DeviceType.DEVICE_TYPE_2IN1:
        return "2IN1";
      default:
        return ""
    }
  }

  static isApiSupported(apiVersion: number): boolean {
    return deviceInfo.sdkApiVersion >= apiVersion;
  }


  // 复制文本到剪贴板
  static  copyTextToPasteboard(text: string, result:(success:boolean)=>void) {
    // 1. 创建剪贴板数据对象
    const pasteboardData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    // 2. 获取系统剪贴板
    const systemPasteboard = pasteboard.getSystemPasteboard();
    // 3. 写入数据
    systemPasteboard.setData(pasteboardData).catch(() => {
      // TODO: Implement error handling.
    });
    // 4. 验证复制结果（可选） ohos. permission. READ_PASTEBOARD
    systemPasteboard.getData()
      .then((data) => {
        if (data) {
          console.log('复制成功');
          if(result !==undefined){
            result(true);
          }
        } else {
          console.log('复制失败');
          if(result !==undefined){
            result(false);
          }
        }
      })
      .catch( (error:BusinessError)=>{
        if(result !==undefined){
          result(false);
        }
      }

      );

  }

  static  readTextSync(filePath: string, options?: ReadTextOptions):string|undefined {
    let rc :string|undefined;
    try {
      rc = fs.readTextSync(filePath,options);
      if(BuildProfile.DEBUG){
        hilog.info(0x0000, 'CHIP_HELL', `read text sync path:${filePath},text: \n${rc}`);
      }
    }catch (e) {
      hilog.info(0x0000, 'CHIP_HELL','catch error :' + JSON.stringify(e));
    }
    return rc;
  }

  //判断文件是否存在
  static  fileExist(filePath: string):boolean {
    let rc :boolean=false;
    try {
      rc = fileIo.accessSync(filePath);
    }catch (e) {
      hilog.info(0x0000, 'CHIP_HELL','catch error :' + JSON.stringify(e));
    }
    return rc;
  }

  static getHttpsSectigoChainPemPath() :string {
    return AppUtil.getEntryResourceResFilePath('default','sectigo_chain.pem');
  }

}