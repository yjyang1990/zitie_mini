# 通用移动端原型设计框架

> 🎨 **适用于任何产品** | 📱 **iOS风格标准** | 🔄 **快速定制生成**

---

## 📋 框架概述

这是一个通用的移动端原型设计框架，可以快速应用到任何产品的原型设计中。只需要替换具体的内容和功能，即可生成专业级的iOS风格原型展示。

### 🎯 框架特色

- ✅ **通用适配性** - 适用于任何行业和产品类型
- ✅ **标准化组件** - 完整的iOS设计组件库
- ✅ **快速定制** - 只需替换内容，保持设计一致性
- ✅ **高质量输出** - 支持右键保存高分辨率原型图
- ✅ **响应式布局** - 自动适配各种屏幕尺寸

---

## 🎨 通用设计系统

### 1. 设备标准规格

```css
/* 通用移动端规格 - 以iPhone 12为标准 */
:root {
    --device-width: 390px;           /* 设备宽度 */
    --status-bar-height: 47px;       /* 状态栏高度 */
    --nav-bar-height: 64px;          /* 导航栏高度 */
    --tab-bar-height: 83px;          /* 底部标签栏高度 */
    --home-indicator: 34px;          /* Home指示器高度 */
    --safe-area-top: 47px;           /* 顶部安全区域 */
    --safe-area-bottom: 34px;        /* 底部安全区域 */
}
```

### 2. 通用iOS色彩系统

```css
/* iOS官方色彩 - 完整通用色板 */
:root {
    /* 主要系统色 - 可根据品牌调整 */
    --primary-color: #007AFF;        /* 主品牌色 */
    --secondary-color: #34C759;      /* 辅助色 */
    --accent-color: #FF9500;         /* 强调色 */
    --success-color: #34C759;        /* 成功状态 */
    --warning-color: #FF9500;        /* 警告状态 */
    --error-color: #FF3B30;          /* 错误状态 */
    
    /* 扩展色彩系统 */
    --color-blue: #007AFF;
    --color-green: #34C759;
    --color-orange: #FF9500;
    --color-red: #FF3B30;
    --color-purple: #AF52DE;
    --color-pink: #FF2D92;
    --color-yellow: #FFCC00;
    --color-teal: #5AC8FA;
    --color-indigo: #5856D6;
    
    /* 语义色彩系统 */
    --text-primary: #000000;
    --text-secondary: rgba(60, 60, 67, 0.6);
    --text-tertiary: rgba(60, 60, 67, 0.3);
    --text-quaternary: rgba(60, 60, 67, 0.18);
    
    /* 背景色系统 */
    --bg-primary: #FFFFFF;
    --bg-secondary: #F2F2F7;
    --bg-tertiary: #FFFFFF;
    --bg-grouped: #F2F2F7;
    --bg-grouped-secondary: #FFFFFF;
    
    /* 分隔线系统 */
    --separator: rgba(60, 60, 67, 0.29);
    --separator-opaque: #C6C6C8;
    
    /* 填充色系统 */
    --fill-primary: rgba(120, 120, 128, 0.2);
    --fill-secondary: rgba(120, 120, 128, 0.16);
    --fill-tertiary: rgba(120, 120, 128, 0.12);
    --fill-quaternary: rgba(120, 120, 128, 0.08);
}
```

### 3. 通用渐变系统

```css
/* 可定制的渐变系统 */
:root {
    /* 主要渐变 - 根据品牌调整颜色 */
    --gradient-primary: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
    --gradient-hero: linear-gradient(135deg, var(--primary-color) 0%, var(--accent-color) 50%, var(--secondary-color) 100%);
    --gradient-card: linear-gradient(135deg, rgba(255,255,255,0.95) 0%, rgba(255,255,255,0.8) 100%);
    --gradient-glass: linear-gradient(135deg, rgba(255,255,255,0.25) 0%, rgba(255,255,255,0.1) 100%);
    
    /* 背景渐变系统 */
    --gradient-bg: linear-gradient(135deg, var(--bg-secondary) 0%, #E5E5EA 25%, #D1D1D6 50%, #E5E5EA 75%, var(--bg-secondary) 100%);
}
```

