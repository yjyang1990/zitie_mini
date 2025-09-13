// pages/index/index.ts
interface Template {
  id: string;
  title: string;
  content: string;
  category: string;
  difficulty: number;
  strokeCount: number;
  frequency: number;
  tags: string[];
  description: string;
  featured?: boolean;
  author?: string;
}

interface IndexPageData {
  appTitle: string;
  features: Array<{
    icon: string;
    title: string;
    description: string;
    action: string;
  }>;
  recentTemplates: Template[];
  selectedTemplate: Template | null;
  customText: string;
  loading: boolean;
  showCustomInput: boolean;
}

interface IndexPageMethods {
  initPage(): void;
  loadRecentTemplates(): void;
  loadTemplate(template: Template): void;
  startCreate(): void;
  openTemplateLibrary(): void;
  showCustomInput(): void;
  onCustomTextChange(event: WechatMiniprogram.CustomEvent): void;
  onCustomTextConfirm(): void;
  onTemplateClick(event: WechatMiniprogram.CustomEvent): void;
  viewPrototype(): void;
  onFeatureClick(event: WechatMiniprogram.TouchEvent): void;
}

Page<IndexPageData, IndexPageMethods>({
  data: {
    appTitle: '字帖生成器',
    features: [
      {
        icon: 'library',
        title: '精选模板库',
        description: '100+精心策划的书法练习模板',
        action: 'template_library'
      },
      {
        icon: 'edit',
        title: '自定义创建',
        description: '输入任意文字生成个性化字帖',
        action: 'custom_create'
      },
      {
        icon: 'palette',
        title: '多种字体',
        description: '楷书、行书、隶书等多种选择',
        action: 'font_options'
      },
      {
        icon: 'mobile',
        title: '便捷分享',
        description: '一键生成PDF，随时分享练习',
        action: 'share_options'
      }
    ],
    recentTemplates: [],
    selectedTemplate: null,
    customText: '',
    loading: false,
    showCustomInput: false
  },

  onLoad(options: Record<string, string | undefined>) {
    console.log('字帖生成小程序首页加载完成', options);
    this.initPage();
  },

  onShow() {
    console.log('首页显示');
    this.loadRecentTemplates();
    
    // 检查是否有从模板库选择的模板
    const app = getApp();
    if (app.globalData.selectedTemplate) {
      this.loadTemplate(app.globalData.selectedTemplate);
      app.globalData.selectedTemplate = null; // 清空全局模板
    }
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

  // 加载最近使用的模板
  async loadRecentTemplates() {
    try {
      const history = wx.getStorageSync('template_usage_history') || [];
      const templatesData = await this.getTemplatesData();
      
      // 获取最近使用的前4个模板
      const recentTemplates = history
        .slice(0, 4)
        .map((record: any) => 
          templatesData.templates.find((t: Template) => t.id === record.templateId)
        )
        .filter((template: Template) => template); // 过滤掉未找到的模板
      
      this.setData({ recentTemplates });
    } catch (error) {
      console.error('加载最近模板失败:', error);
    }
  },

  // 获取模板数据
  async getTemplatesData() {
    return new Promise((resolve, reject) => {
      try {
        const data = require('../../data/templates.json');
        resolve(data);
      } catch (error) {
        reject(error);
      }
    });
  },

  // 加载指定模板（从模板库选择后调用）
  loadTemplate(template: Template) {
    this.setData({ selectedTemplate: template });
    
    wx.showToast({
      title: `已选择：${template.title}`,
      icon: 'success',
      duration: 2000
    });
  },

  // 开始创建字帖
  startCreate() {
    if (!this.data.selectedTemplate && !this.data.customText.trim()) {
      wx.showModal({
        title: '提示',
        content: '请先选择模板或输入自定义文字',
        showCancel: false,
        confirmText: '知道了'
      });
      return;
    }

    this.setData({ loading: true });
    
    // 模拟字帖生成过程
    setTimeout(() => {
      this.setData({ loading: false });
      
      const content = this.data.selectedTemplate 
        ? this.data.selectedTemplate.content 
        : this.data.customText;
        
      wx.showModal({
        title: '字帖生成完成',
        content: `已生成包含 "${content.substring(0, 10)}${content.length > 10 ? '...' : ''}" 的字帖`,
        showCancel: false,
        confirmText: '知道了',
        success: () => {
          // TODO: 跳转到字帖预览页面
          console.log('字帖生成完成，内容:', content);
        }
      });
    }, 1500);
  },

  // 打开模板库
  openTemplateLibrary() {
    wx.switchTab({
      url: '/pages/template-library/template-library'
    });
  },

  // 显示自定义输入框
  showCustomInput() {
    this.setData({ 
      showCustomInput: true,
      selectedTemplate: null // 清空已选择的模板
    });
  },

  // 自定义文字输入改变
  onCustomTextChange(event: WechatMiniprogram.CustomEvent) {
    this.setData({
      customText: event.detail.value
    });
  },

  // 确认自定义文字输入
  onCustomTextConfirm() {
    if (!this.data.customText.trim()) {
      wx.showToast({
        title: '请输入文字内容',
        icon: 'none'
      });
      return;
    }

    if (this.data.customText.length > 500) {
      wx.showToast({
        title: '文字内容不能超过500字',
        icon: 'none'
      });
      return;
    }

    this.setData({ 
      showCustomInput: false,
      selectedTemplate: null
    });

    wx.showToast({
      title: `已输入${this.data.customText.length}个字符`,
      icon: 'success'
    });
  },

  // 最近模板点击
  onTemplateClick(event: WechatMiniprogram.CustomEvent) {
    const templateId = event.currentTarget.dataset.id;
    const template = this.data.recentTemplates.find(t => t.id === templateId);
    
    if (template) {
      this.setData({ 
        selectedTemplate: template,
        customText: '', // 清空自定义文字
        showCustomInput: false
      });
    }
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
    
    if (!feature) return;

    switch (feature.action) {
      case 'template_library':
        this.openTemplateLibrary();
        break;
      case 'custom_create':
        this.showCustomInput();
        break;
      case 'font_options':
      case 'share_options':
        wx.showToast({
          title: `${feature.title}功能开发中...`,
          icon: 'none'
        });
        break;
      default:
        wx.showToast({
          title: feature.title,
          icon: 'none'
        });
    }
  }
});
