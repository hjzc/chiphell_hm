
 class DTask{
  name:string = '';
  delay:number = 1000;
  isDoing:boolean = false;
  isEnd:boolean = false;
  startTimer:number = new Date() .getTime();
  private progressDelayTimerId: number = -1;
  runBlock?:()=>void = ()=>{
    this.clearProgressDelayTimer();
  };

  endBlock?:(tasker:DTask)=>void = (tasker:DTask)=>{

  };

  start(): void
  {
    this.progressDelayTimerId=setTimeout(() => {
      this.isDoing =true;
      this.clearProgressDelayTimer();
      if(this.runBlock !== undefined )
      {
        this.runBlock();
        this.runBlock = undefined;
      }
      if(this.endBlock !== undefined )
      {
        this.endBlock(this);
        this.endBlock = undefined;
      }
      this.isEnd  = true;
    }, this.delay);
  }

  resetTime(delay:number, block:()=>void):void{
    this.runBlock = block;
    if(delay > this.delay){
      this.clearProgressDelayTimer();
      this.start();
    }
  }

  private clearProgressDelayTimer(){
    if(this.progressDelayTimerId>-1){
      clearTimeout(this.progressDelayTimerId);
      this.progressDelayTimerId = -1;
    }
  }

  constructor(name: string,delay:number, block:()=>void ){
    this.name =name;
    this.delay = delay;
    this.runBlock = block;
  }
}

export  class DelayTasks{
  private taskList:DTask[] = [];
  //let reentrantTaskListMutex = Mutex();

  // 静态私有实例
  private static instance: DelayTasks;
  // 私有构造函数防止外部实例化
  private constructor() {}
  // 静态方法获取唯一实例
  public static getInstance(): DelayTasks {
    if (!DelayTasks.instance) {
      DelayTasks.instance = new DelayTasks();
    }
    return DelayTasks.instance;
  }

  private getTask(name:string):DTask|null{
    let ret : DTask|null = null;
    for (let i =0;i< this.taskList.length; i++ ){
        if(this.taskList[i].name == name){
          ret = this.taskList[i];
          if( ret.isEnd){
            this.taskList.splice(i, 1);
            ret= null;
          }
          break;
        }
    }
    return ret;
  }

  private  cleanTasker(task:DTask){
    let idx : number = this.taskList.indexOf(task);
    if (idx > -1) {
      this.taskList.splice(idx, 1);
    }
  }

  addDelayRun(name:string,delayMilliseconds:number, block:()=>void):void{
    let tasker =this.getTask(name);
    if (tasker != null) {
      if (tasker.isEnd) {
        tasker = null;
      }else if(tasker.isEnd){
        //不处理
      } else {

        tasker.resetTime(delayMilliseconds,block);
      }
    }
    if(tasker==null){
      tasker = new DTask(name,delayMilliseconds,block);
      tasker.endBlock = (item:DTask)=>{
        this.cleanTasker(item);
      }
      this.taskList.push(tasker);
      tasker.start();
    }
  }

   removeTask(name:string):void{
    for (let i =0;i< this.taskList.length; i++ ){
      if(this.taskList[i].name == name){
        this.taskList.splice(i, 1);
        break;
      }
    }
  }


  static addDelayRun(name:string,delayMilliseconds:number, block:()=>void):void{
    DelayTasks.getInstance().addDelayRun(name,delayMilliseconds,block);
  }

  static  deleteDelayTasker(name:string){
    DelayTasks.getInstance().removeTask(name);
  }


}