### 4. 通用毛玻璃效果

```css
/* 5级毛玻璃效果系统 */
:root {
    --glass-ultra-thin: backdrop-filter: blur(10px) saturate(180%) contrast(120%) brightness(110%);
    --glass-thin: backdrop-filter: blur(20px) saturate(180%) contrast(120%) brightness(110%);
    --glass-regular: backdrop-filter: blur(30px) saturate(180%) contrast(120%) brightness(110%);
    --glass-thick: backdrop-filter: blur(40px) saturate(200%) contrast(130%) brightness(120%);
    --glass-ultra-thick: backdrop-filter: blur(60px) saturate(220%) contrast(140%) brightness(130%);
}
```

### 5. 通用阴影系统

```css
/* 6级阴影系统 - 适用于所有组件 */
:root {
    --shadow-1: 0 1px 2px rgba(0, 0, 0, 0.04), 0 1px 3px rgba(0, 0, 0, 0.06);
    --shadow-2: 0 2px 4px rgba(0, 0, 0, 0.06), 0 1px 6px rgba(0, 0, 0, 0.08);
    --shadow-3: 0 4px 8px rgba(0, 0, 0, 0.08), 0 2px 12px rgba(0, 0, 0, 0.12);
    --shadow-4: 0 8px 16px rgba(0, 0, 0, 0.10), 0 4px 20px rgba(0, 0, 0, 0.16);
    --shadow-5: 0 16px 24px rgba(0, 0, 0, 0.12), 0 8px 32px rgba(0, 0, 0, 0.20);
    --shadow-6: 0 24px 40px rgba(0, 0, 0, 0.16), 0 12px 60px rgba(0, 0, 0, 0.28);
    
    /* 彩色阴影 - 根据主题色调整 */
    --shadow-primary: 0 8px 16px rgba(0, 122, 255, 0.15), 0 4px 20px rgba(0, 122, 255, 0.08);
    --shadow-secondary: 0 8px 16px rgba(52, 199, 89, 0.15), 0 4px 20px rgba(52, 199, 89, 0.08);
    --shadow-accent: 0 8px 16px rgba(255, 149, 0, 0.15), 0 4px 20px rgba(255, 149, 0, 0.08);
}
```

---

## 🏗️ 通用组件架构

### 1. 基础页面结构模板

```html
<!-- 通用页面容器 -->
<div class="page-container">
    <div class="page-title">[图标] [页面名称]</div>
    
    <!-- 状态栏 -->
    <div class="status-bar">
        <span class="time">9:41</span>
        <span class="battery-status">📶📶🔋</span>
    </div>
    
    <div class="content">
        <!-- 导航栏 (可选) -->
        <div class="nav-bar">
            <div class="nav-back">‹ 返回</div>
            <div class="nav-title">[页面标题]</div>
            <div class="nav-action">[操作]</div>
        </div>
        
        <!-- 主要内容区域 -->
        <div class="page-content">
            <!-- 根据产品功能自定义内容 -->
        </div>
        
        <!-- 底部标签栏 (可选) -->
        <div class="tab-bar">
            <!-- 5个标签项 -->
        </div>
    </div>
</div>
```

### 2. 通用卡片组件

```html
<!-- 标准iOS卡片 -->
<div class="ios-card [elevated]">
    <div class="ios-card-header">[分组标题]</div>
    <div class="ios-list-item">
        <div class="ios-list-item-icon" style="background: [渐变色]; color: white;">[图标]</div>
        <div class="ios-list-item-content">
            <div class="ios-list-item-title">[主标题]</div>
            <div class="ios-list-item-subtitle">[副标题/描述]</div>
        </div>
        <div class="ios-list-item-arrow">›</div>
    </div>
</div>
```

### 3. 通用按钮系统

