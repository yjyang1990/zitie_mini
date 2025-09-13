// pages/index/index.js
Page({
  data: {
    
  },

  onLoad() {
    console.log('字帖生成小程序首页加载完成');
  },

  // 开始创建字帖
  startCreate() {
    wx.showToast({
      title: '功能开发中...',
      icon: 'none',
      duration: 2000
    });
    
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
      confirmText: '知道了'
    });
  }
});