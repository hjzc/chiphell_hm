import { ImgDownloadCallBack, ImgDownloadParam, PictureDownloadIntercept } from 'imagegallery';
import { ZzjWebDownload } from '../web/Zzj/ZzjWebDownload';
import { webview } from '@kit.ArkWeb';
import { ObjectUtil } from '../utils/ObjectUtil';
import { AppUtil } from '../utils/AppUtil';
import { FileUtil } from '../utils/FileUtil';

export enum DownloadTokenStatus{
  INIT=-1,
  START =0,
  DOWNLOADING =1,
  HANDLE =5,
  ERROR_HANDLE =6,
  WILL_END =7,
  END =9,
}

//type X = DownloadToken[]
export  class DownloadToken {
  status:DownloadTokenStatus = DownloadTokenStatus.INIT;
  webSavePath:string|undefined;
  error:boolean|undefined;
  progress:number|undefined;

  param: ImgDownloadParam;
  private sameList:ImgDownloadParam[] = [];

  item: webview.WebDownloadItem|undefined;

  constructor(param:ImgDownloadParam){
    this.param =param;
  }

  addSameParam(param:ImgDownloadParam):void {
    this.sameList.push(param);
  }

  isEqualParam(param:ImgDownloadParam):boolean {
    return param.url == this.param.url;
  }

  isEqual(token:DownloadToken):boolean {
    return token.param.url == this.param.url;
  }

  ///开始执行出现错误
  startError():void {
    this.status= DownloadTokenStatus.ERROR_HANDLE;
    this.param.callBack!.errorCode=-1;
    this.param.callBack!.fileValid =false;
    this.callbackEnd();
  }
  willStart(webSavePath:string,item: webview.WebDownloadItem):void{
    if(this.status!= DownloadTokenStatus.START){
      this.status= DownloadTokenStatus.START;
    }
    this.webSavePath =webSavePath;
    this.callBackStart();
  }
  updateProgress(progress:number,item: webview.WebDownloadItem):void{
    if(this.status!= DownloadTokenStatus.DOWNLOADING){
      this.status= DownloadTokenStatus.DOWNLOADING;
    }
    if(this.progress != progress){
      this.progress =progress;
      this.callBackProgress(progress);
    }
  }
  end(error:boolean,item: webview.WebDownloadItem):void{
    this.error =error;
    if(error){
      this.param.callBack!.errorCode=item.getLastErrorCode();
      this.param.callBack!.fileValid =false;
      this.status= DownloadTokenStatus.ERROR_HANDLE;
      this.callbackEnd();
    }else{
      //copy file to target
      if(this.webSavePath && this.param.filePath){
        this.status= DownloadTokenStatus.HANDLE;
        FileUtil.moveFile(this.webSavePath,this.param.filePath).then(()=>{
          this.param.callBack!.errorCode=0;
          this.param.callBack!.fileValid =true;
          this.status= DownloadTokenStatus.WILL_END;
          this.callbackEnd();
        }).catch(()=>{
          this.param.callBack!.errorCode=-4;
          this.param.callBack!.fileValid =false;
          this.status= DownloadTokenStatus.WILL_END;
          this.callbackEnd();
        });
      }else{
        this.param.callBack!.errorCode=-1;
        this.param.callBack!.fileValid =false;
        this.status= DownloadTokenStatus.WILL_END;
        this.callbackEnd();
      }
    }
  }

  private callBackStart() {
    if(this.param.callBack !== undefined  && (this.param.callBack.onStart !== undefined )){
      this.param.callBack.onStart(this.param.url!);
    }
    for (let i = 0; i < this.sameList.length; i++) {
      const element = this.sameList[i];
      element.callBack!.errorCode = this.param.callBack!.errorCode;
      element.callBack!.fileValid = this.param.callBack!.fileValid;
      if(element.callBack !== undefined  && (element.callBack.onStart !== undefined )){
        element.callBack.onStart(element.url!);
      }
    }
  }
  private callBackProgress(progress:number) {
    if(this.param.callBack !== undefined  && (this.param.callBack.onProgress !== undefined )){
      this.param.callBack.onProgress(this.param.url!,progress);
    }
    for (let i = 0; i < this.sameList.length; i++) {
      const element = this.sameList[i];
      if(element.callBack !== undefined  && (element.callBack.onProgress !== undefined )){
        element.callBack.onProgress(element.url!,progress);
      }
    }
  }