```html
<!-- 主要操作按钮 -->
<button class="ios-button">[主要操作]</button>

<!-- 次要操作按钮 -->
<button class="ios-button secondary">[次要操作]</button>

<!-- 危险操作按钮 -->
<button class="ios-button destructive">[删除/危险操作]</button>

<!-- 成功确认按钮 -->
<button class="ios-button success">[确认/完成操作]</button>
```

### 4. 通用设置行组件

```html
<!-- 设置项行 -->
<div class="setting-row">
    <span class="setting-label">[设置项名称]</span>
    <span class="setting-value">[当前值] ›</span>
</div>

<!-- 开关设置行 -->
<div class="setting-row">
    <span class="setting-label">[开关项名称]</span>
    <div class="ios-switch">
        <div class="switch-slider [off]"></div>
    </div>
</div>
```

### 5. 通用输入组件

```html
<!-- 文本输入框 -->
<input class="ios-input" type="text" placeholder="[提示文字]">

<!-- 多行文本框 -->
<textarea class="ios-input" rows="4" placeholder="[提示文字]"></textarea>
```

---

## 📱 通用页面类型模板

### 页面类型1: 功能导航首页

```text
用途: 产品功能入口、导航中心
组件: 英雄区域 + 功能卡片组 + 底部Tab Bar
适用: 所有产品的主页面
```

### 页面类型2: 内容创建/编辑页

```text
用途: 创建内容、编辑信息、表单填写
组件: 导航栏 + 输入区域 + 预览区域 + 操作按钮
适用: 发布内容、编辑资料、创建任务等
```

### 页面类型3: 内容浏览/选择页

```text
用途: 浏览列表、选择模板、分类展示
组件: 导航栏 + 分类卡片 + 列表项 + 搜索功能
适用: 模板库、商品列表、文章列表等
```

### 页面类型4: 个人作品/历史页

```text
用途: 查看历史、管理内容、数据统计
组件: 导航栏 + 时间线列表 + 统计卡片 + 操作按钮
适用: 订单历史、作品集、收藏夹等
```

### 页面类型5: 设置配置页

```text
用途: 参数设置、偏好配置、功能开关
组件: 导航栏 + 设置分组 + 开关/选择器 + 重置按钮
适用: 应用设置、账号设置、功能配置等
```

### 页面类型6: 用户中心页

```text
用途: 个人信息、账号管理、应用偏好
组件: 用户信息卡片 + 设置分组 + 会员功能 + 帮助支持
适用: 个人中心、我的账户、用户资料等
```

### 页面类型7: 预览/结果页

```text
用途: 内容预览、结果展示、分享导出
组件: 预览容器 + 操作选项 + 分享按钮 + 快捷操作
适用: 内容预览、订单详情、结果展示等
```

---

## 🎨 多层背景纹理系统

### 通用背景实现

```css
/* 7层复合背景纹理 - 可调整颜色主题 */
body::before {
    content: '';
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: 
        /* 第一层：主题色彩渐变 */
        radial-gradient(circle at 20% 20%, rgba(var(--primary-rgb), 0.15) 0%, transparent 50%),
        radial-gradient(circle at 80% 80%, rgba(var(--secondary-rgb), 0.15) 0%, transparent 50%),
        radial-gradient(circle at 60% 40%, rgba(var(--accent-rgb), 0.12) 0%, transparent 50%),
        /* 第二层：纹理细节 */
        radial-gradient(circle at 40% 70%, rgba(var(--primary-rgb), 0.08) 0%, transparent 40%),
        radial-gradient(circle at 90% 30%, rgba(var(--accent-rgb), 0.08) 0%, transparent 40%),
        /* 第三层：微纹理 */
        radial-gradient(circle at 15% 85%, rgba(var(--secondary-rgb), 0.06) 0%, transparent 30%),
        radial-gradient(circle at 75% 15%, rgba(var(--accent-rgb), 0.06) 0%, transparent 30%);
    opacity: 0.8;
    pointer-events: none;
    z-index: -2;
    animation: backgroundFloat 20s ease-in-out infinite alternate;
}
```

