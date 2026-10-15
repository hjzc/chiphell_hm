
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { logger } from 'utils';

export  class  ArrayBufferUtil{

  static  WriteBufferToFile(buffer :ArrayBuffer,path:string):boolean
  {
    let r:boolean  = false;
    try {
      // 打开并创建文件目录
      let we:boolean = true;
      let file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      fs.write(file.fd, buffer).catch(() => {
        // TODO: Implement error handling.
        we =false;
      });
      fs.close(file.fd).catch(() => {
        // TODO: Implement error handling.
        we=false;
      });
      r = we;
    }catch (e ){
      let err : BusinessError = e as BusinessError;
      logger.error('CHIP_HELL', `writeBufferToFile error code: ${err.code}, message:${err.message}`);
    }
    return r;
  }

}