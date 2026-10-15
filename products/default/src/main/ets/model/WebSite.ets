import { logger } from "utils";
import { RegexUtil } from "../utils/RegexUtil";
import { getSiteManager, SiteConstants } from "./Site";

export  enum AccessSiteType {
  auto = -1,
  mobile = 0,
  pc =1,
}

// implements ISite
@ObservedV2
export  class  WebSite{
  private defaultUA:string = '';
  private static pcDefaultUA:string = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0.1 Safari/605.1.15";
  // private static mbDefaultUA:string = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1";
  private static mbDefaultUA:string = 'Mozilla/5.0 (Phone; OpenHarmony 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36  ArkWeb/6.0.0.47 Mobile';

  @Trace accessType : AccessSiteType = AccessSiteType.auto;
  @Trace stopUrl:string= '';

  //当前设备是否为phone
  isPhone:boolean = false;
  lastUrl:string = '';
  userToken:string = '';
  title:string = '';
  startUrl:string = '';

  // static  host:string = 'www.chiphell.com';
  // static  base:string = 'https://www.chiphell.com';
  //
  // private static home:string = 'https://www.chiphell.com/';
  // private static forum:string = 'https://www.chiphell.com/forum.php';
  // private static login:string = 'https://www.chiphell.com/member.php?mod=logging&action=login';
  // private static mbHomes:Array<string> = ['https://www.chiphell.com/index.php?mobile=2','https://www.chiphell.com/index.php','https://www.chiphell.com/',];
  // private static mbForums:Array<string> = ['https://www.chiphell.com/forum.php','https://www.chiphell.com/forum.php?mobile=2'];
  // private static mbLogin:string = 'https://www.chiphell.com/member.php?mod=logging&action=login&mobile=2';

  //theme:ConfigurationConstant.ColorMode
  constructor(){
    //super()
  //  this.theme =theme;
    // this.defaultUA = defaultUA;
    // this.isPhone  = isPhone;
    // this.userName = userName;
    // this.userToken = userToken;
  }

  setDefaultUA(ua:string):void{
    this.defaultUA = ua;
    if ((this.accessType === AccessSiteType.auto)) {
       if(this.isPhone){
         this.accessType = AccessSiteType.mobile;
       }else{
         this.accessType = AccessSiteType.pc;
       }
    }
  }
  getDefaultUA():string{
    return this.defaultUA;
  }

  firstLoadUrl():string {
    let url:string= this.lastUrl;
    if ((this.lastUrl.length<10) ) {
      url = this.homeUrl();
    }
    return url;
  }

  isLogin():boolean{
    return this.userToken!=null && (this.userToken.length>0);
  }

  isUseMobile():boolean{
    return this.accessType === AccessSiteType.mobile || (this.isPhone && (this.accessType === AccessSiteType.auto) );
  }

  toggleMobileOrPc():void{
    if(this.isUseMobile()){
      this.accessType = AccessSiteType.pc;
    }else{
      this.accessType = AccessSiteType.mobile;
    }
  }

  startJSPre(debug:boolean =false):string{
    let f = (debug?'true':'false');
    return 'function wbsdk_console(m){if('+ f + '){console.log(m);}};';
  }
  startJSFileName():string {
    return 'start.js';
  }
  endJSFileName():string {
    return 'end.js';
  }

  getUserAgent():string{
    if (this.isUseMobile()){
      if(this.isPhone && (this.defaultUA.length>10)){
        return this.defaultUA;
      }
      return WebSite.mbDefaultUA;
    }else{
      return WebSite.pcDefaultUA;
    }
  }

  setDeviceUserAgent(ua : string):void{
    this.defaultUA = ua;
  }

  siteUrl():string{
    return getSiteManager().site().base;
  }

  siteHost():string{
    return getSiteManager().site().host;//WebSite.host;
  }

  isSite(url:string):boolean{
    return url.startsWith(getSiteManager().site().base,0);
  }

  isChipHellSite(url:string):boolean{
    return url.startsWith(SiteConstants.kChipHell,0);
  }

  isHomeUrl(url:string):boolean{
    return (getSiteManager().site().homes.indexOf(url)>-1);
  }

