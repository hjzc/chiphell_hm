import { fileUri } from "@kit.CoreFileKit";

export class ImgDownloadCallBack{

  url:string|undefined;
  filePath:string|undefined;
  fileValid:boolean=false;
  errorCode:number = 0;
  private  _uriPath:string|undefined;

  onStart?: (url: string) => void;
  onProgress?: (url: string,progress:number) => void;
  onFinished?: (url: string,path:string,error: boolean) => void;
  constructor() {

  }

  get uriPath():string|undefined {
    if (this._uriPath === undefined  || this._uriPath?.length<=0) {
      if( (this.filePath !== undefined) && (this.filePath.length>0) ){
        this._uriPath  = fileUri.getUriFromPath(this.filePath);
      }
    }
    return this._uriPath;
  }
}

export class ImgDownloadParam {
  url:string|undefined;
  filePath:string|undefined;
  callBack:ImgDownloadCallBack|undefined;
}