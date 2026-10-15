import { logger } from "utils";
import { PreferencesUtil } from "../utils/PreferencesUtil";
import { RegexUtil } from "../utils/RegexUtil";

export  interface Site {
  name: string;
  desc: string;
  host: string;
  base: string;
  logins?: Array<string>;
  homes: Array<string>;
  forums: Array<string>;
}

export  class  SiteConstants {
  static kChipHell: string = 'https://www.chiphell.com';
}

export class SiteManager{
  sites:Array<Site> = [];
  index:number = 0;
  constructor(){

  }

  init(){
    this.sites.push({
      name:'Chiphell',
      desc:'Chiphell PCDIY Forum',
      host:'www.chiphell.com',
      base:'https://www.chiphell.com',
      logins:['https://www.chiphell.com/member.php?mod=logging&action=login','https://www.chiphell.com/member.php?mod=logging&action=login&mobile=2'],
      homes: ['https://www.chiphell.com','https://www.chiphell.com/index.php?mobile=2','https://www.chiphell.com/index.php','https://www.chiphell.com/',],
      forums:['https://www.chiphell.com/forum.php','https://www.chiphell.com/forum.php?mobile=2'],
    });
    this.index =  this.getPresIndex();
  }

  private  getPresIndex():number{
    return PreferencesUtil.getNumberSync('site_index',0);
  }

  private  savePresIndex():void{
    PreferencesUtil.putSync('site_index',this.index);
  }

  site():Site {
    return this.sites[this.index];
  }

  chipHellConvertUrl(from:string,mobile:boolean):string{
    const  REG_MOBILE_FLAG: string ='mobile=\\d+';
    const REG_MOBILE_FILTER_FLAG: string ='[?&]{0,}mobile=\\d+';
    let result = from;
    if (mobile) {
      // pc to mobile link
      if (from.includes('mobile=2')) {
        result = from;
      }
      else if(RegexUtil.isMatch(from,REG_MOBILE_FLAG)){
        let rc = RegexUtil.replaceAll(from,REG_MOBILE_FLAG,'mobile=2');
        if(rc == null){
          result= this.matchReplace(from,'mobile=2',mobile);
        }else{
          result =rc;
        }
      }
      else{
        result= this.matchReplace(from,'mobile=2',mobile);
      }
    } else {
      //mobile to pc link
      if(RegexUtil.isMatch(from,REG_MOBILE_FILTER_FLAG)){
        let rc = RegexUtil.replaceAll(from,REG_MOBILE_FILTER_FLAG,'');
        if(rc == null){
          result= this.matchReplace(from,'',mobile);
        }else{
          result =rc;
        }
      }
      else{
        result= this.matchReplace(from,'',mobile);
      }
    }
    return result;
  }

  private matchReplace(from:string,rep:string,mobile:boolean):string{
    let result = from;
    if(mobile){
      if (from.includes('mobile=1') ) {
        result = from.replace('mobile=1', rep);
      } else if (from.includes('mobile=3') ) {
        result = from.replace('mobile=3', rep);
      } else if (from.endsWith('html',from.length)) {
        result = from + '?mobile =2';
      }
      else if (from.endsWith('html?',from.length)) {
        result = from + 'mobile =2';
      }else{
        //https://www.chiphell.com/portal.php?mod=list&catid=98
        logger.error('convert url to mobile error');
      }
    }else{
      if (from.includes('?mobile=2')) {
        result = from.replace('?mobile=2', rep);
      }else if (from.includes('&mobile=2') ) {
        result = from.replace('&mobile=2', rep);
      }else if (from.includes('mobile=2') ) {
        result = from.replace('mobile=2', rep);
      }
      else if (from.includes('?mobile=1') ) {
        result = from.replace('?mobile=1', rep);
      }else if (from.includes('&mobile=1') ) {
        result = from.replace('&mobile=1', rep);
      }else if (from.includes('mobile=1') ) {
        result = from.replace('mobile=1', rep);

      }else if (from.includes('?mobile=3') ) {
        result = from.replace('?mobile=3', rep);
      }else if (from.includes('&mobile=3') ) {
        result = from.replace('&mobile=3', rep);
      }else if (from.includes('mobile=3') ) {
        result = from.replace('mobile=3', rep);
      }else{
        result = from;
      }
    }
    return result;
  }

}

let _gSiteManager: SiteManager | undefined;
export function getSiteManager(): SiteManager {
  if (!_gSiteManager) {
    _gSiteManager = new SiteManager();
  }
  return _gSiteManager;
}