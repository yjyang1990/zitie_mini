"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const index_1 = require("../../utils/index");
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
            const templateData = await this.getTemplateData();
            this.setData({
                templates: templateData.templates,
                filteredTemplates: templateData.templates,
                categories: templateData.categories,
                loading: false
            });
            // 应用当前筛选条件
            this.applyFilters();
        }
        catch (error) {
            console.error('加载模板失败:', error);
            wx.showToast({
                title: '加载模板失败',
                icon: 'none'
            });
            this.setData({ loading: false });
        }
    },
    // 获取模板数据
    async getTemplateData() {
        // 这里应该从实际数据源加载，为了演示直接返回结构化数据
        return new Promise((resolve) => {
            // 模拟网络延迟
            setTimeout(() => {
                resolve(require('../../data/templates.json'));
            }, 500);
        });
    },
    // 加载收藏数据
    loadFavorites() {
        const favorites = (0, index_1.getStorageSync)('template_favorites', []);
        this.setData({ favorites });
    },
    // 搜索模板
    onSearch(event) {
        const query = event.detail.value || '';
        this.setData({ searchQuery: query });
        this.applyFilters();
    },
    // 分类筛选
    onCategoryChange(event) {
        const categoryId = event.currentTarget.dataset.category;
        this.setData({ currentCategory: categoryId });
        this.applyFilters();
    },
    // 难度筛选
    onDifficultyChange(event) {
        const difficulty = parseInt(event.detail.value);
        this.setData({ difficulty });
        this.applyFilters();
    },
    // 排序方式改变
    onSortChange(event) {
        const sortBy = event.detail.value;
        this.setData({ sortBy });
        this.applyFilters();
    },
    // 视图模式切换
    onViewModeChange(event) {
        const viewMode = event.currentTarget.dataset.mode;
        this.setData({ viewMode });
        (0, index_1.setStorageSync)('template_view_mode', viewMode);
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
            filtered = filtered.filter(template => template.title.toLowerCase().includes(query) ||
                template.content.includes(query) ||
                template.tags.some(tag => tag.includes(query)) ||
                template.description.includes(query));
        }
        // 按难度筛选
        if (this.data.difficulty > 0) {
            filtered = filtered.filter(template => template.difficulty === this.data.difficulty);
        }
        // 排序
        filtered = this.sortTemplates(filtered, this.data.sortBy);
        this.setData({ filteredTemplates: filtered });
    },
    // 排序模板
    sortTemplates(templates, sortBy) {
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
    onTemplateClick(event) {
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
    onToggleFavorite(event) {
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
        }
        else {
            // 添加收藏
            favorites.push(templateId);
            wx.showToast({
                title: '已添加收藏',
                icon: 'success'
            });
        }
        this.setData({ favorites });
        (0, index_1.setStorageSync)('template_favorites', favorites);
    },
    // 使用模板
    onUseTemplate(event) {
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
                        indexPage.loadTemplate(template);
                    }
                }
            });
            // 记录使用历史
            this.recordTemplateUsage(templateId);
        }
    },
    // 记录模板使用历史
    recordTemplateUsage(templateId) {
        const history = (0, index_1.getStorageSync)('template_usage_history', []);
        const now = Date.now();
        // 移除旧记录
        const filteredHistory = history.filter((record) => record.templateId !== templateId);
        // 添加新记录
        filteredHistory.unshift({ templateId, usedAt: now });
        // 保持最多50条记录
        const limitedHistory = filteredHistory.slice(0, 50);
        (0, index_1.setStorageSync)('template_usage_history', limitedHistory);
    },
    // 分享模板
    onShareTemplate(event) {
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
