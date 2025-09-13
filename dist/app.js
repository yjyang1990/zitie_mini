// app.ts
App({
    globalData: {
        userInfo: undefined,
        hasLogin: false,
        theme: 'light',
        systemInfo: undefined,
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
        config: {
            version: '1.0.0',
            apiBaseUrl: '',
            maxTextLength: 500,
            enableAnalytics: true
        }
    },
    onLaunch() {
        console.log('字帖生成器小程序启动');
        this.checkSystemInfo();
        this.initTDesign();
    },
    onShow() {
        console.log('字帖生成器小程序显示');
    },
    onHide() {
        console.log('字帖生成器小程序隐藏');
    },
    onError(error) {
        console.error('字帖生成器小程序发生错误:', error);
    },
    // 检查系统信息
    checkSystemInfo() {
        try {
            const systemInfo = wx.getSystemInfoSync();
            this.globalData.systemInfo = systemInfo;
            console.log('系统信息:', systemInfo);
            // 根据系统主题设置应用主题
            if (systemInfo.theme) {
                this.globalData.theme = systemInfo.theme;
            }
        }
        catch (error) {
            console.error('获取系统信息失败:', error);
        }
    },
    // 初始化 TDesign
    initTDesign() {
        // TDesign 主题配置可以在这里进行
        console.log('TDesign UI 框架初始化完成');
    },
    // 获取用户信息
    getUserInfo() {
        return new Promise((resolve, reject) => {
            if (this.globalData.userInfo) {
                resolve(this.globalData.userInfo);
                return;
            }
            wx.getUserProfile({
                desc: '用于完善用户资料',
                success: (res) => {
                    this.globalData.userInfo = res.userInfo;
                    this.globalData.hasLogin = true;
                    resolve(res.userInfo);
                },
                fail: reject
            });
        });
    },
    // 设置主题
    setTheme(theme) {
        this.globalData.theme = theme;
        // 这里可以添加主题切换逻辑
    },
    // 获取字帖配置
    getCallipgraphyConfig() {
        return this.globalData.calligraphy;
    },
    // 更新字帖配置
    updateCallipgraphyConfig(config) {
        if (this.globalData.calligraphy) {
            this.globalData.calligraphy = {
                ...this.globalData.calligraphy,
                ...config
            };
        }
    }
});
