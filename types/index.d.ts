// types/index.d.ts

// 扩展小程序全局类型
declare namespace WechatMiniprogram {
  interface App {
    globalData: {
      userInfo: UserInfo | null;
      hasLogin: boolean;
      theme: 'light' | 'dark';
      systemInfo: SystemInfo | null;
      calligraphy: {
        defaultFont: string;
        supportedFonts: string[];
        gridConfig: {
          rows: number;
          cols: number;
          cellSize: number;
          showGrid: boolean;
        };
      };
      config: {
        version: string;
        apiBaseUrl: string;
        maxTextLength: number;
        enableAnalytics: boolean;
      };
    };

    // 扩展App实例方法
    getUserInfo(): Promise<UserInfo>;
    setTheme(theme: 'light' | 'dark'): void;
    getCallipgraphyConfig(): any;
    updateCallipgraphyConfig(config: any): void;
    initApp(): void;
    checkForUpdate(): void;
    initTDesign(): void;
    loadLocalSettings(): Promise<void>;
    checkNetworkStatus(): void;
    saveUserInfo(userInfo: UserInfo): Promise<void>;
    saveUserState(): Promise<void>;
    notifyThemeChange(theme: 'light' | 'dark'): void;
    reportUserAccess(): void;
    reportError(error: string): void;
  }

  // 页面类型定义
  interface IPageData {
    [key: string]: any;
  }

  interface IPageMethods {
    [key: string]: (...args: any[]) => any;
  }

  // 组件类型定义
  interface IComponentData {
    [key: string]: any;
  }

  interface IComponentMethods {
    [key: string]: (...args: any[]) => any;
  }
}

// 页面相关接口
export interface IndexPageData extends WechatMiniprogram.IPageData {
  appTitle: string;
  features: Array<{
    icon: string;
    title: string;
    description: string;
  }>;
  loading: boolean;
}

export interface ProfilePageData extends WechatMiniprogram.IPageData {
  userInfo: WechatMiniprogram.UserInfo | null;
  hasLogin: boolean;
  settings: Array<{
    title: string;
    icon: string;
    key: string;
    value?: string;
  }>;
}

// 组件相关接口
export interface CallipgraphyPreviewData extends WechatMiniprogram.IComponentData {
  fontOptions: Array<{id: string; name: string; family: string}>;
  selectedFont: string;
  selectedFontFamily: string;
  showFontSelector: boolean;
  gridData: string[];
  cellSize: number;
  showGrid: boolean;
  loading: boolean;
}

export interface CallipgraphyPreviewMethods extends WechatMiniprogram.IComponentMethods {
  onFontChange: (event: WechatMiniprogram.TouchEvent) => void;
  toggleGrid: () => void;
  onExport: () => void;
  generatePreview: () => void;
  updateGridData: (text: string) => void;
}

// 工具函数类型
export interface FormatUtils {
  formatDate(date: Date, format?: string): string;
  formatFileSize(bytes: number): string;
}

export interface StorageUtils {
  setStorage(key: string, data: any): Promise<void>;
  getStorage<T>(key: string): Promise<T | null>;
  removeStorage(key: string): Promise<void>;
}

export interface NetworkUtils {
  request<T>(options: {
    url: string;
    method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
    data?: any;
    header?: Record<string, string>;
  }): Promise<T>;
  checkNetworkStatus(): Promise<WechatMiniprogram.GetNetworkTypeSuccessCallbackResult>;
}

export interface UIUtils {
  showLoading(title?: string): void;
  hideLoading(): void;
  showSuccess(title: string, duration?: number): void;
  showError(title: string, duration?: number): void;
  showToast(title: string, duration?: number): void;
  showConfirm(title: string, content: string): Promise<boolean>;
}

export interface CallipgraphyUtils {
  getSupportedFonts(): Array<{id: string; name: string; description: string}>;
  validateText(text: string): { valid: boolean; message?: string };
  generateGridConfig(options: {
    rows?: number;
    cols?: number;
    cellSize?: number;
    showGrid?: boolean;
  }): any;
}

// 扩展全局App类型
declare const app: WechatMiniprogram.App;
declare function getApp(): WechatMiniprogram.App;

// 扩展Component函数类型定义
declare function Component<TData, TMethods>(
  options: WechatMiniprogram.Component.Options<TData, {}, TMethods, {}, false>
): string;

// 扩展Page函数类型定义
declare function Page<TData, TMethods>(
  options: WechatMiniprogram.Page.Options<TData, TMethods>
): void;
