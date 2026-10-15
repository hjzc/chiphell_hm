import { WebRecord } from './WebRecord'
import { relationalStore } from '@kit.ArkData';
import { DBManager } from '../common/DBManager';
import { logger } from 'utils';
import { BusinessError } from '@kit.BasicServicesKit';

export class  WebRecordDbModel {
  rdbStore: relationalStore.RdbStore;
  constructor( rdbStore: relationalStore.RdbStore) {
    this.rdbStore = rdbStore;
  }

  copyItem(item:WebRecord):WebRecord {
    let r : WebRecord =new WebRecord();
    r.url=  item.url;
    r.title=item.title;
    r.access=item.access;
    r.accessDate=item.accessDate;
    r.favor=item.favor;
    r.favorDate=item.favorDate;
    r.deleted=item.deleted;
    r.updateDate= item.updateDate;
    r. createDate= item.createDate;
    return r;
  }

  queryRecordCount(context: Context,url:string | undefined = undefined, isFavor:boolean |undefined): Promise<number> {
    return new Promise<number>(resolve => {
      let predicates = new relationalStore.RdbPredicates(DBManager.WebRecordTable);
      if(url !== undefined){
        predicates.equalTo('url', url);
      }
      let flag =  isFavor !== undefined;
      if(flag){
        //查询是否收藏
        predicates.equalTo('favor', isFavor);
      }else{
        //查询历史记录
        predicates.equalTo('deleted', false);
      }
      let count:number = -1;
      try {
        // 调用 count 接口
        this.rdbStore.query(predicates,['access'],
          async (err, resultSet) => {
            if (err) {
              logger.error(`Query failed, code is ${err.code},message is ${err.message}`);
            }else{
              count=resultSet.rowCount;
            }
            resolve(count);
          });
      } catch (error) {
        resolve(count);
      }
    });
  }

  readRecordList(context: Context,url:string | undefined = undefined, isFavor:boolean |undefined,offset: number = 0, pageSize: number = 50,orderByDesc:boolean=true): Promise<WebRecord[]> {
    const retArray: WebRecord[] = [];
    return new Promise<WebRecord[]>(resolve => {
      let predicates = new relationalStore.RdbPredicates(DBManager.WebRecordTable);
      if(url !== undefined){
        predicates.equalTo('url', url);
      }

      let flag =  isFavor !== undefined;
      if(flag){
        //查询是否收藏
        predicates.equalTo('favor', isFavor);

      }else{
        //查询历史记录
        predicates.equalTo('deleted', false);
      }

      if(offset >=0 ){
        predicates.limitAs(pageSize).offsetAs(offset);
      }else if(pageSize>0){
        predicates.limitAs(pageSize);
      }

      //predicates.equalTo("NAME", "Lisa").or().equalTo("NAME", "Rose"); // 查询 NAME = 'Lisa' OR NAME = 'Rose'
      //降序
      if(orderByDesc){
        predicates.orderByDesc(flag?'favorDate': 'accessDate');
      }else{
        predicates.orderByAsc(flag?'favorDate':'accessDate');
      }

      try {
        this.rdbStore.query(predicates,
          async (err, resultSet) => {
            if (err) {
              logger.error(`Query failed, code is ${err.code},message is ${err.message}`);
            }else{
              // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
              while (resultSet.goToNextRow()) {
                const url = resultSet.getString(resultSet.getColumnIndex('url'));
                const title = resultSet.getString(resultSet.getColumnIndex('title'));
                const access = resultSet.getLong(resultSet.getColumnIndex('access'));
                const accessDate = resultSet.getLong(resultSet.getColumnIndex('accessDate'));

                const favor = resultSet.getLong(resultSet.getColumnIndex('favor')) ;
                const favorDate = resultSet.getLong(resultSet.getColumnIndex('favorDate'));
                const deleted = resultSet.getLong(resultSet.getColumnIndex('deleted')) ;

                const updateDate = resultSet.getLong(resultSet.getColumnIndex('updateDate'));
                const createDate = resultSet.getLong(resultSet.getColumnIndex('createDate'));


                logger.info(`title=${title}, url=${url}, createDate=${createDate}, updateDate=${updateDate}, access=${access} , favor=${favor} , deleted=${deleted} `);
                let r : WebRecord =new WebRecord();
                r.url=  url;
                r.title=title;
                r.access=access;
                r.accessDate=accessDate;
                r.favor=favor;
                r.favorDate=favorDate;
                r.deleted=deleted;
                r.updateDate= updateDate;
                r. createDate= createDate;

                // let record: WebRecord = {
                //   url: url,
                //   title: title,
                //   access: access,
                //   accessDate: accessDate,
                //   favor: favor,
                //   favorDate:favorDate,
                //   deleted: deleted,
                //   updateDate: updateDate,
                //   createDate: createDate,
                // };
                retArray.push(r);
              }
              // 释放数据集的内存，若不释放可能会引起fd泄露与内存泄露
              try {
                resultSet.close();
              } catch (error) {

              }
            }
            resolve(retArray);
          });
      } catch (error) {

      }
    });
  }

