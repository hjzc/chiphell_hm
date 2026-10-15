import { connection,} from '@kit.NetworkKit';


interface ConnNetInfo  {
  netId: number;
  state: boolean;
};

export  class  NetConnectionManager {

  private  conn: connection.NetConnection|null=null;
  netAvailableCallBack ?: (valid:boolean)=> void = (valid:boolean)=>{};
  private  _connected :boolean = false;
  private  infoList:Array<ConnNetInfo> = [];
  public connect():boolean {
    return this._connected;
  }

  // 创建网络监听对象, 默认300ms 就timeout
  constructor(callBack:(valid:boolean)=>void ,immediately:boolean = true, millsTimeout:number = 300,custom?:connection.NetSpecifier ) {
    this.netAvailableCallBack = callBack;
    this.conn =connection.createNetConnection(custom?? this.defaultConfig(),millsTimeout);
    if(immediately) {
      this.startOn();
    }
  }
  defaultConfig():connection.NetSpecifier{
    let ncl :connection.NetCapabilities = {
      bearerTypes: [connection.NetBearType.BEARER_CELLULAR,connection.NetBearType.BEARER_WIFI,connection.NetBearType.BEARER_ETHERNET],
      networkCap: [connection.NetCap.NET_CAPABILITY_INTERNET]
    };
    let netSpecifier:connection.NetSpecifier = {
      netCapabilities: ncl,
    };
    return netSpecifier;
  }

  _checkConnectData(data:connection.NetHandle,connectState:boolean):void{
    let exist:boolean = false;
    let connectedCount = 0;
    for (let i = 0; i < this.infoList.length; i++) {
      const element :ConnNetInfo = this.infoList[i];
      if(element.netId == data.netId){
        element.state = connectState;
        exist =true;
      }
      if(element.state){
        connectedCount ++;
      }else{
        //remove
        this.infoList.splice(i,1);
        i--;
      }
    }
    if(connectState &&  !exist){
      this.infoList.push({
        netId:data.netId,
        state:connectState,
      });
      connectedCount ++;
    }

    if( (connectedCount>0) != this._connected){
      this._connected = (connectedCount>0);
      if(this.netAvailableCallBack!=null){
        this.netAvailableCallBack(this.connect());
      }
    }
  }

  startOn():void {
      // 订阅网络可用事件
    this.conn?.on('netAvailable', (data:connection.NetHandle) => {
      console.info("网络可用，ID:" + data.netId);
      this._checkConnectData(data,true);
    });
    // 订阅网络丢失事件
    this.conn?.on('netLost', (data:connection.NetHandle) => {
      console.info("网络丢失，ID:" + data.netId);
      this._checkConnectData(data,false);
    });
  }

  // 检查网络连接
  static hasDefaultNet(callBack:(valid:number)=>void):void {
     connection.hasDefaultNet((error, data) => {
      if (data) {
        // 获取默认网络句柄
        connection.getDefaultNet().catch(() => {
          // TODO: Implement error handling.
          return null;
        }).then((netHandle) => {
          // 获取网络能力信息
          if(netHandle){
            connection.getNetCapabilities(netHandle, (error, data) => {
              let type:number = 0;
              if (data.bearerTypes?.includes(connection.NetBearType.BEARER_CELLULAR)) {
                console.log('当前使用移动蜂窝网络');
                type =1;
              } else if (data.bearerTypes?.includes(connection.NetBearType.BEARER_WIFI)) {
                console.log('当前使用Wi-Fi');
                type =2;
              } else if (data.bearerTypes?.includes(connection.NetBearType.BEARER_BLUETOOTH)) {
                console.log('当前使用BLUETOOTH');
                type =3;
              } else if (data.bearerTypes?.includes(connection.NetBearType.BEARER_ETHERNET)) {
                console.log('当前使用ETHERNET');
                type =4;
              }else if (data.bearerTypes?.includes(connection.NetBearType.BEARER_VPN)) {
                console.log('当前使用VPN');
                type =5;
              }
              callBack(type);
            });
          }
          else{
            callBack(-1);
          }
        });
      }
    });
  }

//   const conn = connection.createNetConnection(netSpecifier);
//




}