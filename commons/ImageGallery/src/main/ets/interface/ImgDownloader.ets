
import { fileUri } from "@kit.CoreFileKit";
import { PicturePreviewDataModel } from "../model/PicturePreviewDataModel";
import { http } from '@kit.NetworkKit';
import { BusinessError, SuppressWarnings, SuppressWarningsType } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { hilog } from "@kit.PerformanceAnalysisKit";
import { ArkTSUtils, taskpool } from '@kit.ArkTS';
import { rcp } from "@kit.RemoteCommunicationKit";
import { ImgDownloadParam } from "./ImgDownloadCallBack";
import { PictureCacheUtil } from "../utils/PictureCacheUtil";

export class MgLocker{
  private  lock_: ArkTSUtils.locks.AsyncLock = new ArkTSUtils.locks.AsyncLock();
   locker(run:()=>void):Promise<void> {
    return this.lock_.lockAsync(() => {
      try {
        if(run!=null){
          run();
        }
      }catch (e) {
        hilog.info(0x0000, 'CHIP_HELL','catch error :' + JSON.stringify(e));
      }
      return;
    }).catch(() => {

    });
  }
}

@Concurrent
async function globalMgThreadFunc(a: MgThread) {
  a.threadHandle();
}

export class MgThread{

  private onCall?: () => void;
  async  start(ex:()=>void):Promise<void> {
    this.onCall  = ex;
    await taskpool.execute(globalMgThreadFunc, this);
  }

  threadHandle():void{
    if(this.onCall != null  && this.onCall != undefined){
      this.onCall();
    }
  }
}

class Header {
  public contentType: string;
  public referer: string;
  public userAgent: string;
  public cookie: string;
  constructor(contentType: string,referer: string,userAgent: string,cookie: string) {
    this.contentType = contentType;
    this.referer = referer;
    this.userAgent =userAgent;
    this.cookie = cookie;
  }
}

export enum ImgDownloadStatus{
  INIT=-1,
  START =0,
  STEAM_START =1,
  STEAM_DATE_RECEIVE =2,
  HANDLE =5,
  ERROR_HANDLE =6,
  WILL_END =7,
  END =9,
}

export class ImgDownloader {
  static defaultUserAgent : string  = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0.1 Safari/605.1.15';
  static defaultUserAgentHM : string  ='Mozilla/5.0 (Phone; OpenHarmony 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36  ArkWeb/6.0.0.47 Mobile';
  onlyImg:boolean = true;

  param: ImgDownloadParam;
  private sameList:ImgDownloadParam[] = [];

  request: http.HttpRequest|undefined;

  steamRequest: http.HttpRequest|undefined;
  steamFile: fs.File | undefined;
  steamFileOffset: number = 0;

  status:ImgDownloadStatus = ImgDownloadStatus.INIT;
 // locker:MgLocker = new MgLocker();

  callBack: (item:ImgDownloader, startOrEnd:boolean)=> void = (item:ImgDownloader, startOrEnd:boolean)=>{};

  constructor(param: ImgDownloadParam) {
    this.param =param;
  }

  addSameParam(param:ImgDownloadParam):void { //Promise<void>
    this.sameList.push(param);
   // return this.locker.locker(()=>{
   //    this.sameList.push(param);
   //  })
  }

  private getRequestCaPath(domain:string|null):string|undefined{
    let r:string|undefined = undefined;
    let host :string|null=domain;
    if(host==null){
      host = this.getHeaderHost();
    }
    if(host!=null){
      r = PicturePreviewDataModel.getCaPath(host);
    }
    return r;
  }

  private getHeaderReferer():string{
    let r:string|null = null;
    if (this.param.url != null) {
      const regex = new RegExp("^(https?:\\/\\/[a-zA-Z0-9-|.]+[a-zA-Z]{2,6})"); // 创建一个全局正则表达式
      let res:RegExpMatchArray|null|undefined =  this.param.url?.match(regex);
      if((res != null) && res.length >0) {
        /// https://static.chiphell.com/  -> https://wwww.chiphell.com/
        let baseUrl = res[0];
        if (baseUrl.startsWith('https://static.',0)) {
          r = baseUrl.replace('https://static.','https://www.');
        }else if (baseUrl.startsWith('http://static.',0)) {
          r= baseUrl.replace('http://static.','http://www.');
        }else if(baseUrl.length> 5) {
          r = baseUrl;
        }
        if ( (r!= null  )&&   (r.length >0) &&  (r.charAt(r.length -1) != '/') ) {
          r = r+ '/';
        }
      }else{
      }
    }else{

    }
    if (r == null || r.length<5){
      r = PicturePreviewDataModel.getInstance().requestReferer;
    }
    if (r == null || r.length<5){
      r = 'https://www.chiphell.com/';
    }
    return r;
  }

