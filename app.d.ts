/// <reference types="@types/wechat-miniprogram" />

interface IAppOption {
  globalData: {
    userInfo?: WechatMiniprogram.UserInfo;
    hasLogin: boolean;
    theme: 'light' | 'dark';
    systemInfo?: WechatMiniprogram.SystemInfo;
    calligraphy?: {
      defaultFont: string;
      supportedFonts: string[];
      gridConfig: {
        rows: number;
        cols: number;
        cellSize: number;
        showGrid: boolean;
      };
    };
    config?: {
      version: string;
      apiBaseUrl: string;
      maxTextLength: number;
      enableAnalytics: boolean;
    };
  };
  getUserInfo?(): Promise<WechatMiniprogram.UserInfo>;
  setTheme?(theme: 'light' | 'dark'): void;
  getCallipgraphyConfig?(): any;
  updateCallipgraphyConfig?(config: any): void;
  checkSystemInfo?(): void;
  initTDesign?(): void;
}