  private getInsertValueBucket(record:WebRecord): relationalStore.ValuesBucket {
    let r: relationalStore.ValuesBucket =  {
      url:  record.url,
      title: record.title,
      access: record.access,
      accessDate: record.accessDate,
      favor: record.favor,
      favorDate:record.favorDate,
      deleted: record.deleted,
      updateDate:  record.updateDate,
      createDate:  record.createDate,
    };
    return r;
  }

  queryRecord(context: Context, url:string):Promise<WebRecord|undefined>  {
    return new Promise<WebRecord|undefined>(resolve => {
      try {
        if (this.rdbStore !== undefined) {
          let predicates2 = new relationalStore.RdbPredicates(DBManager.WebRecordTable);
          predicates2.equalTo('url', url);
          this.rdbStore.query(predicates2, async (err: BusinessError, resultSet) => {
            let r: WebRecord | undefined;
            if (err) {
              console.error(`Failed to query data. Code:${err.code}, message:${err.message}`);
            } else {
              while (resultSet.goToNextRow()) {
                const url = resultSet.getString(resultSet.getColumnIndex('url'));
                const title = resultSet.getString(resultSet.getColumnIndex('title'));
                const access = resultSet.getLong(resultSet.getColumnIndex('access'));
                const accessDate = resultSet.getLong(resultSet.getColumnIndex('accessDate'));
                const favor = resultSet.getLong(resultSet.getColumnIndex('favor')) ;
                const favorDate = resultSet.getLong(resultSet.getColumnIndex('favorDate'));
                const deleted = resultSet.getLong(resultSet.getColumnIndex('deleted')) ;
                const updateDate = resultSet.getLong(resultSet.getColumnIndex('updateDate'));
                const createDate = resultSet.getLong(resultSet.getColumnIndex('createDate'));
                r =new WebRecord();
                r.url=  url;
                r.title=title;
                r.access=access;
                r.accessDate=accessDate;
                r.favor=favor;
                r.favorDate=favorDate;
                r.deleted=deleted;
                r.updateDate= updateDate;
                r. createDate= createDate;
                break;
              }
            }
            if (resultSet !== undefined) {
              resultSet.close();
            }
            resolve(r);
          });
        } else {
          resolve(undefined);
        }
      }catch (error) {
        resolve(undefined);
      }
    });
  }

  insertRecord(context: Context, record:WebRecord): Promise<boolean> {
    return new Promise<boolean>( async resolve => {
      try {
        let r:boolean =false;
        if (this.rdbStore !== undefined) {
          let createDate = record.createDate;
          let updateDate = record.updateDate;
          record.createDate = new Date() .getTime();
          record.updateDate = record.createDate;
          try {
            await this.rdbStore.insert(DBManager.WebRecordTable, this.getInsertValueBucket(record));
            r = true;
            logger.info(`Succeeded in inserting data. url:${record.url}`);
          } catch (error) {
            record.createDate =createDate;
            record.updateDate =updateDate;
            const err = error as BusinessError;
            logger.error(`Failed to insert data. Code:${err.code}, message:${err.message}`);
          }
        }
        resolve(r);
      }catch (error) {
        logger.error(`Get RdbStore failed, code is ${error.code},message is ${error.message}`);
        resolve(false);
      }
    });
  }

  updateRecord(context: Context, record:WebRecord): Promise<boolean> {
    return new Promise<boolean>(async  resolve => {
      let r:boolean =false;
      if (this.rdbStore !== undefined) {
        let updateDate = record.updateDate;
        try{
          let predicates = new relationalStore.RdbPredicates(DBManager.WebRecordTable);
          predicates.equalTo('url', record.url);
          record.updateDate = new Date() .getTime();
          this.rdbStore.update(this.getInsertValueBucket(record), predicates, (err: BusinessError, rows: number) => {
            if (err) {
              record.updateDate =updateDate;
              logger.error(`Failed to update data. Code:${err.code}, message:${err.message}`);
            }
            else{
              r=true;
              logger.info(`Succeeded in updating data. `);
            }
            resolve(r);
          })
        }catch(error){
          record.updateDate =updateDate;
          const err = error as BusinessError;
          logger.error(`Failed to update data. Code:${err.code}, message:${err.message}`);
          resolve(r);
        }
      }else{
        resolve(r);
      }
    });
  }

  deleteRecord(context: Context, record:WebRecord): Promise<boolean> {
    return new Promise<boolean>(async resolve => {
      let r:boolean =false;
      if (this.rdbStore !== undefined) {
        try{
          let predicates = new relationalStore.RdbPredicates(DBManager.WebRecordTable);
          predicates.equalTo('url', record.url);
          this.rdbStore.delete(predicates, (err: BusinessError, rows: number) => {
            if (err) {
              logger.error(`Failed to delete data. Code:${err.code}, message:${err.message}`);
            }
            else{
              r=true;
              logger.info(`delete success`);
            }
            resolve(r);
          })
        }catch(error){
          const err = error as BusinessError;
          logger.error(`Failed to delete data. Code:${err.code}, message:${err.message}`);
          resolve(r);
        }
      }
      else{
        resolve(r);
      }
    });
  }


}