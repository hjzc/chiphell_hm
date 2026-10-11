
import { ImgDownloadCallBack, ImgDownloader, ImgDownloadParam, ImgDownloadStatus, MgLocker } from "./ImgDownloader";

export class ImgDownloadManager{
  downloadMax:number = 1;
  loopTimer :number = 1000;
  private downloadQueue:ImgDownloader[] = [];
  private  exeQueue:ImgDownloader[] = [];
  locker:MgLocker = new MgLocker();
  poolRunning :boolean =false;
  poolShouldExit :boolean =false;


  private static instance: ImgDownloadManager | undefined;

  private constructor() {

  }

  public static getInstance(): ImgDownloadManager {
    if (!ImgDownloadManager.instance) {
      ImgDownloadManager.instance = new ImgDownloadManager();
    }
    return ImgDownloadManager.instance;
  }

  downloadPathByUrl(filePath: string, url: string, downloadCallBack:ImgDownloadCallBack|undefined = undefined ) {
    let  param  = this.creatImgDownloadParam(filePath,url,downloadCallBack);
    let item = this.getExistImgDownloader(url);
    if(item !== undefined){
      item.addSameParam(param);
    }
    else{
      let downloader = new ImgDownloader (param);
      this.addDownloader(downloader);
    }
  }

  private getExistImgDownloader(url: string):ImgDownloader|undefined {
    let r:ImgDownloader|undefined ;
    for (let index = 0; index < this.downloadQueue.length; index++) {
      let element:ImgDownloader = this.downloadQueue[index];
      if(element.param.url == url){
        if(element.status < ImgDownloadStatus.WILL_END){
          r = element;
          break;
        }
      }
    }
    return r;
  }

  private creatImgDownloadParam(filePath: string, url: string, downloadCallBack:ImgDownloadCallBack|undefined = undefined ):ImgDownloadParam {
    let  param: ImgDownloadParam = new ImgDownloadParam();
    param.filePath =filePath;
    param.url =url;
    param.callBack = downloadCallBack;
    downloadCallBack!.url = url;
    downloadCallBack!.filePath = filePath;
    return param;
  }

  private addDownloader(downloader :ImgDownloader):void {
    downloader.callBack = (item:ImgDownloader, startOrEnd:boolean)=> {
      this.itemDelegateCallBack(item,startOrEnd);
    }
    this.locker.locker(()=>{
      this.downloadQueue.push(downloader);
    });
    this.checkExeQueue();
  }

  private itemDelegateCallBack(item:ImgDownloader, startOrEnd:boolean):void {
    if (startOrEnd) {
      this.locker.locker(()=>{
        let idx = this.exeQueue.indexOf(item);
        if (idx!= null  &&(idx>-1)) {
          this.exeQueue.splice(idx,1);
        }
      });
    }
  }

  private  checkExeQueue(){
    if (this.poolRunning) {
      return;
    }
    this.poolRunning = true;
    this.poolShouldExit=false;
    this.taskPool();
  }

  private async taskPool() :Promise<void>{
    return new Promise<void>(resolve => {
      this.locker.locker(()=>{
        if (this.exeQueue.length < this.downloadMax) {
          if (this.downloadQueue.length>0) {
            let item = this.downloadQueue.shift();
            if (item) {
              this.exeQueue.push(item);
              item.start();
            }
          }else{
            this.poolShouldExit = true;
          }
        }
      });
      if (this.poolShouldExit) {
        this.poolRunning=false;
      }else{
        setTimeout(() => {
          resolve(this.taskPool());
        }, this.loopTimer);
      }
    });
  }

}
































