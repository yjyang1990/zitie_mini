// Simple Icon Component - Text-based fallback for TDesign icons
Component({
  properties: {
    name: {
      type: String,
      value: ''
    },
    size: {
      type: String,
      value: '32rpx'
    },
    color: {
      type: String,
      value: '#000'
    }
  },

  data: {
    iconText: ''
  },

  lifetimes: {
    attached() {
      this.updateIconText();
    }
  },

  observers: {
    'name': function(newName) {
      this.updateIconText();
    }
  },

  methods: {
    updateIconText() {
      const iconMap = {
        'add': '➕',
        'close': '✖️',
        'close-circle-filled': '⊗',
        'edit': '✏️',
        'check-circle': '✅',
        'check-circle-filled': '✅',
        'search': '🔍',
        'filter': '🔽',
        'sort': '⇕️',
        'view-module': '⊞',
        'format-list-bulleted': '☰',
        'star-filled': '⭐',
        'layers': '📚',
        'thumb-up': '👍',
        'palette': '🎨',
        'time': '⏰',
        'user': '👤',
        'chevron-right': '▷',
        'chevron-right-double': '⏭️'
      };

      const iconText = iconMap[this.data.name] || '●';
      this.setData({ iconText });
    }
  }
});