### 品牌色RGB值配置

```css
/* 根据不同产品主题配置RGB值 */
:root {
    /* 示例：蓝色主题 */
    --primary-rgb: 0, 122, 255;     /* #007AFF */
    --secondary-rgb: 52, 199, 89;   /* #34C759 */
    --accent-rgb: 255, 149, 0;      /* #FF9500 */
    
    /* 示例：紫色主题 */
    /* --primary-rgb: 175, 82, 222;  /* #AF52DE */
    /* --secondary-rgb: 88, 86, 214; /* #5856D6 */
    /* --accent-rgb: 255, 45, 146;   /* #FF2D92 */
}
```

---

## 🔄 快速定制指南

### 步骤1: 确定产品主题

```text
1. 选择主品牌色 (--primary-color)
2. 选择辅助色 (--secondary-color)  
3. 选择强调色 (--accent-color)
4. 配置对应的RGB值
```

### 步骤2: 设计功能结构

```text
1. 确定需要的页面数量 (建议5-7个)
2. 为每个页面选择合适的页面类型模板
3. 定义页面标题和图标
4. 规划页面间的导航关系
```

### 步骤3: 填充具体内容

```text
1. 替换页面标题和描述文字
2. 更换功能图标 (emoji或自定义图标)
3. 调整卡片分组和列表项内容
4. 配置设置项和选项值
5. 添加品牌特色的预览内容
```

### 步骤4: 调整视觉效果

```text
1. 根据品牌色调整渐变配色
2. 修改图标背景的渐变色
3. 调整英雄区域的背景效果
4. 优化阴影颜色以匹配主题
```

---

## 🚀 完整生成指令模板

### 通用生成指令

```text
根据以下要求生成移动端原型展示:

【产品信息】
- 产品名称: [产品名称]
- 产品类型: [工具类/内容类/社交类/电商类等]
- 主要功能: [核心功能描述]

【视觉主题】  
- 主品牌色: [十六进制色值]
- 辅助色: [十六进制色值]
- 强调色: [十六进制色值]
- 产品图标: [emoji或描述]

【页面结构】
需要生成 [X] 个页面:
1. [页面名称] - [页面类型] - [主要功能]
2. [页面名称] - [页面类型] - [主要功能]
...

【技术要求】
- 严格遵循iPhone 12尺寸 (390px × 自适应高度)
- 使用通用iOS设计系统
- 实现多层毛玻璃纹理背景
- 应用6级优雅阴影系统
- 支持右键保存高质量图片
- 响应式网格布局 (1-4列自适应)
- 无滚动效果，完整内容展示

【预期效果】
专业级iOS设计质感，接近原生应用效果，支持高分辨率图片导出
```

### 具体应用示例

#### 示例1: 健身应用

```text
【产品信息】
- 产品名称: 💪 智能健身助手
- 产品类型: 健康健身工具类
- 主要功能: 训练计划、动作指导、进度跟踪

【视觉主题】
- 主品牌色: #FF6B35 (活力橙)
- 辅助色: #34C759 (健康绿)  
- 强调色: #007AFF (科技蓝)
- 产品图标: 💪

【页面结构】
1. 健身首页 - 功能导航首页 - 训练入口和数据概览
2. 训练计划 - 内容浏览页 - 训练计划选择和定制
3. 动作库 - 内容浏览页 - 健身动作教学和分类
4. 训练记录 - 个人作品页 - 历史训练和数据统计  
5. 计划设置 - 设置配置页 - 训练参数和提醒设置
6. 个人中心 - 用户中心页 - 个人资料和应用偏好
7. 训练详情 - 预览结果页 - 训练详情和分享功能
```

#### 示例2: 记账应用

