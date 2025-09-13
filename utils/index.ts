/**
 * 通用工具函数集合
 */

// 格式化工具
export const formatUtils = {
  /**
   * 格式化日期
   * @param date 日期对象
   * @param format 格式化字符串，默认 'YYYY-MM-DD'
   */
  formatDate(date: Date, format: string = 'YYYY-MM-DD'): string {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hour = String(date.getHours()).padStart(2, '0');
    const minute = String(date.getMinutes()).padStart(2, '0');
    const second = String(date.getSeconds()).padStart(2, '0');

    return format
      .replace('YYYY', String(year))
      .replace('MM', month)
      .replace('DD', day)
      .replace('HH', hour)
      .replace('mm', minute)
      .replace('ss', second);
  },

  /**
   * 格式化文件大小
   * @param bytes 字节数
   */
  formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
};

// 存储工具
export const storageUtils = {
  /**
   * 设置本地存储
   * @param key 存储键
   * @param data 存储数据
   */
  setStorage(key: string, data: any): Promise<void> {
    return new Promise((resolve, reject) => {
      wx.setStorage({
        key,
        data,
        success: () => resolve(),
        fail: (err) => reject(err)
      });
    });
  },

  /**
   * 获取本地存储
   * @param key 存储键
   */
  getStorage<T>(key: string): Promise<T | null> {
    return new Promise((resolve) => {
      wx.getStorage({
        key,
        success: (res) => resolve(res.data as T),
        fail: () => resolve(null)
      });
    });
  },

  /**
   * 移除本地存储
   * @param key 存储键
   */
  removeStorage(key: string): Promise<void> {
    return new Promise((resolve, reject) => {
      wx.removeStorage({
        key,
        success: () => resolve(),
        fail: (err) => reject(err)
      });
    });
  }
};

// 网络工具
export const networkUtils = {
  /**
   * 发起HTTP请求
   * @param options 请求配置
   */
  request<T>(options: {
    url: string;
    method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
    data?: any;
    header?: Record<string, string>;
  }): Promise<T> {
    return new Promise((resolve, reject) => {
      wx.request({
        ...options,
        method: options.method || 'GET',
        success: (res) => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(res.data as T);
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${res.errMsg}`));
          }
        },
        fail: (err) => reject(err)
      });
    });
  },

  /**
   * 检查网络连接状态
   */
  checkNetworkStatus(): Promise<WechatMiniprogram.GetNetworkTypeSuccessCallbackResult> {
    return new Promise((resolve, reject) => {
      wx.getNetworkType({
        success: resolve,
        fail: reject
      });
    });
  }
};

// 用户交互工具
export const uiUtils = {
  /**
   * 显示加载提示
   * @param title 提示文字
   */
  showLoading(title: string = '加载中...'): void {
    wx.showLoading({ title });
  },

  /**
   * 隐藏加载提示
   */
  hideLoading(): void {
    wx.hideLoading();
  },

  /**
   * 显示成功提示
   * @param title 提示文字
   * @param duration 持续时间（毫秒）
   */
  showSuccess(title: string, duration: number = 2000): void {
    wx.showToast({
      title,
      icon: 'success',
      duration
    });
  },

  /**
   * 显示错误提示
   * @param title 提示文字
   * @param duration 持续时间（毫秒）
   */
  showError(title: string, duration: number = 2000): void {
    wx.showToast({
      title,
      icon: 'error',
      duration
    });
  },

  /**
   * 显示普通提示
   * @param title 提示文字
   * @param duration 持续时间（毫秒）
   */
  showToast(title: string, duration: number = 2000): void {
    wx.showToast({
      title,
      icon: 'none',
      duration
    });
  },

  /**
   * 显示确认对话框
   * @param title 标题
   * @param content 内容
   */
  showConfirm(title: string, content: string): Promise<boolean> {
    return new Promise((resolve) => {
      wx.showModal({
        title,
        content,
        success: (res) => resolve(res.confirm),
        fail: () => resolve(false)
      });
    });
  }
};

// 字帖相关工具函数
export const callipgraphyUtils = {
  /**
   * 获取支持的字体列表
   */
  getSupportedFonts(): Array<{id: string; name: string; description: string}> {
    return [
      { id: 'kaishu', name: '楷书', description: '工整规范，适合初学者练习' },
      { id: 'xingshu', name: '行书', description: '流畅自然，日常书写常用' },
      { id: 'lishu', name: '隶书', description: '古朴典雅，具有历史韵味' },
      { id: 'caoshu', name: '草书', description: '潇洒飘逸，书法艺术性强' }
    ];
  },

  /**
   * 验证输入文本是否适合生成字帖
   * @param text 输入文本
   */
  validateText(text: string): { valid: boolean; message?: string } {
    if (!text || text.trim().length === 0) {
      return { valid: false, message: '请输入要练习的文字内容' };
    }

    if (text.length > 500) {
      return { valid: false, message: '文字内容不能超过500个字符' };
    }

    // 检查是否包含特殊字符
    const specialCharsRegex = /[^\u4e00-\u9fa5\u3400-\u4dbf\uF900-\uFAFF\s\u3000-\u303F\uFF00-\uFFEF]/;
    if (specialCharsRegex.test(text)) {
      return { valid: false, message: '文字内容包含不支持的字符，请使用中文字符' };
    }

    return { valid: true };
  },

  /**
   * 生成字帖网格配置
   * @param options 配置选项
   */
  generateGridConfig(options: {
    rows?: number;
    cols?: number;
    cellSize?: number;
    showGrid?: boolean;
  }) {
    return {
      rows: options.rows || 8,
      cols: options.cols || 6,
      cellSize: options.cellSize || 120,
      showGrid: options.showGrid !== false,
      padding: 20,
      margin: 10
    };
  }
};

// 导出所有工具函数
export default {
  formatUtils,
  storageUtils,
  networkUtils,
  uiUtils,
  callipgraphyUtils
};
