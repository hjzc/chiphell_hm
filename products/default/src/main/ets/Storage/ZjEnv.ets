import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { collections } from '@kit.ArkTS';
import { logger } from 'utils';


export class ZjEnv {
  language: string | undefined;
  fontSizeScale: number | undefined;
  fontWeightScale: number | undefined;
  statusBarHeight: number = 136;
  bottomRectHeight: number = 136;
  navBarHeight: number = 98;
  windowHeight: number = 0;
  currentColorMode:ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  themeMode:ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  defaultUserAgent: string | null=null;
  bundleName: string|null =null;
  debug: boolean  =true;
  login:boolean = false;
  siteUserName: string|null =null;
  userAgreementState:number = 0;
  caMap = new collections.Map<string, string>();

  public  updateCAPaths(domain:string, caPath:string) {
    try {
      this.caMap.set(domain, caPath);
    } catch (error) {
      // TODO: Implement error handling.
      logger.error('updateCAPaths error: ' + JSON.stringify(error));
    }
  }

  public  getCaPath(domain:string):string|undefined {
    let r :string|undefined=undefined;
    try {
      r= env.caMap.get(domain);
    } catch (error) {
      // TODO: Implement error handling.
      logger.error('getCaPath domain:'+domain +' error: ' + JSON.stringify(error));
    }
    return r;
  }

  public getChiphellCaPath():string|undefined {
    return this.getCaPath('static.chiphell.com');
  }
}


export let env: ZjEnv = new ZjEnv();