// pages/profile/profile.ts
interface ProfilePageData {
  userInfo: WechatMiniprogram.UserInfo | null;
  hasLogin: boolean;
  settings: Array<{
    title: string;
    icon: string;
    key: string;
    value?: string;
  }>;
}

interface ProfilePageMethods {
  initUserInfo(): void;
  handleLogin(): void;
  handleSetting(event: WechatMiniprogram.TouchEvent): void;
  handleThemeSwitch(): void;
  handleFontSetting(): void;
  handleAbout(): void;
}

Page<ProfilePageData, ProfilePageMethods>({
  data: {
    userInfo: null,
    hasLogin: false,
    settings: [
      { title: '主题设置', icon: 'palette', key: 'theme', value: '浅色模式' },
      { title: '字体偏好', icon: 'text-format', key: 'font' },
      { title: '导出设置', icon: 'download', key: 'export' },
      { title: '关于我们', icon: 'info-circle', key: 'about' }
    ]
  },

  onLoad() {
    console.log('个人中心页面加载');
    this.initUserInfo();
  },

  onShow() {
    console.log('个人中心页面显示');
    this.initUserInfo();
  },

  // 初始化用户信息
  initUserInfo() {
    const app = getApp<any>();
    if (app.globalData.hasLogin && app.globalData.userInfo) {
      this.setData({
        userInfo: app.globalData.userInfo,
        hasLogin: true
      });
    }
  },

  // 处理登录
  async handleLogin() {
    try {
      const app = getApp<any>();
      if (typeof app.getUserInfo === 'function') {
        const userInfo = await app.getUserInfo();
        this.setData({
          userInfo: userInfo,
          hasLogin: true
        });
        
        wx.showToast({
          title: '登录成功',
          icon: 'success'
        });
      }
    } catch (error) {
      console.error('登录失败:', error);
      wx.showToast({
        title: '登录失败',
        icon: 'error'
      });
    }
  },

  // 处理设置项点击
  handleSetting(event: WechatMiniprogram.TouchEvent) {
    const key = event.currentTarget.dataset.key as string;
    
    switch (key) {
      case 'theme':
        this.handleThemeSwitch();
        break;
      case 'font':
        this.handleFontSetting();
        break;
      case 'export':
        wx.showToast({ title: '导出设置功能开发中', icon: 'none' });
        break;
      case 'about':
        this.handleAbout();
        break;
      default:
        wx.showToast({ title: '功能开发中', icon: 'none' });
    }
  },

  // 处理主题切换
  handleThemeSwitch() {
    const app = getApp<any>();
    const currentTheme = app.globalData.theme;
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';
    
    if (typeof app.setTheme === 'function') {
      app.setTheme(newTheme);
      
      // 更新显示
      const themeText = newTheme === 'light' ? '浅色模式' : '深色模式';
      const updatedSettings = this.data.settings.map(setting => {
        if (setting.key === 'theme') {
          return { ...setting, value: themeText };
        }
        return setting;
      });
      
      this.setData({ settings: updatedSettings });
      
      wx.showToast({
        title: `已切换为${themeText}`,
        icon: 'success'
      });
    }
  },

  // 处理字体设置
  handleFontSetting() {
    wx.showActionSheet({
      itemList: ['楷书', '行书', '隶书', '草书'],
      success: (res) => {
        const fonts = ['kaishu', 'xingshu', 'lishu', 'caoshu'];
        const fontNames = ['楷书', '行书', '隶书', '草书'];
        const selectedFont = fonts[res.tapIndex];
        const selectedFontName = fontNames[res.tapIndex];
        
        const app = getApp<any>();
        if (typeof app.updateCallipgraphyConfig === 'function') {
          app.updateCallipgraphyConfig({
            defaultFont: selectedFont
          });
          
          wx.showToast({
            title: `已设置为${selectedFontName}`,
            icon: 'success'
          });
        }
      }
    });
  },

  // 关于我们
  handleAbout() {
    wx.showModal({
      title: '关于字帖生成器',
      content: '字帖生成器 v1.0.0\n\n基于微信小程序和TDesign UI框架开发的中文书法练习工具。\n\n支持多种字体和自定义内容，让书法练习更加便捷。',
      showCancel: false,
      confirmText: '确定'
    });
  }
});
