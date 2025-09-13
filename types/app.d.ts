// WeChat Mini Program App Interface
interface IAppOption {
  globalData: {
    userInfo?: WechatMiniprogram.UserInfo,
    hasLogin: boolean,
    theme: 'light' | 'dark'
  }
  userInfoReadyCallback?: WechatMiniprogram.GetUserInfoSuccessCallback,
}

// Page Interface
interface IPageData {
  [key: string]: any
}

interface IPageMethods {
  [key: string]: (...args: any[]) => any
}

// Component Interface
interface IComponentData {
  [key: string]: any
}

interface IComponentMethods {
  [key: string]: (...args: any[]) => any
}

interface IComponentProperties {
  [key: string]: any
}

// Global App Instance
declare const app: WechatMiniprogram.App.Instance<IAppOption>

// TDesign Component Types
declare namespace TDesign {
  interface ButtonProps {
    type?: 'primary' | 'secondary' | 'success' | 'warning' | 'danger'
    size?: 'large' | 'medium' | 'small' | 'mini'
    disabled?: boolean
    loading?: boolean
    block?: boolean
    ghost?: boolean
    shape?: 'rectangle' | 'round' | 'circle'
  }
  
  interface InputProps {
    value?: string
    placeholder?: string
    disabled?: boolean
    readonly?: boolean
    clearable?: boolean
    type?: 'text' | 'number' | 'password' | 'textarea'
    maxlength?: number
    showWordLimit?: boolean
  }
  
  interface DialogOptions {
    title?: string
    content?: string
    confirmBtn?: string
    cancelBtn?: string
    showCancel?: boolean
  }
}
