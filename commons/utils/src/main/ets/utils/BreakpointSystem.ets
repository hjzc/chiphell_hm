/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
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

// 理解断点。断点以应用窗口宽度为切入点，将应用窗口在宽度维度上分成了几个不同的区间即不同的断点，在不同的区间下，开发者可根据需要实现不同的页面布局效果。具体的断点与应用窗口宽度对应关系如下所示
// 断点名称
// 取值范围（vp） vp是virtual pixel（虚拟像素）的缩写，是常用的长度单位。
// xs  [0, 320）
// sm  [320, 600)
// md  [600, 840)
// lg  [840, +∞)

import { mediaquery } from '@kit.ArkUI';

declare interface BreakpointTypeOption<T> {
  xs?: T
  sm?: T
  md?: T
  lg?: T
  xl?: T
  xxl?: T
}

export class BreakpointType<T> {
  options: BreakpointTypeOption<T>;

  constructor(option: BreakpointTypeOption<T>) {
    this.options = option
  }

  getValue(currentBreakPoint: string) {
    if (currentBreakPoint === 'xs') {
      return this.options.xs;
    } else if (currentBreakPoint === 'sm') {
      return this.options.sm;
    } else if (currentBreakPoint === 'md') {
      return this.options.md;
    } else if (currentBreakPoint === 'lg') {
      return this.options.lg;
    } else if (currentBreakPoint === 'xl') {
      return this.options.xl;
    } else if (currentBreakPoint === 'xxl') {
      return this.options.xxl;
    } else {
      return undefined;
    }
  }
}

interface Breakpoint {
  name: string,
  size: number,
  mediaQueryListener?: mediaquery.MediaQueryListener
}

export enum BreakpointTypeEnum {
  SM = 'sm',
  MD = 'md',
  LG = 'lg',
  XL = 'xl'
}

export class BreakpointSystem {
  private currentBreakpoint: string = "md";
  private breakpoints: Breakpoint[] = [
    { name: 'sm', size: 320 },
    { name: 'md', size: 600 },
    { name: 'lg', size: 840 },
    { name: 'xl', size: 1500 }
  ];
  private onChangedCallback?: Callback<string> = undefined;

  setOnChanged(onChangedCallback: Callback<string>) {
    this.onChangedCallback = onChangedCallback;
  }

  private updateCurrentBreakpoint(breakpoint: string) {
    if (this.currentBreakpoint !== breakpoint) {
      this.currentBreakpoint = breakpoint;
      AppStorage.setOrCreate<string>('currentBreakpoint', this.currentBreakpoint);
      if(this.onChangedCallback!==undefined){
        this.onChangedCallback(this.currentBreakpoint);
      }
      console.log('on current breakpoint: ' + this.currentBreakpoint);
    }
  }

  public register() {
    this.breakpoints.forEach((breakpoint: Breakpoint, index) => {
      let condition: string;
      if (index === this.breakpoints.length - 1) {
        condition = '(' + breakpoint.size + 'vp<=width' + ')';
      } else {
        condition = '(' + breakpoint.size + 'vp<=width<' + this.breakpoints[index + 1].size + 'vp)';
      }
      let uiContext :UIContext= AppStorage.get('UIContext') as UIContext;
      breakpoint.mediaQueryListener = uiContext.getMediaQuery().matchMediaSync(condition);
      breakpoint.mediaQueryListener.on('change', (mediaQueryResult) => {
        if (mediaQueryResult.matches) {
          this.updateCurrentBreakpoint(breakpoint.name);
        }
      })
    })
  }

  public unregister() {
    this.breakpoints.forEach((breakpoint: Breakpoint) => {
      if (breakpoint.mediaQueryListener) {
        breakpoint.mediaQueryListener.off('change');
      }
    })
  }
}