  private callbackEnd() {
    new Promise<void>(resolve => {
      this.status = DownloadTokenStatus.END;
      if (this.param.callBack !== undefined && (this.param.callBack.onFinished !== undefined)) {
        this.param.callBack.onFinished(this.param.url!, this.param.callBack.uriPath!,
          this.param.callBack.errorCode != 0);
      }
      for (let i = 0; i < this.sameList.length; i++) {
        const element = this.sameList[i];
        element.callBack!.errorCode = this.param.callBack!.errorCode;
        element.callBack!.fileValid = this.param.callBack!.fileValid;
        if (element.callBack !== undefined && (element.callBack.onFinished !== undefined)) {
          element.callBack.onFinished(element.url!, element.callBack.uriPath!, element.callBack.errorCode != 0);
        }
      }
    });
  }
}

export  class  WebImageDownloader implements PictureDownloadIntercept,ZzjWebDownload {
  controller?: webview.WebviewController;
  private enableBrowserDownload:boolean = false;
  private preTokens: Map<string, DownloadToken> =  new Map();
  private downloadingTokens: Map<string, DownloadToken> = new Map();

  constructor(enableBrowser:boolean) {
    this.enableBrowserDownload =enableBrowser;
  }

  onDownloaderBrowserUrl?(url:string):boolean{
    let r:boolean=false;
    if( this.enableBrowserDownload) {
      r=this.startDownload(url);
    }
    return r;
  }

  private startDownload(url:string):boolean{
    let r:boolean=false;
    try {
      this.controller?.startDownload(url);
      r = true;
    } catch (error) {
      // TODO: Implement error handling.
    }
    return r;
  }

  setWebviewController(controller: webview.WebviewController): void{
    this.controller = controller;
  }

  onFileDownloadStart?(item: webview.WebDownloadItem,url: string,guid:string,filename:string,savePath:string): boolean{
    let r:boolean =false;
    if(this.preTokens.has(url)){
      let token = this.preTokens.get(url);
      if(token){
        token.status =DownloadTokenStatus.START;
        this.downloadingTokens.set(url,token);
        this.preTokens.delete(url);
        token.item=item;
        token.willStart(savePath,item);
        r=true;
      }
    }
    return r;
  }

  onFileDownloadProgress?(item: webview.WebDownloadItem,url: string,guid:string,filename:string,progress:number): boolean{
    let r:boolean =false;
    if(this.downloadingTokens.has(url)){
      let token = this.downloadingTokens.get(url);
      if(token){
        token.updateProgress(progress/100.0,item);
      }
      r=true;
    }
    return r;
  }

  onFileDownloadFinished?(item: webview.WebDownloadItem,failed:boolean): boolean{
    let r:boolean =false;
    let url =item.getUrl();
    if(this.downloadingTokens.has(url)){
      let token = this.downloadingTokens.get(url);
      if(token){
        token.status =DownloadTokenStatus.END;
        token.end(failed,item);
      }
      this.downloadingTokens.delete(url);
      r=true;
    }
    return r;
  }

  ///图片后台下载
  isDownloadIntercept (url: string):boolean{
    if(url.indexOf('https://static.chiphell.com')!=0){
      return false;
    }
    return true;
  }

  downloadPathByUrl(filePath: string, url: string,downloadCallBack:ImgDownloadCallBack|undefined):void{
    let  param  = this.createImgDownloadParam(filePath,url,downloadCallBack);
    let item = this.getExistDownloaderToken(url);
    if(item !== undefined){
      item.addSameParam(param);
    }
    else{
      let token = new DownloadToken (param);
      this.preTokens.set(url,token);
      let r=this.startDownload(url);
      if(r==false){
        token.startError();
        this.preTokens.delete(url);
      }
    }
  }

  private createImgDownloadParam(filePath: string, url: string, downloadCallBack:ImgDownloadCallBack|undefined = undefined ):ImgDownloadParam {
    let  param: ImgDownloadParam = new ImgDownloadParam();
    param.filePath =filePath;
    param.url =url;
    param.callBack = downloadCallBack;
    downloadCallBack!.url = url;
    downloadCallBack!.filePath = filePath;
    return param;
  }

  private getExistDownloaderToken(url: string):DownloadToken|undefined {
    let r:DownloadToken|undefined;
    if(this.preTokens.has(url)){
      r= this.preTokens.get(url);
    }else if(this.downloadingTokens.has(url)){
      r= this.downloadingTokens.get(url);
    }
    return r;
  }

}