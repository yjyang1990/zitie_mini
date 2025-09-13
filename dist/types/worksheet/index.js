"use strict";
/**
 * 字帖工作表相关类型定义
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_WORKSHEET_CONFIG = exports.PRESET_FONT_CONFIGS = exports.PRESET_GRID_CONFIGS = exports.FontType = exports.GridType = void 0;
// 网格类型枚举
var GridType;
(function (GridType) {
    GridType["TIAN_ZI"] = "tian_zi";
    GridType["MI_ZI"] = "mi_zi";
    GridType["JIU_GONG"] = "jiu_gong"; // 九宫格
})(GridType || (exports.GridType = GridType = {}));
// 字体类型枚举
var FontType;
(function (FontType) {
    FontType["KAISHU"] = "kaishu";
    FontType["XINGSHU"] = "xingshu";
    FontType["LISHU"] = "lishu";
    FontType["CAOSHU"] = "caoshu"; // 草书
})(FontType || (exports.FontType = FontType = {}));
// 预定义网格配置
exports.PRESET_GRID_CONFIGS = {
    [GridType.TIAN_ZI]: {
        type: GridType.TIAN_ZI,
        lineWidth: 1,
        mainLineColor: '#333333',
        helperLineColor: '#cccccc',
        showHelperLines: true
    },
    [GridType.MI_ZI]: {
        type: GridType.MI_ZI,
        lineWidth: 1,
        mainLineColor: '#333333',
        helperLineColor: '#cccccc',
        showHelperLines: true
    },
    [GridType.JIU_GONG]: {
        type: GridType.JIU_GONG,
        lineWidth: 1,
        mainLineColor: '#333333',
        helperLineColor: '#cccccc',
        showHelperLines: true
    }
};
// 预定义字体配置
exports.PRESET_FONT_CONFIGS = {
    [FontType.KAISHU]: {
        type: FontType.KAISHU,
        family: 'KaiTi, STKaiti, serif',
        color: '#000000',
        weight: 'normal'
    },
    [FontType.XINGSHU]: {
        type: FontType.XINGSHU,
        family: 'STXingkai, cursive',
        color: '#000000',
        weight: 'normal'
    },
    [FontType.LISHU]: {
        type: FontType.LISHU,
        family: 'STLiSu, serif',
        color: '#000000',
        weight: 'normal'
    },
    [FontType.CAOSHU]: {
        type: FontType.CAOSHU,
        family: 'STCaoshu, cursive',
        color: '#000000',
        weight: 'normal'
    }
};
// 默认配置
exports.DEFAULT_WORKSHEET_CONFIG = {
    gridConfig: {
        ...exports.PRESET_GRID_CONFIGS[GridType.TIAN_ZI],
        cellSize: 120
    },
    fontConfig: {
        ...exports.PRESET_FONT_CONFIGS[FontType.KAISHU],
        size: 80
    },
    layoutConfig: {
        rows: 8,
        cols: 6,
        padding: 20,
        margin: 10,
        spacing: 5
    },
    canvasConfig: {
        width: 750,
        height: 1000,
        pixelRatio: 2,
        backgroundColor: '#ffffff',
        quality: 'high'
    }
};