  private getHeaderHost():string|null{
    let r:string|null = null;
    if (r == null) {
      if (this.param.url != null) {
        const regex = new RegExp("^https?:\\/\\/([a-zA-Z0-9-|.]+[a-zA-Z]{2,6})"); // 创建一个全局正则表达式
        let res:RegExpMatchArray|null|undefined =  this.param.url?.match(regex);
        if((res != null) && res.length >1) {
          r= res[1];
        }
      }else{
      }
    }
    return r;
  }

  private getHeaderUserAgent():string|null{
      return PicturePreviewDataModel.requestUserAgent??ImgDownloader.defaultUserAgent;
  }
  // header:{
  //   'Referer':'https://www.chiphell.com/',
  //   'User-Agent':ua??'',
  //   'Cookie': cookie??'',
  //   'Host': host??'',
  //   'Accept': 'image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
  //   'Accept-Encoding': 'gzip, deflate, br, zstd',
  //   'Accept-Language': 'zh-CN,zh;q=0.9',
  //   'Connection': 'keep-alive',
  //   'sec-ch-ua-platform':"Unknown",
  //   'sec-ch-ua':'"Not A(Brand";v="8", "Chromium";v="132"',
  //   'sec-ch-ua-mobile':'?0',
  //   'sec-fetch-site':'same-site',
  //   'sec-fetch-mode':'no-cors',
  //   'sec-fetch-dest':'image',
  // },
  //由于 https://static.chiphell.com/ 服务开启连接检测，中间人，所以不能验证https CA证书，否则下载失败
  //关键配置：跳过证书验证 remoteValidation: 'skip',
  //在更新证书后，可能还要加载pem证书
  private getRequestOption():http.HttpRequestOptions
  {
    let pro1_1 = true;
    let rf = this.getHeaderReferer();

   // let
    let ua = this.getHeaderUserAgent();
    //ua = ImgDownloader.defaultUserAgent;
    //ua = ImgDownloader.defaultUserAgentHM;

    let cookie = PicturePreviewDataModel.getInstance().requestCookie;
    let host = this.getHeaderHost()?? '';
    //let header :Header= new Header('',rf??'https://www.chiphell.com',ua??'',cookie??''); cookie??
    //header key 大小写不敏感
    let header: Record<string, string | number> = {
      'Accept': 'image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      'Accept-Encoding': 'gzip, deflate, br, zstd',
      'Accept-Language': 'zh-CN,zh;q=0.9',
    };
   // header['referer']='https://www.chiphell.com/thread-2774083-1-1.html?mobile=2';
    header['referer']=rf;
    header['user-agent']=ua??'';
    header['cookie']=cookie??'';
    // if (host!= null  && (host.length>4) ) {
    //   header['host']=host??''; // HTTP/1.1 唯一必须包含的请求头
    //   pro1_1= true;
    // }
    /// "certificates": "/data/storage/el1/bundle/default/resources/resfile/sectigo_chain.pem"
    // /data/storage/el1/base/haps/default/files/certs/static-chiphell-com.pem
    // /data/storage/el1/base/haps/default/files/certs/sectigo_chain.pem
    //let pemPath ="/data/storage/el1/bundle/default/resources/resfile/sectigo_chain.pem";
    //let pemPath ='/data/storage/el1/bundle/default/resources/resfile/domainCaCert'; [http_exec.cpp:
    let pemPath = this.getRequestCaPath(host);
    // try {
    //   let pemStr = fs.readTextSync(pemPath);
    //   if(pemStr){//http_exec.cpp:
    //     hilog.info(0x0000, 'CHIP_HELL', `domain:${host}, pem path:${pemPath},content: \n${pemStr}`);
    //   }else{
    //     hilog.info(0x0000, 'CHIP_HELL', `domain:${host}, pem path:${pemPath},content: is null`);
    //   }
    // }catch (e) {
    //   hilog.info(0x0000, 'CHIP_HELL','catch error :' + JSON.stringify(e));
    // }


    //HTTP/1.1引入了持久连接的概念
    // 1）客户端发送一个请求到服务器，并在请求头中包含Connection: keep-alive字段，表示希望保持连接。
    // （2）服务器接收到请求后，发送相应的响应给客户端，并在响应头中也包含Connection: keep-alive字段，表示服务器同意保持连接。
    // （3）在保持连接的状态下，客户端可以继续发送其他请求到服务器，而不需要重新建立连接。
    // （4）服务器接收到这些额外的请求后，分别处理请求并发送相应的响应。
   // header['Connection']= 'keep-alive';

    if (this.param.url?.startsWith('https',0)) {
      header['sec-ch-ua-platform']='Unknown';
      header['sec-ch-ua']='Not A(Brand";v="8", "Chromium";v="132"';
      header['sec-ch-ua-mobile']='?0';
      header['priority']='i';

      header['sec-fetch-site']='same-site';
      header['sec-fetch-dest']='image';
      header['sec-fetch-mode']='no-cors';
      //header['priority']=' u=1, i';
     // header['priority']=' u=3, i';
    }
    let op : http.HttpRequestOptions =  {
      method: http.RequestMethod.GET,
      connectTimeout: 30000,
      readTimeout: 30000,
      maxLimit: 100 * 1024 * 1024,
      usingCache:false,
      header:header,
      //remoteValidation: 'system',
     // remoteValidation: 'skip', // 关键配置：跳过证书验证,因为chip hell的static
      //usingProtocol可能无效。一个系统bug，会自动协商到http3,导致被拦截
      usingProtocol:pro1_1?http.HttpProtocol.HTTP1_1 : http.HttpProtocol.HTTP2,

      //在HTTP/1.1中，每个请求都可以带有一个优先级（priority）信息，用于指示请求的重要性或紧急程度。
      //请求头部添加Priority字段来指定。该字段的值可以是urgency（紧急）或immediacy（即时）
      //header['Priority']=' u=3, i';
      //这里不支持
      //[1, 1000], default is 1.
      //priority:1,

    //  usingProxy: false, // 可选，默认不使用网络代理，自API 10开始支持该属性
      //浏览器打开，到处pem证书，加载 /data/storage/el1/base/haps/default/files/certs/static-chiphell-com.pem
      caPath:  pemPath,
    //  caPath:'/data/storage/el1/bundle/default/resources/resfile/sectigo_chain.pem',

     // extraData: { isRedirect: false },
      //expectDataType: http.HttpDataType.ARRAY_BUFFER,
    };

    return op;
  }


