import { rcp } from '@kit.RemoteCommunicationKit';
import { logger } from 'utils';
import { env } from '../../Storage/ZjEnv';
import { http, networkSecurity } from '@kit.NetworkKit';
import { FileUtil } from '../../utils/FileUtil';
import { ArrayBufferUtil } from '../../utils/ArrayBufferUtil';
import { DateUtil } from '../../utils/DateUtil';
import { AppUtil } from '../../utils/AppUtil';
import fs from '@ohos.file.fs';

export  class BCDownloader {
  private static instance: BCDownloader | undefined;
  private session: rcp.Session | null = null;
  private static pcUa:string = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0.1 Safari/605.1.15';
  private static devUa:string ='Mozilla/5.0 (Phone; OpenHarmony 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36  ArkWeb/6.0.0.47 Mobile';
  static  appCaPath:string = '/data/storage/el1/bundle/default/resources/resfile/domainCaCert/sectigo_chain.pem';
  private constructor() {

  }

  public static getInstance(): BCDownloader {
    if (!BCDownloader.instance) {
      BCDownloader.instance = new BCDownloader();
    }
    return BCDownloader.instance;
  }

  private  initSession():void{
    if(this.session){
      return;
    }
    let header: rcp.RequestHeaders = {
      'user-agent': BCDownloader.devUa,
      'accept': 'image/avif,image/webp,image/png,image/svg+xml,image/*;q=0.8,*/*;q=0.5',
      'accept-language': 'zh-CN,zh;q=0.9,zh-TW;q=0.8,zh-HK;q=0.7,en-US;q=0.6,en;q=0.5',
      'accept-encoding': ['gzip', 'deflate', 'br', 'zstd'],
      'referer': 'https://www.chiphell.com/'
    };

    header['sec-ch-ua-platform']='Unknown';
    header['sec-ch-ua']='Not A(Brand";v="8", "Chromium";v="132"';
    header['sec-ch-ua-mobile']='?0';
    header['priority']='i';
    header['sec-fetch-site']='same-site';
    header['sec-fetch-dest']='image';
    header['sec-fetch-mode']='no-cors';
    try {
      this.session = rcp.createSession({
        requestConfiguration: {
          security: {
            remoteValidation: {
              filePath: BCDownloader.appCaPath
            }
          }
        },
        headers: header,
      });

    } catch (error) {
      // TODO: Implement error handling.
      console.error(`rcp createSession err:${JSON.stringify(error)}`);
    }
  }

  start(uiContext: UIContext ,url:string,refStr:string):void{
   // this.startAxios(uiContext,url,refStr);
  }

  startRcp(uiContext: UIContext ,url:string,refStr:string):boolean{
    // 注意：session 不要创建为局部变量，要作为成员变量复用
    let r:boolean =false;
    if (!this.session) {
      this.initSession();
    }
    if (this.session) {
      // 发起请求
      r=true;
      this.session.get(url).then((response) => {
        // response.body 是 ArrayBuffer
        if(response.statusCode==567){
          console.error(`rcp err: 567`);
        }else{
          console.error(`response.statusCode: ${response.statusCode}`);
        }
        // let imgData: ArrayBuffer = response.body as ArrayBuffer;
        // BCDownloader.handleRcpResponse(response);
      }).catch((err:Error) => {
        console.error(`rcp err: ${err?.name}, ${err.message}`);
      });
    }else{
      logger.info('CHIP_HELL', ` rcp session create failed`);
    }
    return r;
  }
  //
  // public  startAxios(uiContext: UIContext ,url:string,refStr:string):void{
  //   // /data/storage/el2/base/haps/default/cache/chiphell_image.jpg
  //   const filePath =uiContext.getHostContext()?.cacheDir + '/chiphell_image.jpg';
  //   // 若文件已存在需先删除，否则下载会失败
  //   try {  fs.accessSync(filePath); fs.unlinkSync(filePath); } catch (e) {}
  //   axios({
  //     url: url,
  //     method: 'get',
  //     filePath: filePath,
  //     caPath:  BCDownloader.appCaPath, // 自定义证书路径
  //     headers: {
  //       'User-Agent': BCDownloader.devUa,
  //       'Accept': 'image/avif,image/webp,image/png,image/svg+xml,image/*;q=0.8,*/*;q=0.5',
  //       'Accept-Language': 'zh-CN,zh;q=0.9,zh-TW;q=0.8,zh-HK;q=0.7,en-US;q=0.6,en;q=0.5',
  //       'Accept-Encoding':'gzip,deflate,br,zstd',
  //       'Referer': 'https://www.chiphell.com/'
  //     },
  //     onDownloadProgress: (e) => {
  //       let percent = e?.total ? Math.ceil(e.loaded / e.total * 100) : 0
  //       console.info(`下载进度: ${percent}%`)
  //     }
  //   }).then(() => {
  //     console.info('图片已下载到: ' + filePath);
  //   }).catch((error:AxiosError)=>{
  //     logger.error('CHIP_HELL', ` axios get error:${JSON.stringify(error)}`);
  //   });
  // }

