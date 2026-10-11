import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { fileUri } from '@kit.CoreFileKit';
import { Context } from '@ohos.arkui.UIContext';
import { AllFilesInterface, FileType, ResourceType } from '../../../../Index';
import { FilePath } from '../model/FilePath';
import { ImgDownloadManager } from '../interface/ImgDownloadManager';
import { ImgDownloadCallBack } from '../interface/ImgDownloader';
import { BusinessError } from '@kit.BasicServicesKit';
import { PicturePreviewDataModel } from '../model/PicturePreviewDataModel';

export class PictureCacheUtil{
  private context: Context
  constructor(context: Context) {
    this.context = context;
  }
  static defaultUA : string  = 'Mozilla/5.0 (Phone; OpenHarmony 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36  ArkWeb/6.0.0.47 Mobile';


  /**
   * 根据传入的网络地址或者本地地址选择使用哪个地址
   * @param url 网络地址
   * @param path 本地地址 或者 文件名称
   * @returns 图片地址
   */
  getPathOrUrl(pathOrName:string, url: string, downloadCallBack:ImgDownloadCallBack|undefined = undefined ,suffix: string = '.jpg'): string {
    // 两个地址都不存在
    if (!pathOrName && !url) {
      return ''
    }

    let filePath:string  = '';
    let fileName:string = '';
    // 如果是本地地址则返回本地地址
    if (pathOrName) {
      if (pathOrName.includes("file://")) {
        fileName = PictureCacheUtil.getFileName(pathOrName, url, suffix)
        filePath = PictureCacheUtil.getFilePath(this.context, fileName);
        if (fs.accessSync(filePath)) {
           return pathOrName;
        }
      }
      else if (fs.accessSync(pathOrName)) {
        return fileUri.getUriFromPath(pathOrName)
      }
      else{
        let fileName = PictureCacheUtil.getFileName(pathOrName, url, suffix)
        let filePath = PictureCacheUtil.getFilePath(this.context, fileName);
      }
    }else{
      fileName = PictureCacheUtil.getFileName(pathOrName, url, suffix)
      filePath = PictureCacheUtil.getFilePath(this.context, fileName);
    }

    // 校验并创建目录
    const regex = new RegExp("/"+fileName, 'g'); // 创建一个全局正则表达式
    let file = filePath.replace(regex, ''); // 替换所有匹配的子字符串为空字符串
    PictureCacheUtil.verifyFileDirectory(file);
    // 存在则判断文件存不存在，存在则返回，不存在则创建并缓存文件
    let is = PictureCacheUtil.verifyFilePath(filePath)
    if (is) {
      let file = fileUri.getUriFromPath(filePath);
      console.log("ThumbnailPictureModel", "getPathOrUrl", "拿到本地沙箱路径： " + file)
      return file;
    } else {
      PictureCacheUtil.downloadPathByUrl(filePath, url,downloadCallBack)
      return url ? url : '';
    }
  }

 static  getFilePathFromUrl(context: Context,pathOrName:string, url: string,suffix: string = '.jpg'): string {
    // 两个地址都不存在
    if (!pathOrName && !url) {
      return ''
    }

   let filePath:string  = '';
   let fileName:string = '';
   // 如果是本地地址则返回本地地址
   if (pathOrName) {
     if (pathOrName.includes("file://")) {
       fileName = PictureCacheUtil.getFileName(pathOrName, url, suffix)
       filePath = PictureCacheUtil.getFilePath(context, fileName);
       if (fs.accessSync(filePath)) {
         return pathOrName;
       }
     }
     else if (fs.accessSync(pathOrName)) {
       return fileUri.getUriFromPath(pathOrName)
     }
     else{
       let fileName = PictureCacheUtil.getFileName(pathOrName, url, suffix)
       let filePath = PictureCacheUtil.getFilePath(context, fileName);
     }
   }else{
     fileName = PictureCacheUtil.getFileName(pathOrName, url, suffix)
     filePath = PictureCacheUtil.getFilePath(context, fileName);
   }

    // // 如果是本地地址则返回本地地址
    // if (pathOrName) {
    //   if (pathOrName.includes("file://")) {
    //     return pathOrName;
    //   }
    //   if (fs.accessSync(pathOrName)) {
    //     return fileUri.getUriFromPath(pathOrName)
    //   }
    // }
    // let fileName = PictureCacheUtil.getFileName(pathOrName, url, suffix)
    // let filePath = PictureCacheUtil.getFilePath(context, fileName);




    // 校验并创建目录
    const regex = new RegExp("/"+fileName, 'g'); // 创建一个全局正则表达式
    let file = filePath.replace(regex, ''); // 替换所有匹配的子字符串为空字符串
    PictureCacheUtil.verifyFileDirectory(file);
    // 存在则判断文件存不存在，存在则返回，不存在则创建并缓存文件
    let is = PictureCacheUtil.verifyFilePath(filePath)
    if (is) {
      let file = fileUri.getUriFromPath(filePath);
      console.log("ThumbnailPictureModel", "getPathOrUrl", "拿到本地沙箱路径： " + file)
      return file;
    } else {
      let file = fileUri.getUriFromPath(filePath)
      return file ? file : '';
    }
  }