  private  destroy():void {
    if (this.request!= null && this.request!= undefined ) {
      this.request.off('headersReceive');
      this.request.destroy();
      this.request=undefined;
    }
  }

  private cleanSteamFile():void{

    if(this.steamFile!==undefined ){
      fs.close(this.steamFile.fd).catch(() => {
        // TODO: Implement error handling.
      });
      this.steamFile = undefined;
    }
  }

  private destroySteamRequest():void {
    this.cleanSteamFile();
    if (this.steamRequest!= null && this.steamRequest!= undefined ) {
      this.steamRequest.off('dataReceive');
      // 取消订阅HTTP流式响应数据发送进度事件。
      this.steamRequest.off('dataSendProgress');
      // 取消订阅HTTP流式响应数据接收进度事件。
      this.steamRequest.off('dataReceiveProgress');
      // 取消订阅HTTP流式响应数据接收完毕事件。
      this.steamRequest.off('dataEnd');
      this.steamRequest.destroy();
      this.steamRequest.off('headersReceive');
      this.steamRequest=undefined;
    }
  }

  isDownloading():boolean{
    return this.request != null || this.steamRequest!=null;
  }

  private writeBufferToFile(buffer :ArrayBuffer):boolean {
    return PictureCacheUtil.writeBufferToFile(this.param.filePath,buffer);
  }

