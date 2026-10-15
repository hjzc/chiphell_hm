
import { relationalStore } from '@kit.ArkData'; // 导入模块
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { logger } from 'utils';
import { WebRecord } from '../model/WebRecord';

//https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-persistence-by-rdb-store
//https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/batch-database-operations-guide
export class DBManager{
  static  tokenType: relationalStore.Tokenizer= relationalStore.Tokenizer.ICU_TOKENIZER;
  static  DBName:string = 'site.db';
  static  DBDir:string = 'Rdb';
  static  WebRecordTable = 'RECORD';
  static  WebFilterTable = 'FILTER_TABLE';

  ready:boolean = false;
  dbPath:string|undefined;
  store: relationalStore.RdbStore|undefined;

  //在共享沙箱中，必须通过rootDir显式指定共享目录。isShared: true,
  // const groupId:string = 'history'
  //let groupDir = await context.getGroupDir(groupId);
  STORE_CONFIG: relationalStore.StoreConfig = {
    // 数据库文件名
    name: DBManager.DBName,
    // 数据库安全级别
    securityLevel: relationalStore.SecurityLevel.S3,
    // 可选参数，指定数据库是否加密，默认不加密
    encrypt: false,
    //isShared: true, // 共享沙箱中需设为true
    //groupDir 获取的共享沙箱绝对路径传给rootDir,如果没有定义rootDir，则customDir的相对路径为context.databaseDir + "/rdb/"。
    //rootDir: groupDir,
    //可选参数，数据库自定义路径。默认在本应用沙箱目录下创建RdbStore实例。 配置相对路径,关键：相对路径（实际路径 = groupDir + '/rdb'）
    customDir: DBManager.DBDir,
    // 可选参数，指定数据库是否以只读方式打开。默认为false，表示数据库可读可写。为true时，只允许从数据库读取数据，不允许对数据库进行写操作，否则会返回错误码801。
    isReadOnly: false,
    // 可选参数，指定用户在全文搜索场景(FTS)下使用哪种分词器。默认在FTS下仅支持英文分词，不支持其他语言分词。
    tokenizer: DBManager.tokenType
  };

  initDb(context: common.UIAbilityContext):void{
    // 若希望使用分词器，可调用isTokenizerSupported检查希望使用的分词器是否支持当前平台。
    let tokenTypeSupported = relationalStore.isTokenizerSupported(DBManager.tokenType);
    if (!tokenTypeSupported) {
      logger.error(`ICU_TOKENIZER is not supported on this platform.`);
    }
    this.dbPath = context.getApplicationContext().databaseDir + DBManager.DBDir;

    // 判断数据库版本，如果不匹配则需进行升降级操作
    // 假设当前数据库版本为3，表结构：EMPLOYEE (NAME, AGE, SALARY, CODES, IDENTITY)
    // 建表Sql语句, IDENTITY为bigint类型，sql中指定类型为UNLIMITED INT
    const SQL_CREATE_TABLE =
      'CREATE TABLE IF NOT EXISTS '+ DBManager.WebRecordTable+ ' (url TEXT PRIMARY KEY NOT NULL, title TEXT NOT NULL, access INTEGER, accessDate INTEGER,favor INTEGER,favorDate INTEGER, deleted INTEGER,updateDate INTEGER,createDate INTEGER )';

    const FILTER_SQL_CREATE_TABLE =
      'CREATE TABLE IF NOT EXISTS '+ DBManager.WebFilterTable+ ' (name TEXT PRIMARY KEY NOT NULL,createDate INTEGER )';


    relationalStore.getRdbStore(context, this.STORE_CONFIG, async (err, store) => {
      if (err) {
        logger.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
        return;
      }
      this.store = store;
      logger.debug('Succeeded in getting RdbStore.');
      let storeVersion = store.version;
      // 当数据库创建时，数据库默认版本为0
      if (storeVersion === 0) {
        try {
          await store.execute(SQL_CREATE_TABLE); // 创建数据表，以便后续调用insert接口插入数据
          storeVersion = 1;
          // 设置数据库的版本，入参为大于0的整数
        } catch (e) {
          const err = e as BusinessError;
          logger.error(`Failed to execute sql. Code:${err.code}, message:${err.message}`);
        }
        try {
          await store.execute(FILTER_SQL_CREATE_TABLE);
          storeVersion = 1;
        } catch (e) {
          const err = e as BusinessError;
          logger.error(`Failed to execute sql. Code:${err.code}, message:${err.message}`);
        }
      }

      store.version = storeVersion;
      // 请确保获取到RdbStore实例，完成数据表创建后，再进行数据库的增、删、改、查等操作
      this.ready = true;
    });
  }

