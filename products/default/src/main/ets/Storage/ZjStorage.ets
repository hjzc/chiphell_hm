import {  ConfigurationConstant } from '@kit.AbilityKit';
import { BreakpointTypeEnum, logger } from 'utils';
import { Type, UIUtils } from '@kit.ArkUI';

const webTextZoomRatioList:number[] = [100, 120,140];

@ObservedV2
export class ZjStorage {
  @Trace statusBarHeight: number = 136;
  @Trace navBarHeight: number = 136;
  @Trace bottomRectHeight: number = 136;
  @Trace currentBreakpoint: string = BreakpointTypeEnum.MD;
  @Trace currentColorMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
  @Trace themeMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  @Trace webTextZoomRatioIndex: number = 0;//0,1,2
  @Trace webImageMode: number = 0;//0,1
  @Trace userName:string|null = null;

  @Trace filterList:string[]= [];
  @Trace filterListChanged:number = 0;

  @Trace openHistoryUrl:string|null = null;

  // @Monitor('filterList')
  // onStorageFilterChanged(mon: IMonitor) {
  //   logger.debug('dd');
  //   //this.webClient.handleFilter();
  // }

  isDark():boolean{
    return this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
  }

  webTextZoomRatio():number{
    return webTextZoomRatioList[this.webTextZoomRatioIndex];
  }

  webTextZoomRatioDesc():Resource{
    return ZjStorage.webTextZoomRatioDescList()[this.webTextZoomRatioIndex];
  }

  static  webTextZoomRatioDescList():Resource[]{
    return [$r("app.string.web_font_set_option_normal"), $r("app.string.web_font_set_option_mid"),$r("app.string.web_font_set_option_big")];
  }


  containFilter(user:string):boolean {
    let r:boolean =false;
    if (!this.filterList.includes(user)) {
      r= true;
    }
    return r;
  }

  addFilter(user:string):boolean {
    let r:boolean =false;
    if (!this.filterList.includes(user)) {
      this.filterList.push(user);
      r= true;
      this.filterListChanged +=1;
    }
    return r;
  }

  deleteFilter(user:string):boolean {
    let r:boolean =false;
    let idx : number = this.filterList.indexOf(user);
    if (idx>-1) {
      this.filterList.splice(idx,1);
      r = true;
      this.filterListChanged -=1;
    }
    return r;
  }


  isWebImageAccess():boolean {
    return  this.webImageMode==0;
  }
  webImageModeDesc():Resource{
    return ZjStorage.webImageModeDescList()[this.webImageMode];
  }
  static  webImageModeDescList():Resource[]{
    return [$r('app.string.web_font_set_option_normal'), $r('app.string.web_set_image_mode_no_image')];
  }


}