  @SuppressWarnings({ rules: [SuppressWarningsType.PERMISSION] })
  start(): void {
    if (this.isDownloading()) {
      return;
    }
    this.status = ImgDownloadStatus.START;
    //import http from '@ohos.net.http';
    this.param.callBack!.fileValid = false;
    this.request = http.createHttp();
    this.request.on('headersReceive', (header) => {
      // let rc :Record<string, string | number> = header as  Record<string, string | number>;
      // const finalUrl = rc['Location'];
      hilog.info(0x0000, 'CHIP_HELL:', 'header: ' + JSON.stringify(header));
    });
    this.downloadStart();
    this.request.request(this.param.url, this.getRequestOption(),
      async (err: BusinessError, data: http.HttpResponse) => {
        let isSteamRetry = err && (err.code == 2300023);
        if (err) {
          if (isSteamRetry) {
            //大于100MB需要流下载方式
            this.destroy();
            new Promise<void>(resolve => {
              this.startSteamRequest();
            });
            return;
          } else {
            //失败
            this.status = ImgDownloadStatus.ERROR_HANDLE;
            this.param.callBack!.errorCode = err.code;
          }
        } else if (data) {
          hilog.info(0x0000, 'CHIP_HELL',
            `CHIP_HELL data. resultType:${data.resultType},responseCode: ${data.responseCode} `);
          this.status = ImgDownloadStatus.HANDLE;
          if (this.onlyImg) {
            if (data.resultType == http.HttpDataType.ARRAY_BUFFER) {
              if (data.responseCode == 200) {
                this.param.callBack!.errorCode = 0;
                this.param.callBack!.fileValid = this.writeBufferToFile(data.result as ArrayBuffer);
                // 文件保存成功 /data/storage/el2/base/haps/default/files/MediaLibrary_Image/081136j54da155qdicrat1.jpg
                hilog.info(0x0000, 'CHIP_HELL', "downloadPathByUrl 文件保存成功 " + this.param.filePath);
              } else {
                this.param.callBack!.errorCode = -3;
                this.param.callBack!.fileValid = false;
              }
            } else {
              this.param.callBack!.errorCode = data.responseCode == 200 ? -4 : -1;
              this.param.callBack!.fileValid = false;
              if (data.resultType == http.HttpDataType.OBJECT) {
                hilog.info(0x0000, 'CHIP_HELL', `CHIP_HELL data. resultType 1 object 无效格式 `);
              } else if (data.resultType == http.HttpDataType.STRING) {
                hilog.info(0x0000, 'CHIP_HELL', `CHIP_HELL data. resultType 0 string : ${data.result} `);
              } else {
                hilog.info(0x0000, 'CHIP_HELL', `CHIP_HELL data. resultType ${data.resultType} other 无效格式`);
              }
            }
          } else {
            this.param.callBack!.errorCode = 0;
            this.param.callBack!.fileValid = this.writeBufferToFile(data.result as ArrayBuffer);
            hilog.info(0x0000, 'CHIP_HELL', `CHIP_HELL download data end`);
          }
        } else {
          this.param.callBack!.errorCode = -2;
          this.param.callBack!.fileValid = false;
          hilog.info(0x0000, 'CHIP_HELL', `CHIP_HELL download data. is null`);
        }
        this.destroy();
        this.status = ImgDownloadStatus.WILL_END;
        this.downloadEnd();
        //this.startRcp();
      });
  }

