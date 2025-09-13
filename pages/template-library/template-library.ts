// Remove utils import since we'll use wx API directly

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
  // Computed properties for WXML display
  categoryName?: string;
  categoryIcon?: string;
  categoryColor?: string;
  contentPreview?: string;
  contentNote?: string;
}

interface Category {
  id: string;
  name: string;
  description: string;
  icon: string;
  color: string;
}

interface TemplateData {
  categories: Category[];
  templates: Template[];
  metadata: {
    version: string;
    totalTemplates: number;
    lastUpdated: string;
    categories: number;
    difficultyLevels: number;
    author: string;
    description: string;
  };
}

interface PageData {
  templates: Template[];
  filteredTemplates: Template[];
  categories: Category[];
  currentCategory: string;
  searchQuery: string;
  sortBy: string;
  viewMode: 'grid' | 'list';
  difficulty: number;
  favorites: string[];
  loading: boolean;
  showPreview: boolean;
  selectedTemplate: Template | null;
}

Page({
  data: {
    templates: [],
    filteredTemplates: [],
    categories: [],
    currentCategory: 'all',
    searchQuery: '',
    sortBy: 'default',
    viewMode: 'grid',
    difficulty: 0,
    favorites: [],
    loading: true,
    showPreview: false,
    selectedTemplate: null
  },

  onLoad() {
    this.loadTemplates();
    this.loadFavorites();
  },

  onShow() {
    // 每次显示页面时刷新收藏状态
    this.loadFavorites();
  },

  // 加载模板数据
  async loadTemplates() {
    this.setData({ loading: true });
    
    try {
      // 这里模拟加载模板数据，实际项目中可能从服务器或本地文件加载
      const templateData: TemplateData = await this.getTemplateData();
      
      // 预处理模板数据
      const processedTemplates = this.preprocessTemplates(templateData.templates);
      
      this.setData({
        templates: processedTemplates,
        filteredTemplates: processedTemplates,
        categories: templateData.categories,
        loading: false
      });

      // 应用当前筛选条件
      this.applyFilters();
      
    } catch (error) {
      console.error('加载模板失败:', error);
      wx.showToast({
        title: '加载模板失败',
        icon: 'none'
      });
      this.setData({ loading: false });
    }
  },

  // 获取模板数据
  async getTemplateData(): Promise<TemplateData> {
    // 这里应该从实际数据源加载，为了演示直接返回结构化数据
    return new Promise((resolve) => {
      // 模拟网络延迟
      setTimeout(() => {
        resolve(require('../../data/templates.js'));
      }, 500);
    });
  },

  // 加载收藏数据
  loadFavorites() {
    const favorites = wx.getStorageSync('template_favorites') || [];
    this.setData({ favorites });
  },

  // 搜索模板
  onSearch(event: WechatMiniprogram.CustomEvent) {
    const query = event.detail.value || '';
    this.setData({ searchQuery: query });
    this.applyFilters();
  },

  // 分类筛选
  onCategoryChange(event: WechatMiniprogram.CustomEvent) {
    const categoryId = event.currentTarget.dataset.category;
    this.setData({ currentCategory: categoryId });
    this.applyFilters();
  },

  // 难度筛选
  onDifficultyChange(event: WechatMiniprogram.CustomEvent) {
    const difficulty = parseInt(event.detail.value);
    this.setData({ difficulty });
    this.applyFilters();
  },

  // 排序方式改变
  onSortChange(event: WechatMiniprogram.CustomEvent) {
    const sortBy = event.detail.value;
    this.setData({ sortBy });
    this.applyFilters();
  },

  // 视图模式切换
  onViewModeChange(event: WechatMiniprogram.CustomEvent) {
    const viewMode = event.currentTarget.dataset.mode as 'grid' | 'list';
    this.setData({ viewMode });
    wx.setStorageSync('template_view_mode', viewMode);
  },

  // 预处理模板数据，添加计算属性
  preprocessTemplates(templates: Template[]): Template[] {
    return templates.map(template => {
      const category = this.data.categories.find(cat => cat.id === template.category);
      return {
        ...template,
        categoryName: category ? category.name : '未知',
        categoryIcon: category ? category.icon : 'help-circle',
        categoryColor: category ? category.color : '#999999',
        contentPreview: template.content.length > 20 ? template.content.substring(0, 20) + '...' : template.content,
        contentNote: template.content.length > 15 ? template.content.substring(0, 15) + '...' : template.content
      };
    });
  },

  // 应用筛选条件
  applyFilters() {
    let filtered = [...this.data.templates];
    
    // 按分类筛选
    if (this.data.currentCategory && this.data.currentCategory !== 'all') {
      filtered = filtered.filter(template => template.category === this.data.currentCategory);
    }
    
    // 按搜索关键词筛选
    if (this.data.searchQuery) {
      const query = this.data.searchQuery.toLowerCase();
      filtered = filtered.filter(template =>
        template.title.toLowerCase().includes(query) ||
        template.content.includes(query) ||
        template.tags.some(tag => tag.includes(query)) ||
        template.description.includes(query)
      );
    }
    
    // 按难度筛选
    if (this.data.difficulty > 0) {
      filtered = filtered.filter(template => template.difficulty === this.data.difficulty);
    }
    
    // 排序
    filtered = this.sortTemplates(filtered, this.data.sortBy);
    
    // 确保预处理过的数据包含计算属性
    const processedFiltered = this.preprocessTemplates(filtered);
    
    this.setData({ filteredTemplates: processedFiltered });
  },

  // 排序模板
  sortTemplates(templates: Template[], sortBy: string): Template[] {
    switch (sortBy) {
      case 'difficulty_asc':
        return templates.sort((a, b) => a.difficulty - b.difficulty);
      case 'difficulty_desc':
        return templates.sort((a, b) => b.difficulty - a.difficulty);
      case 'stroke_count_asc':
        return templates.sort((a, b) => a.strokeCount - b.strokeCount);
      case 'stroke_count_desc':
        return templates.sort((a, b) => b.strokeCount - a.strokeCount);
      case 'frequency':
        return templates.sort((a, b) => b.frequency - a.frequency);
      case 'featured':
        return templates.sort((a, b) => (b.featured ? 1 : 0) - (a.featured ? 1 : 0));
      default:
        return templates;
    }
  },

  // 模板点击事件
  onTemplateClick(event: WechatMiniprogram.CustomEvent) {
    const templateId = event.currentTarget.dataset.id;
    const template = this.data.templates.find(t => t.id === templateId);
    
    if (template) {
      this.setData({
        selectedTemplate: template,
        showPreview: true
      });
    }
  },

  // 关闭预览
  onClosePreview() {
    this.setData({
      showPreview: false,
      selectedTemplate: null
    });
  },

  // 切换收藏状态
  onToggleFavorite(event: WechatMiniprogram.CustomEvent) {
    const templateId = event.currentTarget.dataset.id;
    let favorites = [...this.data.favorites];
    
    const index = favorites.indexOf(templateId);
    if (index > -1) {
      // 取消收藏
      favorites.splice(index, 1);
      wx.showToast({
        title: '已取消收藏',
        icon: 'none'
      });
    } else {
      // 添加收藏
      favorites.push(templateId);
      wx.showToast({
        title: '已添加收藏',
        icon: 'success'
      });
    }
    
    this.setData({ favorites });
    wx.setStorageSync('template_favorites', favorites);
  },

  // 使用模板
  onUseTemplate(event: WechatMiniprogram.CustomEvent) {
    const templateId = event.currentTarget.dataset.id;
    const template = this.data.templates.find(t => t.id === templateId);
    
    if (template) {
      // 保存选择的模板到全局数据
      const app = getApp();
      app.globalData.selectedTemplate = template;
      
      // 跳转到主页并传递模板数据
      wx.switchTab({
        url: '/pages/index/index',
        success: () => {
          // 通知首页刷新数据
          const pages = getCurrentPages();
          const indexPage = pages.find(page => page.route === 'pages/index/index');
          if (indexPage && indexPage.loadTemplate) {
            (indexPage as any).loadTemplate(template);
          }
        }
      });
      
      // 记录使用历史
      this.recordTemplateUsage(templateId);
    }
  },

  // 记录模板使用历史
  recordTemplateUsage(templateId: string) {
    const history = wx.getStorageSync('template_usage_history') || [];
    const now = Date.now();
    
    // 移除旧记录
    const filteredHistory = history.filter((record: any) => record.templateId !== templateId);
    
    // 添加新记录
    filteredHistory.unshift({ templateId, usedAt: now });
    
    // 保持最多50条记录
    const limitedHistory = filteredHistory.slice(0, 50);
    
    wx.setStorageSync('template_usage_history', limitedHistory);
  },

  // 分享模板
  onShareTemplate(event: WechatMiniprogram.CustomEvent) {
    const templateId = event.currentTarget.dataset.id;
    const template = this.data.templates.find(t => t.id === templateId);
    
    if (template) {
      return {
        title: `${template.title} - ${template.description}`,
        path: `/pages/template-library/template-library?template=${templateId}`,
        imageUrl: '/images/share-template.png' // 需要准备分享图片
      };
    }
  },

  // 页面分享
  onShareAppMessage() {
    return {
      title: '字帖生成器 - 精选书法练习模板',
      path: '/pages/template-library/template-library',
      imageUrl: '/images/share-library.png'
    };
  },

  // 清空搜索
  onClearSearch() {
    this.setData({ searchQuery: '' });
    this.applyFilters();
  },

  // 重置筛选条件
  onResetFilters() {
    this.setData({
      currentCategory: 'all',
      searchQuery: '',
      sortBy: 'default',
      difficulty: 0
    });
    this.applyFilters();
  },

  // 下拉刷新
  onPullDownRefresh() {
    this.loadTemplates().then(() => {
      wx.stopPullDownRefresh();
    });
  }
});