```text
【产品信息】
- 产品名称: 💰 智能记账本
- 产品类型: 财务管理工具类
- 主要功能: 收支记录、分类统计、预算管理

【视觉主题】
- 主品牌色: #34C759 (财富绿)
- 辅助色: #007AFF (信任蓝)
- 强调色: #FF9500 (提醒橙)
- 产品图标: 💰

【页面结构】
1. 记账首页 - 功能导航首页 - 记账入口和财务概览
2. 添加记录 - 内容创建页 - 收支记录和分类选择
3. 分类管理 - 内容浏览页 - 收支分类和标签管理
4. 账单历史 - 个人作品页 - 历史账单和统计图表
5. 预算设置 - 设置配置页 - 预算限额和提醒配置
6. 个人中心 - 用户中心页 - 账户设置和数据管理
7. 统计报表 - 预览结果页 - 财务报表和分析图表
```

---

## 📐 响应式布局配置

### 通用响应式规则

```css
/* 通用响应式网格 */
.pages-showcase {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(390px, 1fr));
    gap: 40px;
    padding: 40px 20px;
    max-width: 1800px;
    margin: 0 auto;
    justify-items: center;
    align-items: start;
}

/* 移动端 */
@media (max-width: 480px) {
    .pages-showcase {
        grid-template-columns: 1fr;
        padding: 20px 10px;
        gap: 30px;
    }
}

/* 平板端 */
@media (min-width: 900px) {
    .pages-showcase {
        grid-template-columns: repeat(2, 390px);
        gap: 60px;
    }
}

/* 桌面端 */
@media (min-width: 1400px) {
    .pages-showcase {
        grid-template-columns: repeat(3, 390px);
        gap: 60px;
    }
}

/* 大屏桌面 */
@media (min-width: 1800px) {
    .pages-showcase {
        grid-template-columns: repeat(4, 390px);
        gap: 80px;
    }
}
```

---

## 🖼️ 通用右键保存功能

### 标准实现代码

```javascript
// 通用页面保存功能
function savePageAsImage(container, title) {
    const options = {
        backgroundColor: null,
        scale: 2,
        useCORS: true,
        allowTaint: false,
        width: 390,
        height: container.offsetHeight,
        ignoreElements: function(element) {
            return element.classList.contains('save-hint') || 
                   element.classList.contains('loading-indicator');
        }
    };
    
    html2canvas(container, options)
        .then(function(canvas) {
            const link = document.createElement('a');
            link.download = `${title.replace(/[^\w\s]/gi, '')}_${new Date().getTime()}.png`;
            link.href = canvas.toDataURL('image/png');
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        });
}
```

---

## 📦 必需资源和依赖

### 外部库依赖

```html
<!-- html2canvas - 页面截图保存 -->
<script src="https://cdn.jsdelivr.net/npm/html2canvas@1.4.1/dist/html2canvas.min.js"></script>
```

### 字体系统

```css
body {
    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', 'PingFang SC', 'Hiragino Sans GB', sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
}
```

### 移动端优化

```javascript
// 标准移动端优化代码
document.addEventListener('DOMContentLoaded', function() {
    // 禁用双击缩放
    document.addEventListener('dblclick', function(e) {
        e.preventDefault();
    }, { passive: false });
    
    // 防止页面弹性滚动
    document.body.addEventListener('touchmove', function(e) {
        if (e.target === document.body) {
            e.preventDefault();
        }
    }, { passive: false });
});
```

---

## 🎯 使用流程总结

### 1. 准备阶段

- 确定产品信息和主题色彩
- 规划功能页面和导航结构
- 准备具体的内容和文案

### 2. 生成阶段  

- 使用通用生成指令
- 替换模板中的占位内容
- 调整视觉主题和配色

### 3. 定制阶段

- 优化页面布局和组件
- 调整交互效果和动画
- 测试响应式表现

### 4. 导出阶段

- 验证右键保存功能
- 导出高质量原型图
- 用于演示和文档

---

**🚀 目标**: 提供一个完全通用的原型设计框架，通过简单的内容替换和主题配置，快速生成任何产品的专业级移动端原型展示。

> 这个框架可以应用到电商、社交、工具、内容、健康、教育、金融等任何行业的产品原型设计中！
