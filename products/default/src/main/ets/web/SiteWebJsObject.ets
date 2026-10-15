import { logger } from "utils";
import { ZzjWebJsObject } from "./Zzj/ZzjWebJsObject";
import { JSONUtil } from "../utils/JSONUtil";
import { env } from "../Storage/ZjEnv";

export class SiteWebJsObject extends ZzjWebJsObject {

  onEvent?:(event:number,param: string | undefined | null) =>void = (event:number,param: string | undefined | null )=>{

  };

  loginInfo(info?: string|undefined) {
    if(info===undefined){
      return;
    }
    let map= JSONUtil.jsonToMap(info);
    let name  =  map.get('name');
    if(name !== undefined &&  (name as string) ){
      let username =  name as string;
      if(username.length>0){
          env.siteUserName = username;
      }
      logger.info(`loginInfo user name: ${username}`);
    }
  }

  tapFavorite():void{
    logger.info('点击收藏:');
    if(this.onEvent){
      this.onEvent(1, null);
    }
  }

  backInfo(info?: string|undefined):void{
    logger.info('backForumInfo:',info!);
    if(this.onEvent){
      this.onEvent(2, info);
    }
  }


}