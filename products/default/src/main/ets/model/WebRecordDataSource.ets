
import {
  BasicDataSource
} from './BasicDataSource';
import {
  WebRecord
} from './WebRecord';

@ObservedV2
export class WebRecordDataSource extends BasicDataSource<WebRecord> {
  @Trace dbTotal:number = 0;
  pageSize:number = 8;
  @Trace isLoading:boolean = false;
  @Trace isMoreLoading:boolean = false;

  offset():number {
    return this.totalCount();
  }

  //@Computed get
   hasMore(): boolean {
    return  this.dbTotal > this.totalCount();
  }

  traverseRemoveData(item:WebRecord):boolean{
    let r: boolean = false;
    for(let i:number =0; i < this.totalCount(); i++){
      let val = this.getData(i);
      if (val.url === item.url) {
        this.removeDataOfIndex(i);
        r = true;
        break;
      }
    }
    return r;
  }

  traverseSetFavorData(item:WebRecord):boolean{
    let r: boolean = false;
    for(let i:number =0; i < this.totalCount(); i++){
      let val = this.getData(i);
      if (val.url === item.url) {
        val.favorDate = item.favorDate;
        val.favor = item.favor;
        r = true;
        break;
      }
    }
    return r;
  }


}