  // private  static  handleRcpResponse(response: rcp.Response){
  //   if (response.statusCode==200) {
  //     let contentType = response.headers['content-type'] ;
  //     //image/png
  //     let path = FileUtil.getTempDirPath('','temp_'+ DateUtil.getFormatDateStr(new Date(),) +'.jpeg',false);
  //      // if (FileUtil.accessSync(path)) {
  //      //    FileUtil.unlinkSync(path);
  //      // }
  //     if(response.body!=null){
  //        ArrayBufferUtil.WriteBufferToFile(response.body,path);
  //     }
  //   }else{
  //     if (response.statusCode==567) {
  //       //text/html; charset=UTF-8
  //       let contentType = response.headers['content-type'] ;
  //     }
  //     logger.info('CHIP_HELL', ` rcp response: ${response.toString()}`);
  //   }
  // }

  //校验证书的日期是否符合预期。https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-customsecurityconfig#section10766830174317
  static  makeItTwoChar(s: string): string {
    if (s.length === 1) {
      return '0' + s;
    }
    return s;
  }
  static getASNDateString(): string {
    const date = new Date();
    let dateStr = date.getFullYear().toString().slice(2);
    dateStr += BCDownloader.makeItTwoChar((date.getMonth() + 1).toString());
    dateStr += BCDownloader.makeItTwoChar(date.getDate().toString());
    dateStr += BCDownloader.makeItTwoChar(date.getHours().toString());
    dateStr += BCDownloader.makeItTwoChar(date.getMinutes().toString());
    dateStr += BCDownloader.makeItTwoChar(date.getSeconds().toString());
    return dateStr + 'Z';
  }
  static async  ValidationRemoteServer(context: rcp.ValidationContext): Promise<boolean> {
    // 服务器未返回证书，校验失败
    let length = context.pemCerts.length;
    if (length <= 0) {
      return Promise.reject();
    }
    // 此示例中最后一个证书为根证书，开发中请根据实际情况调整
    const firstCaBlob: networkSecurity.CertBlob = {
      type: networkSecurity.CertType.CERT_TYPE_PEM,
      data: context.pemCerts[length - 1],
    }
    // 如果 certVerificationSync 的第二个参数未填写，则使用系统默认的 CA（"/etc/security/certificates"）进行验证
    if (networkSecurity.certVerificationSync(firstCaBlob) !== 0) {
      return Promise.reject();
    }
    // 此处可以添加所需的校验逻辑，如校验日期
    for (const x of context.x509Certs) {
      let dateStr = BCDownloader.getASNDateString();
      try {
        x.checkValidityWithDate(dateStr);
      } catch (e) {
        return Promise.reject();
      }
    }
    // 校验成功
    return Promise.resolve(true);
  }


  // static startHttp(url:string,refStr:string,pemPath:string):void{
  //   let capath = env.getChiphellCaPath();
  //   let httpRequest = http.createHttp();
  //   httpRequest.request(
  //     url,
  //     {
  //       header:{
  //         'user-agent':'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:157.0) Gecko/20100101 Firefox/157.0',
  //         'Accept':'image/avif,image/webp,image/png,image/svg+xml,image/*;q=0.8,*/*;q=0.5',
  //         'Accept-Language':'zh-CN,zh;q=0.9,zh-TW;q=0.8,zh-HK;q=0.7,en-US;q=0.6,en;q=0.5',
  //         'Accept-Encoding':'gzip, deflate, br, zstd',
  //         'Referer':'https://www.chiphell.com/'
  //       },
  //       method: http.RequestMethod.GET,
  //       usingProtocol: http.HttpProtocol.HTTP1_1,//参数无效
  //       caPath: capath,
  //      // caData:BCDownloader.PEM_CA,//只支持单证书，不支持证书链，要放的是“签发者的证书”，
  //     },
  //     (err, data) => {
  //       if (!err) {
  //         // 成功
  //         if( data.responseCode === 200){
  //           logger.info('CHIP_HELL', `http 下载成功`);
  //         }
  //         else if(data.responseCode === 567){
  //           //[http_exec.cpp:500] taskid=-2147483647, size:7352, dns:0.027, connect:0.000, tls:0.000,
  //           //tls 为0 说明证书无效
  //           logger.info('CHIP_HELL', `http 下载失败`);
  //         }else{
  //           logger.info('CHIP_HELL', `http 下载错误`);
  //         }
  //
  //       }
  //     }
  //   );
  // }


}