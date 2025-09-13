// components/calligraphy-preview/calligraphy-preview.ts

Component({
  properties: {
    // 要预览的文字内容
    text: {
      type: String,
      value: '',
      observer: function(this: any, newVal: string) {
        if (newVal) {
          this.updateGridData(newVal);
        }
      }
    },
    
    // 网格尺寸
    cellSize: {
      type: Number,
      value: 120
    },
    
    // 是否显示字体选择器
    showFontSelector: {
      type: Boolean,
      value: true
    },
    
    // 初始字体
    defaultFont: {
      type: String,
      value: 'kaishu'
    }
  },

  data: {
    fontOptions: [
      { id: 'kaishu', name: '楷书', family: 'KaiTi, serif' },
      { id: 'xingshu', name: '行书', family: 'STXingkai, cursive' },
      { id: 'lishu', name: '隶书', family: 'STLiSu, serif' },
      { id: 'caoshu', name: '草书', family: 'STCaoshu, cursive' }
    ],
    selectedFont: 'kaishu',
    selectedFontFamily: 'KaiTi, serif',
    showFontSelector: true,
    
    gridData: [] as string[],
    cellSize: 120,
    showGrid: true,
    loading: false
  },

  lifetimes: {
    attached(this: any) {
      // 初始化组件
      this.setData({
        selectedFont: this.properties.defaultFont,
        cellSize: this.properties.cellSize,
        showFontSelector: this.properties.showFontSelector
      });
      
      // 设置默认字体样式
      const defaultFont = this.data.fontOptions.find((font: any) => font.id === this.properties.defaultFont);
      if (defaultFont) {
        this.setData({
          selectedFontFamily: defaultFont.family
        });
      }
      
      // 如果有初始文字，生成预览
      if (this.properties.text) {
        this.updateGridData(this.properties.text);
      }
    },

    ready() {
      console.log('字帖预览组件已准备完成');
    }
  },

  methods: {
    /**
     * 切换字体
     */
    onFontChange(this: any, event: WechatMiniprogram.TouchEvent) {
      const fontId = event.currentTarget.dataset.font as string;
      const selectedFont = this.data.fontOptions.find((font: any) => font.id === fontId);
      
      if (selectedFont) {
        this.setData({
          selectedFont: fontId,
          selectedFontFamily: selectedFont.family,
          loading: true
        });
        
        // 模拟字体切换加载
        setTimeout(() => {
          this.setData({ loading: false });
          
          // 触发字体变更事件
          this.triggerEvent('fontchange', {
            fontId: fontId,
            fontName: selectedFont.name,
            fontFamily: selectedFont.family
          });
        }, 500);
      }
    },

    /**
     * 切换网格显示
     */
    toggleGrid(this: any) {
      const newShowGrid = !this.data.showGrid;
      this.setData({
        showGrid: newShowGrid
      });
      
      // 触发网格切换事件
      this.triggerEvent('gridtoggle', {
        showGrid: newShowGrid
      });
    },

    /**
     * 导出字帖
     */
    onExport(this: any) {
      // 触发导出事件，让父组件处理具体的导出逻辑
      this.triggerEvent('export', {
        text: this.properties.text,
        font: this.data.selectedFont,
        showGrid: this.data.showGrid,
        cellSize: this.data.cellSize
      });
    },

    /**
     * 更新网格数据
     */
    updateGridData(this: any, text: string) {
      if (!text) {
        this.setData({ gridData: [] });
        return;
      }
      
      // 将文字转换为数组，每个字符一个网格
      const characters = Array.from(text).slice(0, 48); // 最多显示48个字符
      
      this.setData({
        gridData: characters,
        loading: false
      });
      
      // 触发预览更新事件
      this.triggerEvent('previewupdate', {
        text: text,
        characterCount: characters.length
      });
    },

    /**
     * 生成预览（提供给外部调用）
     */
    generatePreview(this: any) {
      if (this.properties.text) {
        this.setData({ loading: true });
        
        setTimeout(() => {
          this.updateGridData(this.properties.text);
        }, 300);
      }
    }
  }
});