  private startSteamRequest():void{
    if (this.isDownloading()) {
      return;
    }
    this.status = ImgDownloadStatus.STEAM_START;
    this.param.callBack!.fileValid = false;
    this.steamRequest = http.createHttp();
    try {
      this.steamFile = fs.openSync(this.param.filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    } catch (error) {
      // TODO: Implement error handling.
    }
    this.steamFileOffset = 0;

    this.steamRequest.on('headersReceive', (header) => {
      hilog.info(0x0000, 'CHIP_HELL','steam receive header: ' + JSON.stringify(header));
    });

    // 订阅HTTP流式响应数据接收事件
    this.steamRequest.on('dataReceive', (data: ArrayBuffer) => {
     if( this.status == ImgDownloadStatus.STEAM_START){
       this.status = ImgDownloadStatus.STEAM_DATE_RECEIVE;
     }
      let len =data.byteLength;
      hilog.info(0x0000, 'CHIP_HELL', `dataReceive length: ${len}`);
      if(len>0){
        //writeSync
        let writeLen =0;
        try {
          hilog.info(0x0000, 'CHIP_HELL', `start syn write length: ${len}`);
          writeLen = fs.writeSync(this.steamFile!.fd, data, { offset: this.steamFileOffset, length: data.byteLength });
          hilog.info(0x0000, 'CHIP_HELL', `end syn write length: ${writeLen}`);
          if (writeLen>0) {
            this.steamFileOffset +=writeLen;
          }
        } catch (error) {
          // TODO: Implement error handling.
          hilog.info(0x0000, 'CHIP_HELL', ` syn write error : ${JSON.stringify(error)}`);
        }
      }
    });

    // 用于订阅HTTP流式响应数据接收完毕事件。
    this.steamRequest.on('dataEnd', () => {
      hilog.info(0x0000, 'CHIP_HELL',`No more data in response, data receive end,write length:${this.steamFileOffset}}`);
      this.cleanSteamFile();
    });

    // 订阅HTTP流式响应数据接收进度事件，下载服务器的数据时，可以通过该回调获取数据下载进度。
    this.steamRequest.on('dataReceiveProgress', (data: http.DataReceiveProgressInfo) => {
      hilog.info(0x0000, 'CHIP_HELL', 'dataReceiveProgress receiveSize:' + data.receiveSize + ', totalSize:' + data.totalSize);
    });

    this.steamRequest.requestInStream(this.param.url, this.getRequestOption())
      .then((data: number) => {
        hilog.info(0x0000, 'CHIP_HELL', `requestInStream OK!`);
        hilog.info(0x0000, 'CHIP_HELL', `ResponseCode : ${JSON.stringify(data)}`);
        this.status = ImgDownloadStatus.HANDLE;
        this.cleanSteamFile();
        this.param.callBack!.errorCode = 0;
        this.param.callBack!.fileValid = true; // fs.accessSync(this.param.filePath);
        this.destroySteamRequest();
        this.status = ImgDownloadStatus.WILL_END;
        this.downloadEnd();
      }).catch((err: Error) => {
        this.status = ImgDownloadStatus.ERROR_HANDLE;
        hilog.error(0x0000, 'CHIP_HELL', `requestInStream ERROR : err = ${JSON.stringify(err)}`);
        this.param.callBack!.fileValid = false;
        if(this.param!=null && (this.param.callBack!=null) ){
          this.param.callBack!.errorCode = -1;
        }
        // 取消订阅步骤3中订阅的事件，并调用destroy方法主动销毁。
        this.destroySteamRequest();
        this.status = ImgDownloadStatus.WILL_END;
        this.downloadEnd();
    });
  }

  private downloadStart() {
    if(this.param.callBack !== undefined  && (this.param.callBack.onStart !== undefined )){
      this.param.callBack.onStart(this.param.url!);
    }
    for (let i = 0; i < this.sameList.length; i++) {
      const element = this.sameList[i];
      element.callBack!.errorCode = this.param.callBack!.errorCode;
      element.callBack!.fileValid = this.param.callBack!.fileValid;
     // element.callBack!.errorCode = this.param.callBack!.errorCode;
      if(element.callBack !== undefined  && (element.callBack.onStart !== undefined )){
        element.callBack.onStart(element.url!);
      }
    }
    if (this.callBack!=null) {
      this.callBack( this,false);
    }
  }

  private downloadEnd() {
    new Promise<void>(resolve => {
      this.status = ImgDownloadStatus.END;
      if(this.param.callBack !== undefined  && (this.param.callBack.onFinished !== undefined )){
        this.param.callBack.onFinished(this.param.url!,this.param.callBack.uriPath!,this.param.callBack.errorCode !=0);
      }
      for (let i = 0; i < this.sameList.length; i++) {
        const element = this.sameList[i];
        element.callBack!.errorCode = this.param.callBack!.errorCode;
        element.callBack!.fileValid = this.param.callBack!.fileValid;
       // element.callBack!.errorCode = this.param.callBack!.errorCode;
        if(element.callBack !== undefined  && (element.callBack.onFinished !== undefined )){
          element.callBack.onFinished(element.url!,element.callBack.uriPath! ,element.callBack.errorCode !=0);
        }
      }
      if (this.callBack!=null) {
        this.callBack( this,true);
      }
    });
  }




  // startRcp():void{
  //   let securityConfig: rcp.SecurityConfiguration = {
  //     remoteValidation: 'skip'  // 显式跳过SSL验证
  //   };
  //   try {
  //     const session = rcp.createSession({
  //       requestConfiguration: { security: securityConfig }
  //     });
  //     // 发起HTTPS请求
  //     session.get(this.param.url)
  //       .then((response: rcp.Response) => {
  //         // 处理响应数据
  //         //this.status = ImgDownloadStatus.WILL_END;
  //         //this.downloadEnd();
  //         hilog.info(0x0000, 'CHIP_HELL', ` rcp response statusCode: ${response.statusCode}`);
  //
  //       });
  //   } catch (error) {
  //     // TODO: Implement error handling.
  //   }
  // }



}

































