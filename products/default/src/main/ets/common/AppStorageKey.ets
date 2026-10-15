import { Constants } from "./Constants";
import { ConfigurationConstant } from "@kit.AbilityKit";
import { PreferencesUtil } from "../utils/PreferencesUtil";

export  class AppStorageKey {

  static  setString(key:string,value:string | null):void{
    if(value===null){
      PreferencesUtil.delete(key);
    }
    else{
      PreferencesUtil.put(key,value);
    }
    //AppStorage.setOrCreate(key,value);
  }
  static  getString(key:string):string | null {
    let r: string | null = null;
    let  rv = PreferencesUtil.getStringSync(key);// AppStorage.get(key) as string;
    if (rv == undefined ){
      r = null;
    }
    else if(rv === ''){
      r = null;
    }
    else{
      r = rv;
    }
    return r;
  }

  static  setNumber(key:string,value:number|null):void{
    if(value===null){
      PreferencesUtil.delete(key);
    }
    else{
      PreferencesUtil.put(key,value);
    }
    //AppStorage.setOrCreate(key,value);
  }

  static  getNumber(key:string):number | null {
    let r: number | null = null;
    let  rv = PreferencesUtil.getNumberSync(key,-9999999);// AppStorage.get(key) as string;
   // let  rv =  AppStorage.get(key) as number;
    if (rv == undefined ){
      r = null;
    }else if(rv === -9999999){
      r = null;
    }else{
      r = rv;
    }
    return r;
  }
  static  getNumberValue(key:string, deValue:number = 0):number  {
    let r: number | null = null;
    let  rv = PreferencesUtil.getNumberSync(key,deValue);// AppStorage.get(key) as string;
    // let  rv =  AppStorage.get(key) as number;
    if (rv == undefined ){
      r = deValue;
    }else{
      r = rv;
    }
    return r;
  }



  // static  saveLastUrl(url:string|null):void{
  //   AppStorageKey.setString(Constants.kLastUrl,url);
  // }
  // static  getLastUrl():string | null {
  //   return AppStorageKey.getString(Constants.kLastUrl);
  // }


  // static  saveDefaultWebUA(ua:string|null):void{
  //   AppStorageKey.setString(Constants.kDefaultWebUA,ua);
  // }
  // static  getDefaultWebUA():string | null {
  //   return AppStorageKey.getString(Constants.kDefaultWebUA);
  // }


  // static  saveLastSiteAuthorToken(token:string|null):void{
  //   AppStorageKey.setString(Constants.kLastSiteAuthorToken,token);
  // }
  // static  getLastSiteAuthorToken():string | null {
  //   return AppStorageKey.getString(Constants.kLastSiteAuthorToken);
  // }




  // static  saveCurrentColorMode(mode:number):void{
  //   AppStorageKey.setNumber(Constants.kCurrentColorMode,mode);
  // }
  // static  getCurrentColorModeNumber():number| null{
  //   return AppStorageKey.getNumber(Constants.kCurrentColorMode);
  // }

  static  getWebTextZoomRatioIndex(): number{
    return AppStorageKey.getNumberValue(Constants.kWebTextZoomRatioIndex);
  }
  static  saveWebTextZoomRatioIndex(value:number): void{
     AppStorageKey.setNumber(Constants.kWebTextZoomRatioIndex,value);
  }



  static  saveThemeMode(mode:ConfigurationConstant.ColorMode):void{
    let tm = -1;
    if(mode == ConfigurationConstant.ColorMode.COLOR_MODE_DARK){
      tm=0;
    }else if(mode == ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT){
      tm=1;
    }
    AppStorageKey.setNumber(Constants.kThemeMode,tm);
  }
  static  getThemeModeNumber(): number| null{
    return AppStorageKey.getNumber(Constants.kThemeMode);
  }
  static  getThemeMode():ConfigurationConstant.ColorMode {
    return AppStorageKey.convertColorMode(AppStorageKey.getThemeModeNumber());
  }


  static colorModeFromNumber(r:  ConfigurationConstant.ColorMode | undefined ):number {
    let tm = -1;
    if(r == undefined){
      tm = -1;
    }
    else if(r == ConfigurationConstant.ColorMode.COLOR_MODE_DARK){
      tm=0;
    }else if(r == ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT){
      tm=1;
    }
    return tm;
  }
  static convertColorMode(r: number| null):ConfigurationConstant.ColorMode {
    let rc :ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    if (r !== null) {
      if(r === 0 ){
        rc= ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      }else if(r ===1){
        rc= ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
      }else{
      }
    }
    return rc;
  }

  //-1 第一次启动，0表示用户同意，1,2...，表示用户查看次数，没同意
  static  getUserAgreementState(): number{
    return AppStorageKey.getNumberValue(Constants.kWebUserAgreementState,-1);
  }
  static  saveUserAgreementState(value:number): void{
    AppStorageKey.setNumber(Constants.kWebUserAgreementState,value);
  }

  //0 默认模式，1，无图模式
  static  getWebImageMode(): number{
    return AppStorageKey.getNumberValue(Constants.kWebImageModeState,0);
  }
  static  saveWebImageMode(value:number): void{
    AppStorageKey.setNumber(Constants.kWebImageModeState,value);
  }






}