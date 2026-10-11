import { textToSpeech } from '@kit.CoreSpeechKit';
import { BusinessError, emitter } from '@kit.BasicServicesKit';

export class Speaker {
  ttsEngine?: textToSpeech.TextToSpeechEngine;


  // speed为合成音频播报时的语速，支持范围[0.5-2]，不传参时默认为1。
  // volume为合成音频播报时的音量，支持范围[0-2]，不传参时默认为1。
  // pitch为合成音频播报时的音调，支持范围[0.5-2]，不传参时默认为1。
  // playType为合成类型，不传参时默认为1。当该参数为0时表示仅合成不播报，返回音频流，为1时表示合成与播报不返回音频流。
  // soundChannel为通道，参数范围0-16，整数类型，可参考音频流使用类型介绍来选择适合自己的音频场景。不传参时默认为3，语音助手通道。
  // queueMode为播报模式，不传参时默认为0。0为排队模式播报，1为抢占模式播报。
  extraParam: Record<string, Object> = {
    "queueMode": 0,
    "speed": 1,
    "volume": 2,
    "pitch": 1,
    "languageContext": 'zh-CN',
    "audioType": "pcm",
    "soundChannel": 3,
    "playType": 1
  };
  initParamsInfo: textToSpeech.CreateEngineParams = {
    language: 'zh-CN',
    person: 0,
    online: 1,
    extraParams: { "style": 'interaction-broadcast', "locate": 'CN', "name": 'EngineName' }
  };
  speakListener?: textToSpeech.SpeakListener;

  constructor() {
    this.initListener()
    this.createEngine()
  }

  initListener() {
    this.speakListener = {
      onStart(requestId: string, response: textToSpeech.StartResponse) {
      },

      onComplete(requestId: string, response: textToSpeech.CompleteResponse) {
        if (response.type === 1) {
          emitter.emit("eventId");
        }
      },

      onStop(requestId: string, response: textToSpeech.StopResponse) {
        if (response.type === 1) {
          emitter.emit("eventId");
        }
      },

      onData(requestId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) {
      },

      onError(requestId: string, errorCode: number, errorMessage: string) {
      }
    };
  }

  createEngine() {
    try {
      textToSpeech.createEngine(this.initParamsInfo,
        (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => {
          if (!err) {
            this.ttsEngine = textToSpeechEngine;
            this.ttsEngine.setListener(this.speakListener);
          } else {
          }
        });
    } catch (error) {
      let message = (error as BusinessError).message;
      let code = (error as BusinessError).code;
    }
  }

  startSpeak(content: string) {
    let speakParams: textToSpeech.SpeakParams = {
      requestId: Date.now().toString(),//合成播报ID，全局不允许重复。
      extraParams: this.extraParam //合成播报音频流的相关参数
    };
    this.ttsEngine?.speak(content, speakParams);
  }

  stopSpeak() {
    this.ttsEngine?.stop();
  }

  shutdownEngine() {
    this.ttsEngine?.shutdown();
  }
}