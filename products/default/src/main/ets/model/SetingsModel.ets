import { PicturePreview } from 'imagegallery';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppUtil } from '../utils/AppUtil';
import { webview } from '@kit.ArkWeb';
import { logger } from 'utils';
//import fs from '@ohos.file.fs';

export  class SettingsModel{

  static  deleteDirListFiles(dir:string):Promise<void> {
    return new Promise<void>(resolve => {
      fs.listFile(dir).catch((error:BusinessError) => {
        logger.error(`ListFile ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
        resolve();
      }).then((filenames) => {
        //处理 filenames: void | string[] 类型时，需明确该变量可能为 void（即 undefined）或字符串数组
        if (filenames && Array.isArray(filenames) && filenames.length > 0) {
          for (let i = 0; i < filenames.length; i++) {
            let filename = filenames[i];
            if (filename == 'Cookies' || filename == 'Session Storage') {
              continue;
            }
            let dirPath = dir + '/' + filename;
            console.info(dirPath);
            // 判断是否为文件夹
            let isDirectory: boolean = false;
            try {
              isDirectory = fs.statSync(dirPath).isDirectory();
            } catch (e) {
              console.error(JSON.stringify(e));
            }
            if (isDirectory) {
              try {
                fs.rmdirSync(dirPath);
              } catch (error) {
                logger.error(`fs.rmdirSync ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
              }
            } else {
              fs.unlink(dirPath).then(() => {
                logger.info('remove file succeed');
              }).catch((err: Error) => {
                logger.error(`fs.unlink remove file failed with error message: ${err.message}`);
              });
            }
          }
        }
        resolve();
      })
    });
  }

  static  deleteDir(dirPath:string):Promise<void> {
    return new Promise<void>(resolve => {
      try {
        fs.rmdir(dirPath).then(() => {
          logger.info('rmdir succeed');
          resolve();
        }).catch((err: BusinessError) => {
          logger.error(`rmdir failed with error message: ${err.message}, error code: ${err.code}`);
          resolve();
        });
      }catch (e) {
        resolve();
      }
    });
  }

  static deleteWebCache(all:boolean) :Promise<void>
  {
    return new Promise<void>(resolve => {
      if(AppUtil.isApiSupported(18)){
        try {
          webview.WebviewController.removeAllCache(all);
          resolve();
        } catch (error) {
          logger.error(`webview removeAllCache ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
          resolve();
        }
      }else{
        if(all){
          let cacheDir = 'data/storage/el2/base/cache/web';
          SettingsModel.deleteDirListFiles(cacheDir)
            .then(()=>{
              resolve();
            });
        }else{
          let dirPath = 'data/storage/el2/base/cache/web/Cache';
          SettingsModel.deleteDir(dirPath)
            .then(()=>{
              resolve();
            });
        }
      }
    });
  }

  static deleteTempDir(context:Context) :Promise<void>
  {
    //data/storage/el2/base/haps/default/files
  //  let filesDir = context.filesDir;
    ///data/storage/el2/base/haps/default/cache
   // let cacheDir = context.cacheDir;
    ///data/storage/el2/base/haps/default/temp
   // let tempDir = context.tempDir;
    return new Promise<void>(resolve => {
      SettingsModel.deleteDirListFiles(context.tempDir)
        .then(() => {
          resolve();
        });
    });
    // try {
    //   fs.rmdirSync(tempDir + "/*" )
    // } catch (error) {
    //   logger.error(`fs.rmdirSync ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`);
    // }
  }

  static async  clearCache(context:Context, all:boolean,onCompleted?:()=>void )
  {
      await SettingsModel.deleteTempDir(context);
      await SettingsModel.deleteWebCache(all);
      await PicturePreview.clearCache();
      if(onCompleted){
        onCompleted();
      }
  }
}