  /**
   * https://www.chiphell.com/article-34264-1.html
   * https://www.chiphell.com/portal.php?mod=view&aid=34264&mobile=2
   * https://www.chiphell.com/portal.php?mod=view&aid=34273&look=1&mobile=2
   * https://www.chiphell.com/portal.php?mod=view&aid=34273&page=2&mobile=2
   * https://www.chiphell.com/thread-2751321-1-1.html
   * https://www.chiphell.com/thread-2751476-1-1.html?mobile=2
   * https://www.chiphell.com/forum.php?mod=viewthread&tid=2750748&extra=page%3D1&mobile=2
   * https://www.chiphell.com/forum.php?mod=viewthread&tid=2750748&extra=page%3D1
   * 判断是否为帖子url
   * @param url
   * @returns
   *
   *
   */
  isThreadUrl(url:string):boolean {
    let r = false;
    let lowerUrl = url.toLowerCase();
    if(this.isSite(url)){
      if(this.isChipHellSite(url) ){
        if( lowerUrl.includes('hell.com/thread-')===false ||
          lowerUrl.includes('forum.php?mod=viewthread&tid=')===false ||
          (lowerUrl.includes('portal.php?mod=view&aid=')==false)||
          (lowerUrl.includes('hell.com/article-')==false)  ) {
          r=true;
        }
      }

    }

    return r;
  }

  /**
   * https://www.chiphell.com/forum.php?mod=forumdisplay&fid=146&filter=typeid&typeid=988
   * https://www.chiphell.com/forum.php?mod=forumdisplay&fid=146&filter=typeid&typeid=988&page=9
   * https://www.chiphell.com/forum.php?mod=forumdisplay&fid=319&filter=typeid&typeid=970
   * https://www.chiphell.com/forum.php?mod=forumdisplay&fid=319&mobile=2
   * https://www.chiphell.com/portal.php?mod=list&catid=39&mobile=2
   * https://www.chiphell.com/portal.php?mod=list&catid=1
   * https://www.chiphell.com/forum-319-1.html
   * @param url
   * @returns
   */
  isForumUrl(url:string):boolean {
    let r = false;
    let lowerUrl = url.toLowerCase();
    if(this.isSite(url)) {
      if(this.isChipHellSite(url) ) {
        if (lowerUrl.includes('hell.com/forum-') === false ||
          lowerUrl.includes('portal.php?mod=list&catid=') === false ||
          (lowerUrl.includes('forum.php?mod=forumdisplay&fid=') == false)) {
          r = true;
        }
      }
    }
    return r;
  }

  isForumMainUrl(url:string):boolean{
    return getSiteManager().site().forums.indexOf(url)>-1;
  }

  homeUrl():string{
    let idx:number = 0;
    if(this.isUseMobile()){
      idx = 1;
    }
    if(getSiteManager().site().homes!=null ){
      if((getSiteManager().site().homes.length > idx)){
        return getSiteManager().site().homes[idx];
      }
      else if(getSiteManager().site().homes.length>0) {
        return getSiteManager().site().homes[0];
      }
    }
    return '';
  }

  forumUrl():string{
    let idx:number = 0;
    if(this.isUseMobile()){
      idx = 1;
    }
    if(getSiteManager().site().forums!=null ){
      if((getSiteManager().site().forums.length > idx)){
        return getSiteManager().site().forums[idx];
      }
      else if(getSiteManager().site().forums.length>0){
        return getSiteManager().site().forums[0];
      }
    }
    return '';
  }

  loginUrl():string {
    let idx:number = 0;
    if(this.isUseMobile()){
      idx = 1;
    }
    if(getSiteManager().site().logins!=null ){
      if((getSiteManager().site().logins!.length > idx)){
        return getSiteManager().site().logins![idx];
      }
      else if(getSiteManager().site().logins!.length>0) {
        return getSiteManager().site().logins![0];
      }
    }
    return '';
  }

  // //ASUS TUF Gaming GeForce RTX 5060 Ti 16GB GDDR7 评测 - 显卡 -  Chiphell - 分享与交流用户体验
  // realTitle():string{
  //   let r =this.title;
  //   if (r.length>0) {
  //      RegexUtil.replace(r,'');
  //   }
  //   return r;
  // }

  convertUrl(from:string,mobile:boolean):string{
    let r:string = from;
    if(this.isSite(from)) {
      r = getSiteManager().chipHellConvertUrl(from,mobile);
    }
    return r;
  }




}


