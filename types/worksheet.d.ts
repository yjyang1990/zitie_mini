/**
 * 字帖工作表相关类型定义
 */

// 网格类型枚举
export enum GridType {
  TIAN_ZI = 'tian_zi',    // 田字格
  MI_ZI = 'mi_zi',        // 米字格
  JIU_GONG = 'jiu_gong'   // 九宫格
}

// 字体类型枚举
export enum FontType {
  KAISHU = 'kaishu',      // 楷书
  XINGSHU = 'xingshu',    // 行书
  LISHU = 'lishu',        // 隶书
  CAOSHU = 'caoshu'       // 草书
}

// 网格配置接口
export interface GridConfig {
  type: GridType;
  cellSize: number;        // 单元格大小 (px)
  lineWidth: number;       // 网格线宽度
  mainLineColor: string;   // 主线颜色
  helperLineColor: string; // 辅助线颜色
  showHelperLines: boolean; // 是否显示辅助线
}

// 字体配置接口
export interface FontConfig {
  type: FontType;
  family: string;          // CSS字体族
  size: number;            // 字体大小
  color: string;           // 字体颜色
  weight: string;          // 字体粗细
}

// 布局配置接口
export interface LayoutConfig {
  rows: number;            // 行数
  cols: number;            // 列数
  padding: number;         // 内边距
  margin: number;          // 外边距
  spacing: number;         // 字符间距
}

// Canvas配置接口
export interface CanvasConfig {
  width: number;           // Canvas宽度
  height: number;          // Canvas高度
  pixelRatio: number;      // 设备像素比
  backgroundColor: string; // 背景颜色
  quality: 'low' | 'medium' | 'high'; // 渲染质量
}

// 工作表数据接口
export interface WorksheetData {
  // 步骤1: 输入数据
  text: string;            // 输入的文字内容
  characterCount: number;  // 字符数量
  
  // 步骤2: 网格选择
  gridConfig: GridConfig;
  
  // 步骤3: 自定义设置
  fontConfig: FontConfig;
  layoutConfig: LayoutConfig;
  
  // 步骤4: 预览和导出
  canvasConfig: CanvasConfig;
  
  // 元数据
  id: string;              // 唯一标识
  createdAt: Date;         // 创建时间
  updatedAt: Date;         // 更新时间
  version: string;         // 版本号
}

// 导出选项接口
export interface ExportOptions {
  format: 'png' | 'jpg' | 'pdf';
  quality: number;         // 图片质量 (0-1)
  scale: number;           // 缩放比例
  dpi: number;             // 分辨率
  fileName?: string;       // 文件名
}

// Canvas渲染选项接口
export interface RenderOptions {
  showGrid: boolean;       // 是否显示网格
  showText: boolean;       // 是否显示文字
  previewMode: boolean;    // 是否预览模式
  highlightCells: number[]; // 高亮单元格索引
}

// 步骤导航状态接口
export interface StepNavigation {
  currentStep: number;     // 当前步骤 (1-4)
  completedSteps: boolean[]; // 已完成的步骤
  canProceed: boolean;     // 是否可以继续下一步
  errors: string[];        // 错误信息
}

// 字符位置信息接口
export interface CharacterPosition {
  char: string;            // 字符
  x: number;               // x坐标
  y: number;               // y坐标
  cellIndex: number;       // 单元格索引
  row: number;             // 行号
  col: number;             // 列号
}

// 网格单元格信息接口
export interface GridCell {
  index: number;           // 单元格索引
  x: number;               // x坐标
  y: number;               // y坐标
  width: number;           // 宽度
  height: number;          // 高度
  character?: string;      // 字符内容
  isEmpty: boolean;        // 是否为空
}

// 预定义网格配置
export const PRESET_GRID_CONFIGS: Record<GridType, Omit<GridConfig, 'cellSize'>> = {
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
export const PRESET_FONT_CONFIGS: Record<FontType, Omit<FontConfig, 'size'>> = {
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
export const DEFAULT_WORKSHEET_CONFIG = {
  gridConfig: {
    ...PRESET_GRID_CONFIGS[GridType.TIAN_ZI],
    cellSize: 120
  },
  fontConfig: {
    ...PRESET_FONT_CONFIGS[FontType.KAISHU],
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
    quality: 'high' as const
  }
};
