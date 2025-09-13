// pages/index/index.ts
interface IndexPageData {
  appTitle: string;
  features: Array<{
    icon: string;
    title: string;
    description: string;
  }>;
  loading: boolean;
}

interface IndexPageMethods {
  initPage(): void;
  startCreate(): void;
  viewPrototype(): void;
  onFeatureClick(event: WechatMiniprogram.TouchEvent): void;
}

Page<IndexPageData, IndexPageMethods>({
  data: {
    appTitle: '字帖生成器',
    features: [
      {
        icon: 'edit',
        title: '个性化字帖创建',
        description: '支持自定义内容和样式'
      },
      {
        icon: 'palette',
        title: '多种书法字体',
        description: '楷书、行书、隶书等多种选择'
      },
      {
        icon: 'mobile',
        title: '便捷移动体验',
        description: '随时随地创建和分享'
      }
    ],
    loading: false
  },

  onLoad(options: Record<string, string | undefined>) {
    console.log('字帖生成小程序首页加载完成', options);
    this.initPage();
  },

  onShow() {
    console.log('首页显示');
  },

  onReady() {
    console.log('首页准备完成');
  },

  // 初始化页面
  initPage() {
    this.setData({
      loading: false
    });
  },

  // 开始创建字帖
  startCreate() {
    this.setData({ loading: true });
    
    setTimeout(() => {
      this.setData({ loading: false });
      wx.showToast({
        title: '功能开发中...',
        icon: 'none',
        duration: 2000
      });
    }, 1000);
    
    // TODO: 跳转到字帖创建页面
    // wx.navigateTo({
    //   url: '/pages/create/index'
    // });
  },

  // 查看原型设计
  viewPrototype() {
    wx.showModal({
      title: '原型设计',
      content: '原型设计文件位于 prototype 目录中，包含完整的UI设计稿',
      showCancel: false,
      confirmText: '知道了',
      success: (res) => {
        if (res.confirm) {
          console.log('用户确认查看原型设计');
        }
      }
    });
  },

  // 功能特性点击处理
  onFeatureClick(event: WechatMiniprogram.TouchEvent) {
    const index = event.currentTarget.dataset.index as number;
    const feature = this.data.features[index];
    
    if (feature) {
      wx.showToast({
        title: feature.title,
        icon: 'none'
      });
    }
  }
});