  /**
   * 删除沙箱路径中的文件
   * @param filePath 沙箱路径
   */
  deletePath(filePath: string) {
    let fileName = PictureCacheUtil.getFileName(filePath, '')
    let filePath1 = PictureCacheUtil.getFilePath(this.context, fileName);
    fs.unlink(filePath1);
  }
  /**
   * 根据传入的网络地址或者本地地址选择使用哪个地址
   * @param url 网络地址
   * @param path 本地地址 或者 文件名称
   * @returns 图片地址
   */
  static getPathOrUrl(context: Context, pathOrName:string, url: string,downloadCallBack:ImgDownloadCallBack|undefined, suffix: string = '.jpg'): string {
    // 两个地址都不存在
    if (!pathOrName && !url) {
      return ''
    }
    let fileName = PictureCacheUtil.getFileName(pathOrName, url, suffix)
    let filePath = PictureCacheUtil.getFilePath(context, fileName);
    // 校验并创建目录
    const regex = new RegExp("/"+fileName, 'g'); // 创建一个全局正则表达式
    let file = filePath.replace(regex, ''); // 替换所有匹配的子字符串为空字符串
    PictureCacheUtil.verifyFileDirectory(file);
    // 存在则判断文件存不存在，存在则返回，不存在则创建并缓存文件
    let is = PictureCacheUtil.verifyFilePath(filePath)
    if (is) {
      let file = fileUri.getUriFromPath(filePath);
      console.log("ThumbnailPictureModel", "getPathOrUrl", "拿到本地沙箱路径： " + file)
      return file;
    } else {
      PictureCacheUtil.downloadPathByUrl(filePath, url,downloadCallBack)
      return url ? url : '';
    }
  }
  /**
   * 删除沙箱路径中的文件
   * @param filePath 沙箱路径
   */
  static deletePath(context: Context, filePath: string) {
    let fileName = PictureCacheUtil.getFileName(filePath, '')
    let filePath1 = PictureCacheUtil.getFilePath(context, fileName);
    fs.unlink(filePath1);
  }
  /**
   *
   * /data/storage/el2/base/haps/default/files + /MediaLibrary_Image
   * 清空缓存目录
   * @param context
   */
  static deleteAll(context: Context) {
    let filesDir = context.filesDir;
    try {
      fs.rmdirSync(filesDir + "/" + FilePath.Image)
    } catch (e) {}
    try {
      fs.rmdirSync(filesDir + "/" + FilePath.Video)
    } catch (e) {}
    try {
      fs.rmdirSync(filesDir + "/" + FilePath.Audio)
    } catch (e) {}
    try {
      fs.rmdirSync(filesDir + "/" + FilePath.File)
    } catch (e) {}
  }
  /**
   * 传入沙箱目录和网络地址
   * 将文件下载到沙箱目录中
   * @param filePath 沙箱目录
   * @param url 网络地址
   */
  static  downloadPathByUrl(filePath: string, url: string,downloadCallBack:ImgDownloadCallBack|undefined = undefined ):void  {

    return ImgDownloadManager.getInstance().downloadPathByUrl(filePath,url,downloadCallBack);

    //
    //
    // let ua =  PicturePreviewDataModel.getInstance().requestUserAgent;
    // if (ua==null) {
    //     ua =AppStorage.get('useragent') as string;
    // }
    // if(ua === undefined ||ua===null){
    //   ua = PictureCacheUtil.defaultUA;
    // }
    //
    // let host =  PicturePreviewDataModel.getInstance().requestHost;;
    // let rf:string|null = PicturePreviewDataModel.getInstance().requestReferer;
    // if (rf==null) {
    //   rf =AppStorage.get('referer') as string;
    // }
    //
    // if(host==null || rf===null || rf === undefined){
    //   const regex = new RegExp("^(https?:\\/\\/[a-zA-Z0-9-|.]+[a-zA-Z]{2,6})"); // 创建一个全局正则表达式
    //   let res :RegExpMatchArray|null =  url.match(regex);
    //   if(res != null && res.length >0){
    //     let baseUrl =res[0];
    //     if (host==null) {
    //       host = baseUrl;
    //       if (host.startsWith('https://',0)) {
    //         host = host.replace('https://','');
    //       }else if (host.startsWith('http://',0)) {
    //         host = host.replace('http://','');
    //       }
    //     }
    //     if (rf==null) {
    //       rf = baseUrl;
    //     }
    //     //https://static.chiphell.com/
    //     if (rf.startsWith('https://static.',0)) {
    //        rf = rf.replace('https://static.','https://www.');
    //     }else if (rf.startsWith('http://static.',0)) {
    //       rf = rf.replace('http://static.','http://www.');
    //     }
    //   }
    // }
    //
    // if(downloadCallBack !== undefined){
    //   downloadCallBack.filePath = filePath;
    //   if(downloadCallBack.onStart !== undefined){
    //     downloadCallBack.onStart(url);
    //   }
    // }
    // // 'Accept':'image/avif,image/webp,image/png,image/svg+xml,image/*;q=0.8,*/*;q=0.5',
    // // 'Accept-Encoding':'gzip, deflate, br, zstd',
    // // 'Accept-Language':'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
    // // 'Referer':rf??'https://www.chiphell.com',
    // // 'Host':host??'www.chiphell.com',
    // // 'User-Agent':ua
    //
    // // let options: http.HttpRequestOptions = {
    // //   method: http.RequestMethod.GET, // 可选，默认为http.RequestMethod.GET
    // //   // 当使用POST请求时此字段用于传递请求体内容，具体格式与服务端协商确定
    // // //  extraData: 'data to send',
    // //   //expectDataType: http.HttpDataType.STRING, // 可选，指定返回数据的类型
    // //   usingCache: true, // 可选，默认为true
    // //   priority: 1, // 可选，默认为1
    // //   // 开发者根据自身业务需要添加header字段
    // //   header: {
    // //     'Referer':rf??'https://www.chiphell.com',
    // //     'User-Agent':ua
    // //   },
    // //   readTimeout: 60000, // 可选，默认为60000ms
    // //   connectTimeout: 60000, // 可选，默认为60000ms
    // //   usingProtocol: http.HttpProtocol.HTTP1_1, // 可选，协议类型默认值由系统自动指定
    // //   usingProxy: false, // 可选，默认不使用网络代理，自API 10开始支持该属性
    // //   maxLimit: 100 * 1024 * 1024,
    // // };
    //
    // let httpRequest = http.createHttp();
    // httpRequest.request(url,{
    //     method: http.RequestMethod.GET,
    //     connectTimeout: 60000,
    //     readTimeout: 60000,
    //     maxLimit: 100 * 1024 * 1024,
    //     usingCache:true,
    //     header: {
    //       'Referer':rf??'https://www.chiphell.com',
    //       'User-Agent':ua
    //     },
    //     usingProtocol: http.HttpProtocol.HTTP1_1,
    //   },
    //   async (err, data)=>
    //   {
    //     let ss = false;
    //     if (err) {
    //       console.log("CHIP_HELL ThumbnailPictureModel", "downloadPathByUrl Error: " + JSON.stringify(err))
    //       let httpError:BusinessError = err as BusinessError;
    //       if(httpError.code == 2300023){
    //         console.log("CHIP_HELL ThumbnailPictureModel", "downloadPathByUrl error 2300023 " + filePath)
    //         //目录不可以写。或者上次还在下载中，或者文件超过了5MB，要改为http.requestInstream 下载
    //         // // 创建请求对象
    //         // import http from '@ohos.net.http';
    //         // let request = http.createHttp();
    //         // // 启用流式传输
    //         // request.requestInStream(url,
    //         //   {
    //         //     connectTimeout: 60000,
    //         //     readTimeout: 60000,
    //         //     maxLimit: 100 * 1024 * 1024,
    //         //     header: {
    //         //       'Accept':'image/avif,image/webp,image/png,image/svg+xml,image/*;q=0.8,*/*;q=0.5',
    //         //       'Referer':rf??'https://www.chiphell.com',
    //         //       'User-Agent':ua
    //         //     }
    //         //   },
    //         //   (err1, response) =>
    //         //   {
    //         //     if (err1)
    //         //     {
    //         //       /* 错误处理 */
    //         //     }
    //         //     else {
    //         //       // 分块处理数据
    //         //       // let writer = ... // 创建文件写入流
    //         //       let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    //         //       response.on('data', (chunk: ArrayBuffer) => {
    //         //         fs.write(file.fd, chunk); // 逐块写入
    //         //       });
    //         //       response.on('end', () => {
    //         //         fs.close(file.fd);
    //         //       });
    //         //     }
    //         //   }
    //         // );
    //         ss = true;
    //       }else{
    //         ss = true;
    //       }
    //     }
    //     else{
    //       if( data.resultType== 2){
    //         console.log('CHIP_HELL data. resultType other 无效格式');
    //         // 获取到图片流
    //         let imageBuffer = data.result as ArrayBuffer;
    //         // 打开并创建文件目录
    //         let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    //         fs.write(file.fd, imageBuffer);
    //         console.log("CHIP_HELL ThumbnailPictureModel", "downloadPathByUrl 文件保存成功 " + filePath)
    //         fs.close(file.fd);
    //       }else{
    //
    //         if(data.resultType == 1) {
    //           console.log('CHIP_HELL data. resultType 1 object 无效格式');
    //         }else if(data.resultType == 0) {
    //           console.log('CHIP_HELL data. resultType 0 string 无效格式');
    //         }else {
    //           console.log(`CHIP_HELL data. resultType ${data.resultType} other 无效格式`);
    //         }
    //       }
    //     }
    //
    //     if(downloadCallBack !== undefined){
    //       if(downloadCallBack.onFinished !== undefined ){
    //         downloadCallBack.onFinished(url,fileUri.getUriFromPath(filePath),ss);
    //       }
    //     }
    //
    //     httpRequest.destroy();
    //
    // });
    // return;

  }
  /**
   * 根据文件路径或文件名称 或者 url 获取缓存文件名称
   * 只是获取文件路径，文件无法确保存在
   * @param pathOrName 文件路径或文件名称
   * @param url 图片url地址
   * @returns
   */
  static getFileName(pathOrName:string, url: string, suffix: string = '.jpg'): string{
    let fileName: string;
    if (pathOrName) {
      pathOrName = pathOrName.replace("\\", "/")
      let paths: string[] = pathOrName.split('/');
      fileName = paths[paths.length - 1];
    } else {
      url = url.replace("\\", "/")
      let paths: string[] = url.split('/');
      fileName = paths[paths.length - 1];
    }
    // 如果包含？则将？后的所有内容都去掉
    fileName = fileName.split('?')[0];

    // 从末尾往前看判断是不是0-9，a-z,A-Z
    // 正则表达式匹配0-9，a-z，A-Z和.
    const regex1 = /[0-9a-zA-Z.]/;
    const regex2 = /[0-9a-zA-Z]/;
    // 去除不合法字符
    let result = '';
    if ((!PictureCacheUtil.verifyAudioFile(fileName) && !PictureCacheUtil.verifyVideoFile(fileName) && !PictureCacheUtil.verifyImageFile(fileName))) {
      for (let i = fileName.length - 1; i >= 0; i--) {
        let st = fileName[i]
        if (regex2.test(st)) {
          result = st + result;
        }
      }
    } else {
      for (let i = fileName.length - 1; i >= 0; i--) {
        let st = fileName[i]
        if ((i>fileName.length-5 && regex1.test(st)) || (i<=fileName.length-5 && regex2.test(st))) {
          result = st + result;
        }
      }
    }

    fileName = result;
    // 如果后四位没有 . 则加上后缀
    if (!fileName.slice(-4).includes('.')) {
      fileName += suffix;
    }

    // 如果长度大于70则截断
    if (fileName.length > 70) {
      fileName = fileName.slice(-70)
    }

    return fileName
  }
  /**
   * 根据文件名称拿到文件路径
   * @param pathOrName 文件路径或文件名称
   * @param url 图片url地址
   * @returns
   */
  static getFilePath(context: Context, fileName: string): string {
    let filePath = context.filesDir + "/" + fileName;
    // 判断资源类型，根据资源类型决定放到哪个目录下
    if (PictureCacheUtil.verifyAudioFile(fileName)) {
      filePath = context.filesDir + "/" + FilePath.Audio + "/" + fileName;
    } else if (PictureCacheUtil.verifyVideoFile(fileName)) {
      filePath = context.filesDir + "/" + FilePath.Video + "/" + fileName;
    } else if (PictureCacheUtil.verifyImageFile(fileName)) {
      filePath = context.filesDir + "/" + FilePath.Image + "/" + fileName;
    } else if (PictureCacheUtil.verifyFileType(fileName) === FileType.FILE) {
      filePath = context.filesDir + "/" + FilePath.File + "/" + fileName;
    }
    return filePath;
  }
  /**
   * 根据传入的应用上下文获取下面的所有缓存文件
   * @param context
   */
  static getAllFilesByContext(context: Context, fileName: string = ''): AllFilesInterface[]{
    let filesDir: string = context.filesDir + "/" + fileName;
    let fileNames = fs.listFileSync(filesDir)

    let allFiles: AllFilesInterface[] = []
    fileNames.forEach((fileName2: string) => {
      // 判断文件类型
      let fileType = PictureCacheUtil.verifyFileType(fileName2);
      let resourceType = ResourceType.FOLDER;
      let files: AllFilesInterface[] = []

      // 判断资源类型
      if (fileType != FileType.FOLDER) {
        resourceType = PictureCacheUtil.verifyResourceType(fileName2);
      } else {
        files = PictureCacheUtil.getAllFilesByContext(context, fileName + "/" + fileName2)
      }

      let allFile: AllFilesInterface = {
        fileName: fileName2,
        fileType: fileType,
        resourceType: resourceType,
        files: files,
      }
      allFiles.push(allFile);
    })
    return allFiles
  }
  /**
   * 校验并创建目录
   * @param filePath 文件夹沙箱目录地址
   */
  static verifyFileDirectory(filePath: string): void{
    let is = fs.accessSync(filePath);
    if (is) return
    fs.mkdirSync(filePath, true)
  }
  /**
   * 校验文件是否存在
   * @param filePath 文件沙箱目录地址
   */
  static verifyFilePath(filePath: string): boolean{
    let is = fs.accessSync(filePath);
    return is;
  }
  /**
   * 传入文件名称或路径，返回文件类型
   * @param fileName
   * @returns
   */
  static verifyFileType(fileName: string): FileType {
    let fileType: FileType = FileType.FILE;
    if (!fileName.slice(-5).includes('.')) {
      fileType = FileType.FOLDER;
    }
    return fileType;
  }
  /**
   * 传入文件名称或路径，返回资源类型
   * @param fileName
   * @returns
   */
  static verifyResourceType(fileName: string): ResourceType {
    // 音频
    if (PictureCacheUtil.verifyAudioFile(fileName)) {
      return ResourceType.AUDIO;
    }
    // 视频
    if (PictureCacheUtil.verifyVideoFile(fileName)) {
      return ResourceType.VIDEO;
    }
    // 图片
    if (PictureCacheUtil.verifyImageFile(fileName)) {
      return ResourceType.IMAGE;
    }
    if (PictureCacheUtil.verifyFileType(fileName) === FileType.FOLDER) {
      return ResourceType.FOLDER;
    }
    // 否则统一为文件类型
    return ResourceType.FILE;
  }
  /**
   * 校验文件是否是音频文件
   * @param fileName
   * @returns
   */
  static verifyAudioFile(fileName: string): boolean {
    if (fileName.slice(-4).toLowerCase().includes('.cda')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.wav')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.mp3')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.aif')) {
      return true;
    }
    if (fileName.slice(-5).toLowerCase().includes('.aiff')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.mid')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.wma')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.ra')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.vqf')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.ape')) {
      return true;
    }
    return false;
  }
  /**
   * 校验文件是否是视频文件
   * @param fileName
   * @returns
   */
  static verifyVideoFile(fileName: string): boolean {
    if (fileName.slice(-4).toLowerCase().includes('.mp4')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.avi')) {
      return true;
    }
    if (fileName.slice(-5).toLowerCase().includes('.rmvb')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.mov')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.wmv')) {
      return true;
    }
    if (fileName.slice(-5).toLowerCase().includes('.mpeg')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.dat')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.flv')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.mkv')) {
      return true;
    }
    return false;
  }
  /**
   * 校验文件是否是图片文件
   * @param fileName
   * @returns
   */
  static verifyImageFile(fileName: string): boolean {
    if (fileName.slice(-4).toLowerCase().includes('.bmp')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.jpg')) {
      return true;
    }
    if (fileName.slice(-5).toLowerCase().includes('.jpeg')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.png')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.gif')) {
      return true;
    }
    if (fileName.slice(-5).toLowerCase().includes('.webp')) {
      return true;
    }
    if (fileName.slice(-5).toLowerCase().includes('.tiff')) {
      return true;
    }
    if (fileName.slice(-5).toLowerCase().includes('.heif')) {
      return true;
    }
    if (fileName.slice(-4).toLowerCase().includes('.img')) {
      return true;
    }
    return false;
  }
}