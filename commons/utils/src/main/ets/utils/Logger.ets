/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

class Logger {
  private domain: number;
  private tag: string;
  private format: string = '%{public}s';
 // private format2: string = '%{public}s, %{public}s';
  private isDebug:boolean =false;

  constructor(tag: string) {
    this.tag = tag;
    this.domain = 0xFF00;
  }

  init(debug:boolean):void{
    this.isDebug = debug;
  }

  setDebugModel():boolean {
    return this.isDebug;
  }


  private  formatFromArgs(length:number):string {
    let ret :string= this.format;
    let count = length;
    while  (count>1) {
      ret = ret + ' ' + this.format;
      count--;
    }
    return ret;
  }

  debug(...args: string[]): void {
    if(!this.isDebug){
      return;
    }
    hilog.debug(this.domain, this.tag,  this.formatFromArgs(args.length), args);
  }

  info(...args: string[]): void {
    if(!this.isDebug){
      return;
    }
    hilog.info(this.domain, this.tag, this.formatFromArgs(args.length), args);
  }

  warn(...args: string[]): void {
    if(!this.isDebug){
      return;
    }
    hilog.warn(this.domain, this.tag, this.formatFromArgs(args.length), args);
  }

  error(...args: string[]): void {
    hilog.error(this.domain, this.tag, this.formatFromArgs(args.length), args);
  }




}

export let logger: Logger = new Logger('CHIP_HELL');

// let spManager:SpManager|undefined;
// export function getSpManager():SpManager {
//   if(!spManager) {
//     spManager = new SpManager();
//   }
//   return spManager;
// }


//export default new Logger('CHIP HELL');
//export default new Logger('CHIP HELL');



// class Person {
//   static instance: Person | null = null
//   static getInstance() {
//     if (!Person.instance) {
//       Person.instance = new Person()
//     }
//     return Person.instance
//   }
//   // 设置方法为私有
//   private  constructor() {
//   }
// }
// const p1 = Person.getInstance()
// const p2 = Person.getInstance()
// console.log("", p1 === p2)// true