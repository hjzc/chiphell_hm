import fs from '@ohos.file.fs';
import { http } from '@kit.NetworkKit';
import { fileUri } from '@kit.CoreFileKit';
import { Context } from '@ohos.arkui.UIContext';
import { AllFilesInterface, FileType, ResourceType } from '../../../../Index';
import { FilePath } from '../model/FilePath';
import { ImgDownloadManager } from '../interface/ImgDownloadManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { PicturePreviewDataModel } from '../model/PicturePreviewDataModel';
import { ImgDownloadCallBack } from '../interface/ImgDownloadCallBack';
import { hilog } from '@kit.PerformanceAnalysisKit';

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
  private static downloadPathByUrl(filePath: string, url: string,downloadCallBack:ImgDownloadCallBack|undefined = undefined ):void  {
    //拦截器
    let vv = PicturePreviewDataModel.getInstance().downloadIntercept;
    if(vv && vv?.isDownloadIntercept(url)){
      vv.downloadPathByUrl(filePath,url,downloadCallBack);
    }else{
      ImgDownloadManager.getInstance().downloadPathByUrl(filePath,url,downloadCallBack);
    }
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

  static  async isImageByContent(filePath: string): Promise<boolean> {
    let r:boolean = false;
    try {
      let file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      let buffer = new ArrayBuffer(8); // 读取前8字节
      await fs.read(file.fd, buffer);
      const view = new Uint8Array(buffer);
      await fs.close(file.fd);
      if(view[0] == 0xFF && view[1] == 0xD8 ){
        r= true;
      }else if(view[0] == 0x47  && view[1] == 0x49  && view[2] == 0x46  ){
        r= true;
      }else if(view[0] == 0x89 && view[1] == 0x50 && view[2] == 0x4E && view[3] == 0x47 ){
        r= true;
      }
      return r;
    } catch (e) {
      return false;
    }
  }

  static  writeBufferToFile(filePath:string|undefined, buffer :ArrayBuffer):boolean {
    let r:boolean  =false;
    if(filePath) {
      try {
        // 打开并创建文件目录
        let we: boolean = true;
        let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.write(file.fd, buffer).catch(() => {
          // TODO: Implement error handling.
          we = false;
        });
        fs.close(file.fd).catch(() => {
          // TODO: Implement error handling.
          we = false;
        });
        r = we;
      } catch (e) {
        let err: BusinessError = e as BusinessError;
        hilog.info(0x0000, 'CHIP_HELL', `writeBufferToFile error code: ${err.code}, message:${err.message}`);
      }
    }
    return r;
  }
}