  private  abilityContext(): common.UIAbilityContext {
    let uiContext :UIContext= AppStorage.get('UIContext') as UIContext;
    if(uiContext){
      return uiContext.getHostContext() as common.UIAbilityContext;
    }
    return getContext() as common.UIAbilityContext;
  }

  // private  deleteDb():void{
  //   //this.store = undefined;
  //   relationalStore.deleteRdbStore(this.abilityContext(), 'site.db', (err: BusinessError) => {
  //     if (err) {
  //       console.error(`Failed to delete RdbStore. Code:${err.code}, message:${err.message}`);
  //       return;
  //     }
  //     console.info('Succeeded in deleting RdbStore.');
  //   });
  // }

  readRecordList(context: Context, isFavor:boolean |undefined=undefined, retryTimes: number =5, offset: number = 0, pageSize: number = 50, orderByDesc:boolean=true): Promise<WebRecord[]> {
    if (this.ready) {
      return this.readRecordListAfterDbInit(context,undefined,isFavor,offset,pageSize,orderByDesc);
    }
    if (retryTimes <= 0) {
      return Promise.resolve([]);
    }
    return new Promise<WebRecord[]>(resolve => {
      setTimeout(() => {
        resolve(this.readRecordList(context, isFavor,--retryTimes,offset,pageSize,orderByDesc));
      }, 500);
    });
  }

