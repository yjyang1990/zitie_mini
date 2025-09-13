// app.js
const { storageUtils, uiUtils } = require('./utils/index.js');

App({
  globalData: {
    userInfo: null,
    hasLogin: false,
    theme: 'light',
    systemInfo: null,
    // 字帖相关配置
    calligraphy: {
      defaultFont: 'kaishu',
      supportedFonts: ['kaishu', 'xingshu', 'lishu', 'caoshu'],
      gridConfig: {
        rows: 8,
        cols: 6,
        cellSize: 120,
        showGrid: true
      }
    },
    // 应用配置
    config: {
      version: '1.0.0',
      apiBaseUrl: '',
      maxTextLength: 500,
      enableAnalytics: true
    }
  },

  onLaunch(options) {
    console.log('字帖生成器小程序启动', options);
    
    // 初始化应用
    this.initApp();
    
    // 检查更新
    this.checkForUpdate();
    
    // 初始化TDesign
    this.initTDesign();
    
    // 加载本地配置
    this.loadLocalSettings();
  },

  onShow(options) {
    console.log('字帖生成器小程序显示', options);
    
    // 检查网络状态
    this.checkNetworkStatus();
    
    // 上报用户访问
    if (this.globalData.config.enableAnalytics) {
      this.reportUserAccess();
    }
  },

  onHide() {
    console.log('字帖生成器小程序隐藏');
    
    // 保存用户状态
    this.saveUserState();
  },

  onError(error) {
    console.error('字帖生成器小程序发生错误:', error);
    
    // 错误上报
    this.reportError(error);
    
    // 显示用户友好的错误提示
    if (typeof uiUtils !== 'undefined') {
      uiUtils.showError('程序出现异常，请重试');
    }
  },

  onUnhandledRejection(res) {
    console.error('未处理的Promise拒绝:', res);
    this.reportError(`Unhandled Promise Rejection: ${res.reason}`);
  },

  onPageNotFound(res) {
    console.warn('页面不存在:', res);
    
    // 重定向到首页
    wx.reLaunch({
      url: '/pages/index/index'
    });
  },

  onThemeChange(res) {
    console.log('系统主题变更:', res.theme);
    this.globalData.theme = res.theme;
    
    // 通知所有页面主题变更
    this.notifyThemeChange(res.theme);
  },

  // 初始化应用
  initApp() {
    // 获取系统信息
    try {
      const systemInfo = wx.getSystemInfoSync();
      this.globalData.systemInfo = systemInfo;
      
      console.log('系统信息:', {
        platform: systemInfo.platform,
        version: systemInfo.version,
        screenWidth: systemInfo.screenWidth,
        screenHeight: systemInfo.screenHeight,
        theme: systemInfo.theme
      });
      
      // 设置主题
      if (systemInfo.theme) {
        this.globalData.theme = systemInfo.theme;
      }
      
    } catch (error) {
      console.error('获取系统信息失败:', error);
    }
  },

  // 检查小程序更新
  checkForUpdate() {
    if (wx.canIUse('getUpdateManager')) {
      const updateManager = wx.getUpdateManager();
      
      updateManager.onCheckForUpdate((res) => {
        console.log('检查更新结果:', res.hasUpdate);
      });

      updateManager.onUpdateReady(() => {
        wx.showModal({
          title: '更新提示',
          content: '新版本已经准备好，是否重启应用？',
          success: (res) => {
            if (res.confirm) {
              updateManager.applyUpdate();
            }
          }
        });
      });

      updateManager.onUpdateFailed(() => {
        wx.showModal({
          title: '更新失败',
          content: '新版本下载失败，请检查网络连接',
          showCancel: false
        });
      });
    }
  },

  // 初始化TDesign
  initTDesign() {
    console.log('TDesign UI 框架初始化完成');
    
    // 这里可以设置 TDesign 的全局配置
    // 例如主题色、字体大小等
  },

  // 加载本地设置
  async loadLocalSettings() {
    try {
      if (typeof storageUtils !== 'undefined') {
        // 加载用户偏好设置
        const userPreferences = await storageUtils.getStorage('userPreferences');
        if (userPreferences) {
          this.globalData.calligraphy = {
            ...this.globalData.calligraphy,
            ...userPreferences.calligraphy
          };
          console.log('加载用户偏好设置:', userPreferences);
        }

        // 加载主题设置
        const themeSettings = await storageUtils.getStorage('themeSettings');
        if (themeSettings) {
          this.globalData.theme = themeSettings.theme || this.globalData.theme;
        }
      }
    } catch (error) {
      console.error('加载本地设置失败:', error);
    }
  },

  // 检查网络状态
  checkNetworkStatus() {
    wx.getNetworkType({
      success: (res) => {
        console.log('网络类型:', res.networkType);
        
        if (res.networkType === 'none') {
          wx.showToast({
            title: '网络连接异常',
            icon: 'none',
            duration: 3000
          });
        }
      },
      fail: (error) => {
        console.error('获取网络状态失败:', error);
      }
    });
  },

  // 获取用户信息
  getUserInfo() {
    return new Promise((resolve, reject) => {
      if (this.globalData.userInfo) {
        resolve(this.globalData.userInfo);
        return;
      }

      wx.getUserProfile({
        desc: '用于完善用户资料和提供个性化服务',
        success: (res) => {
          console.log('获取用户信息成功:', res);
          this.globalData.userInfo = res.userInfo;
          this.globalData.hasLogin = true;
          
          // 保存用户信息到本地
          this.saveUserInfo(res.userInfo);
          
          resolve(res.userInfo);
        },
        fail: (error) => {
          console.error('获取用户信息失败:', error);
          reject(error);
        }
      });
    });
  },

  // 保存用户信息
  async saveUserInfo(userInfo) {
    try {
      if (typeof storageUtils !== 'undefined') {
        await storageUtils.setStorage('userInfo', userInfo);
        console.log('用户信息已保存到本地');
      }
    } catch (error) {
      console.error('保存用户信息失败:', error);
    }
  },

  // 保存用户状态
  async saveUserState() {
    try {
      if (typeof storageUtils !== 'undefined') {
        const userState = {
          calligraphy: this.globalData.calligraphy,
          theme: this.globalData.theme,
          lastActiveTime: new Date().toISOString()
        };
        
        await storageUtils.setStorage('userState', userState);
        console.log('用户状态已保存');
      }
    } catch (error) {
      console.error('保存用户状态失败:', error);
    }
  },

  // 设置主题
  setTheme(theme) {
    if (['light', 'dark'].includes(theme)) {
      this.globalData.theme = theme;
      
      // 保存主题设置
      if (typeof storageUtils !== 'undefined') {
        storageUtils.setStorage('themeSettings', { theme });
      }
      
      // 通知主题变更
      this.notifyThemeChange(theme);
      
      console.log('主题已切换为:', theme);
    }
  },

  // 通知主题变更
  notifyThemeChange(theme) {
    // 这里可以通过事件总线通知所有页面
    console.log('通知主题变更:', theme);
  },

  // 上报用户访问
  reportUserAccess() {
    // 这里可以集成统计分析SDK
    console.log('上报用户访问');
  },

  // 错误上报
  reportError(error) {
    // 这里可以集成错误监控SDK
    console.log('上报错误:', error);
  },

  // 获取字帖配置
  getCallipgraphyConfig() {
    return this.globalData.calligraphy;
  },

  // 更新字帖配置
  updateCallipgraphyConfig(config) {
    this.globalData.calligraphy = {
      ...this.globalData.calligraphy,
      ...config
    };
    
    // 保存到本地
    if (typeof storageUtils !== 'undefined') {
      const userPreferences = {
        calligraphy: this.globalData.calligraphy
      };
      storageUtils.setStorage('userPreferences', userPreferences);
    }
    
    console.log('字帖配置已更新:', this.globalData.calligraphy);
  }
});