  readRecordListAfterDbInit(context: Context,url:string | undefined = undefined, isFavor:boolean |undefined,offset: number = 0, pageSize: number = 50,orderByDesc:boolean=true): Promise<WebRecord[]> {
    const retArray: WebRecord[] = [];
    return new Promise<WebRecord[]>(resolve => {

      relationalStore.getRdbStore(context, this.STORE_CONFIG)
        .then(async (rdbStore: relationalStore.RdbStore) => {

          let predicates = new relationalStore.RdbPredicates(DBManager.WebRecordTable);

          if(url !== undefined){
              predicates.equalTo('url', url);
          }

          if(isFavor !== undefined){
            predicates.equalTo('favor', isFavor);
          }else{
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
            predicates.orderByDesc('accessDate');
          }else{
            predicates.orderByAsc('accessDate');
          }

          rdbStore.query(predicates,
            async (err, resultSet) => {
            if (err) {
              logger.error(`Query failed, code is ${err.code},message is ${err.message}`);
              resolve(retArray);
              return;
            }
            // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
            while (resultSet.goToNextRow()) {
              const url = resultSet.getString(resultSet.getColumnIndex('url'));
              const title = resultSet.getString(resultSet.getColumnIndex('title'));
              const access = resultSet.getLong(resultSet.getColumnIndex('access'));
              const accessDate = resultSet.getLong(resultSet.getColumnIndex('accessDate'));

              const favor = resultSet.getLong(resultSet.getColumnIndex('favor')) ;
              const favorDate = resultSet.getLong(resultSet.getColumnIndex('accessDate'));

              const deleted = resultSet.getLong(resultSet.getColumnIndex('deleted')) ;

              const updateDate = resultSet.getLong(resultSet.getColumnIndex('updateDate'));
              const createDate = resultSet.getLong(resultSet.getColumnIndex('createDate'));


              logger.info(`title=${title}, url=${url}, createDate=${createDate}, updateDate=${updateDate}, access=${access} , favor=${favor} , deleted=${deleted} `);

              let record: WebRecord = {
                url: url,
                title: title,
                access: access,
                accessDate: accessDate,
                favor: favor,
                favorDate:favorDate,
                deleted: deleted,
                updateDate: updateDate,
                createDate: createDate,
              };
              retArray.push(record);
            }
            // 释放数据集的内存，若不释放可能会引起fd泄露与内存泄露
            try {
                resultSet.close();
            } catch (error) {

            }
            resolve(retArray);
          });
        })
        .catch((err: BusinessError) => {
          logger.error(`Get RdbStore failed, code is ${err.code},message is ${err.message}`);
          resolve(retArray);
        });
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
      relationalStore.getRdbStore(context, this.STORE_CONFIG)
        .then(async (rdbStore: relationalStore.RdbStore) => {
          if (rdbStore !== undefined) {
            let predicates2 = new relationalStore.RdbPredicates(DBManager.WebRecordTable);
            predicates2.equalTo('url', url);
            rdbStore.query(predicates2, async (err: BusinessError, resultSet) => {
              let record: WebRecord | undefined;
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
                  record = {
                    url: url,
                    title: title,
                    access: access,
                    accessDate:accessDate,
                    favor: favor,
                    favorDate:favorDate,
                    deleted: deleted,
                    updateDate: updateDate,
                    createDate: createDate,
                  };
                  break;
                }
              }
              if (resultSet !== undefined) {
                resultSet.close();
              }
              resolve(record);
            });
          } else {
            resolve(undefined);
          }
        });
    });
  }

  insertRecord(context: Context,record:WebRecord,retryTimes: number =5 ): Promise<boolean> {
    if (this.ready) {
      return this.insertRecordAfterDbInit(context,record);
    }
    if (retryTimes <= 0) {
      return Promise.resolve(false);
    }
    return new Promise<boolean>(resolve => {
      setTimeout(() => {
        resolve(this.insertRecord(context, record, --retryTimes));
      }, 500);
    })
  }

  insertRecordAfterDbInit(context: Context, record:WebRecord): Promise<boolean> {
    return new Promise<boolean>(resolve => {
      relationalStore.getRdbStore(context, this.STORE_CONFIG)
        .then(async (rdbStore: relationalStore.RdbStore) => {
          let r:boolean =false;
          if (rdbStore !== undefined) {
            let createDate = record.createDate;
            let updateDate = record.updateDate;
            try {
              record.createDate = new Date() .getTime();
              record.updateDate = record.createDate;
              await rdbStore.insert(DBManager.WebRecordTable, this.getInsertValueBucket(record));
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
        })
        .catch((err: BusinessError) => {
          logger.error(`Get RdbStore failed, code is ${err.code},message is ${err.message}`);
          resolve(false);
        });
    });
  }

  updateRecord(context: Context,record:WebRecord,retryTimes: number =5 ): Promise<boolean> {
    if (this.ready) {
      return this.updateRecordAfterDbInit(context,record);
    }
    if (retryTimes <= 0) {
      return Promise.resolve(false);
    }
    return new Promise<boolean>(resolve => {
      setTimeout(() => {
        resolve(this.updateRecord(context, record, --retryTimes));
      }, 500);
    })
  }

  updateRecordAfterDbInit(context: Context, record:WebRecord): Promise<boolean> {
    return new Promise<boolean>(resolve => {
      relationalStore.getRdbStore(context, this.STORE_CONFIG)
        .then(async (rdbStore: relationalStore.RdbStore) => {
          let r:boolean =false;
          let predicates1 = new relationalStore.RdbPredicates(DBManager.WebRecordTable);
          predicates1.equalTo('url', record.url);
          if (rdbStore !== undefined) {
            let updateDate = record.updateDate;
            try{
              record.updateDate = new Date() .getTime();
              (rdbStore as relationalStore.RdbStore).update(this.getInsertValueBucket(record), predicates1, (err: BusinessError, rows: number) => {
                if (err) {
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
        })
        .catch((err: BusinessError) => {
          logger.error(`Get RdbStore failed, code is ${err.code},message is ${err.message}`);
          resolve(false);
        });
    });
  }

  deleteRecord(context: Context, record:WebRecord): Promise<boolean> {
    return new Promise<boolean>(resolve => {
      relationalStore.getRdbStore(context, this.STORE_CONFIG)
        .then(async (rdbStore: relationalStore.RdbStore) => {
          let r:boolean =false;
          let predicates1 = new relationalStore.RdbPredicates(DBManager.WebRecordTable);
          predicates1.equalTo('url', record.url);
          if (rdbStore !== undefined) {
            (rdbStore as relationalStore.RdbStore).delete(predicates1, (err: BusinessError, rows: number) => {
              if (err) {
                logger.error(`Failed to delete data. Code:${err.code}, message:${err.message}`);
              }
              else{
                r=true;
                logger.info(`delete success`);
              }
              resolve(r);
            })
          }
          else{
            resolve(r);
          }
        })
        .catch((err: BusinessError) => {
          logger.error(`Get RdbStore failed, code is ${err.code},message is ${err.message}`);
          resolve(false);
        });
    });
  }


  //-----------------------------------------------Filter ----------------------------------------------
  readFilterList(context: Context,retryTimes:number = 5,offset: number = 0, pageSize: number = 1000,orderByDesc:boolean=true): Promise<string[]> {
    if (this.ready) {
      return this.readFilterListAfterDbInit(context,offset,pageSize,orderByDesc);
    }
    if (retryTimes <= 0) {
      return Promise.resolve([]);
    }
    return new Promise<string[]>(resolve => {
      setTimeout(() => {
        resolve(this.readFilterList(context,--retryTimes,offset,pageSize,orderByDesc));
      }, 500);
    })
  }
  readFilterListAfterDbInit(context: Context,offset: number = 0, pageSize: number = 1000,orderByDesc:boolean=true): Promise<string[]> {
    const retArray: string[] = [];
    return new Promise<string[]>(resolve => {
      relationalStore.getRdbStore(context, this.STORE_CONFIG)
        .then(async (rdbStore: relationalStore.RdbStore) => {
          let predicates = new relationalStore.RdbPredicates(DBManager.WebFilterTable);
          if(offset >=0 ){
            predicates.limitAs(pageSize).offsetAs(offset);
          }else if(pageSize>0){
            predicates.limitAs(pageSize);
          }
          if(orderByDesc){
            predicates.orderByDesc('createDate');
          }else{
            predicates.orderByAsc('createDate');
          }
          rdbStore.query(predicates,
            async (err, resultSet) => {
              if (err) {
                logger.error(`Query failed, code is ${err.code},message is ${err.message}`);
              }else{
                // resultSet是一个数据集合的游标，默认指向第-1个记录，有效的数据从0开始。
                while (resultSet.goToNextRow()) {
                  const name = resultSet.getString(resultSet.getColumnIndex('name'));
                  const createDate = resultSet.getLong(resultSet.getColumnIndex('createDate'));
                  logger.info(`name=${name},createDate=${createDate}`);
                  retArray.push(name);
                }
                try {
                  resultSet.close();
                } catch (error) {
                }
              }
              resolve(retArray);
            });
        })
        .catch((err: BusinessError) => {
          logger.error(`Get RdbStore failed, code is ${err.code},message is ${err.message}`);
          resolve(retArray);
        });
    });
  }
  insertFilter(context: Context,name:string,retryTimes: number =5 ): Promise<boolean> {
    if (this.ready) {
      return this.insertFilterAfterDbInit(context,name);
    }
    if (retryTimes <= 0) {
      return Promise.resolve(false);
    }
    return new Promise<boolean>(resolve => {
      setTimeout(() => {
        resolve(this.insertFilter(context, name, --retryTimes));
      }, 500);
    })
  }
  insertFilterAfterDbInit(context: Context, name:string): Promise<boolean> {
    return new Promise<boolean>(resolve => {
      relationalStore.getRdbStore(context, this.STORE_CONFIG)
        .then(async (rdbStore: relationalStore.RdbStore) => {
          let r:boolean =false;
          if (rdbStore !== undefined) {
            try {
              let createDate = (new Date()).getTime();
              await rdbStore.insert(DBManager.WebFilterTable, {name:name,createDate:createDate });
              r = true;
              logger.info(`Succeeded in inserting data. url:${name}`);
            } catch (error) {
              const err = error as BusinessError;
              logger.error(`Failed to insert data. Code:${err.code}, message:${err.message}`);
            }
          }
          resolve(r);
        })
        .catch((err: BusinessError) => {
          logger.error(`Get RdbStore failed, code is ${err.code},message is ${err.message}`);
          resolve(false);
        });
    });
  }

  // updateFilter(context: Context,name:string,retryTimes: number =5 ): Promise<boolean> {
  //   if (this.ready) {
  //     return this.updateFilterAfterDbInit(context,name);
  //   }
  //   if (retryTimes <= 0) {
  //     return Promise.resolve(false);
  //   }
  //   return new Promise<boolean>(resolve => {
  //     setTimeout(() => {
  //       resolve(this.updateFilter(context, name, --retryTimes));
  //     }, 500);
  //   })
  // }
  //
  // updateFilterAfterDbInit(context: Context, name:string): Promise<boolean> {
  //   return new Promise<boolean>(resolve => {
  //     relationalStore.getRdbStore(context, this.STORE_CONFIG)
  //       .then(async (rdbStore: relationalStore.RdbStore) => {
  //         let r:boolean =false;
  //         let predicates = new relationalStore.RdbPredicates(DBManager.WebFilterTable);
  //         predicates.equalTo('name', name);
  //         if (rdbStore !== undefined) {
  //           let createDate = (new Date()).getTime();
  //           (rdbStore as relationalStore.RdbStore).update({name:name,createDate: createDate }, predicates, (err: BusinessError, rows: number) => {
  //             if (err) {
  //               logger.error(`Failed to update data. Code:${err.code}, message:${err.message}`);
  //             }
  //             else{
  //               r=true;
  //               logger.info(`Succeeded in updating data. `);
  //             }
  //             resolve(r);
  //           })
  //         }else{
  //           resolve(r);
  //         }
  //
  //       })
  //       .catch((err: BusinessError) => {
  //         logger.error(`Get RdbStore failed, code is ${err.code},message is ${err.message}`);
  //         resolve(false);
  //       });
  //   });
  // }

  deleteFilter(context: Context, name:string): Promise<boolean> {
    return new Promise<boolean>(resolve => {
      relationalStore.getRdbStore(context, this.STORE_CONFIG)
        .then(async (rdbStore: relationalStore.RdbStore) => {
          let r:boolean =false;
          let predicates = new relationalStore.RdbPredicates(DBManager.WebFilterTable);
          predicates.equalTo('name', name);
          if (rdbStore !== undefined) {
            (rdbStore as relationalStore.RdbStore).delete(predicates, (err: BusinessError, rows: number) => {
              if (err) {
                logger.error(`Failed to delete data. Code:${err.code}, message:${err.message}`);
              }
              else{
                r=true;
                logger.info(`delete success`);
              }
              resolve(r);
            })
          }
          else{
            resolve(r);
          }
        })
        .catch((err: BusinessError) => {
          logger.error(`Get RdbStore failed, code is ${err.code},message is ${err.message}`);
          resolve(false);
        });
    });
  }



  test():void{
    //let record: WebRecord | undefined;
    let record :WebRecord= {
      url: 'https://www.bilibili.com/video/BV1pVsBzxEoj/?spm_id_from=333.11007.tianma.7-2-24.click&vd_source=be08631a16a6e96ec93e5c0faa1ddd1d',
      title: 'dddaaaa',
      access: 1,
      accessDate: (new Date()).getTime(),
      favor: 1,
      favorDate:(new Date()).getTime(),
      deleted: 0,
      updateDate: (new Date()).getTime(),
      createDate: (new Date()).getTime(),
    };

   this.insertRecordAfterDbInit(this.abilityContext(),record).then(
     (value)=>{
       logger.debug('insert: ', value?'true':'false');
     }
   );

    let record1 :WebRecord= {
      url: 'https://www.bilibili.com/video/BV1PYWdzrExm/?spm_id_from=333.1007.tianma.6-3-21.click&vd_source=be08631a16a6e96ec93e5c0faa1ddd1d',
      title: 'ddd11111',
      access: 1,
      accessDate: (new Date()).getTime(),
      favor: 0,
      favorDate:0,
      deleted: 0,
      updateDate: (new Date()).getTime(),
      createDate: (new Date()).getTime(),
    };
    this.insertRecordAfterDbInit(this.abilityContext(),record1).then(
      (value)=>{
        logger.debug('insert1: ', value?'true':'false');
      }
    );

    this.readRecordList(this.abilityContext(),undefined ).then(
      (value)=>{
        logger.debug('cout: ' +value.length );
      }
    )
  }
}


let dbManager: DBManager | undefined;
export function getDBManager(): DBManager {
  if (!dbManager) {
    dbManager = new DBManager();
  }
  return dbManager;
}