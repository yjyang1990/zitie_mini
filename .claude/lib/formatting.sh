#!/bin/bash
# CCPM 格式化和显示函数库
# 提供通用的输出格式化、进度条显示等功能

# 颜色常量（重用，确保一致性）
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly PURPLE='\033[0;35m'
readonly NC='\033[0m' # No Color

# 状态输出标准头部
show_status_header() {
    echo "Getting status..."
    echo ""
    echo ""
}

# 通用进度条显示
show_progress_bar() {
    local completed="${1:-0}"
    local total="${2:-0}"
    local width="${3:-20}"
    local label="${4:-Progress}"
    
    if [[ $total -gt 0 ]]; then
        local percent=$((completed * 100 / total))
        local filled=$((percent * width / 100))
        local empty=$((width - filled))
        
        echo -n -e "${label}: [${GREEN}"
        [[ $filled -gt 0 ]] && printf '%0.s█' $(seq 1 $filled)
        echo -n -e "${NC}${CYAN}"
        [[ $empty -gt 0 ]] && printf '%0.s░' $(seq 1 $empty)
        echo -e "${NC}] ${percent}% (${completed}/${total})"
    else
        echo -e "${label}: ${YELLOW}No items found${NC}"
    fi
}

# 状态图标显示
show_status_icon() {
    local status="$1"
    case "$status" in
        "open"|"pending"|"todo")
            echo -n "📋"
            ;;
        "in_progress"|"working"|"active")
            echo -n "🔄"
            ;;
        "completed"|"done"|"closed")
            echo -n "✅"
            ;;
        "blocked"|"error")
            echo -n "❌"
            ;;
        "review"|"testing")
            echo -n "👀"
            ;;
        *)
            echo -n "📄"
            ;;
    esac
}

# 格式化状态文本
format_status_text() {
    local status="$1"
    case "$status" in
        "open"|"pending"|"todo")
            echo -e "${YELLOW}$status${NC}"
            ;;
        "in_progress"|"working"|"active")
            echo -e "${BLUE}$status${NC}"
            ;;
        "completed"|"done"|"closed")
            echo -e "${GREEN}$status${NC}"
            ;;
        "blocked"|"error")
            echo -e "${RED}$status${NC}"
            ;;
        "review"|"testing")
            echo -e "${PURPLE}$status${NC}"
            ;;
        *)
            echo -e "${NC}$status${NC}"
            ;;
    esac
}

# 显示表格头部
show_table_header() {
    local -a headers=("$@")
    local separator=""
    
    # 计算分隔符长度
    for header in "${headers[@]}"; do
        printf "%-20s" "$header"
        separator+="--------------------"
    done
    echo ""
    echo "$separator"
}

# 显示表格行
show_table_row() {
    local -a columns=("$@")
    for column in "${columns[@]}"; do
        printf "%-20s" "$column"
    done
    echo ""
}

# 显示分隔线
show_separator() {
    local width="${1:-50}"
    local char="${2:-=}"
    printf '%0.s'"$char" $(seq 1 "$width")
    echo ""
}

# 显示标题
show_title() {
    local title="$1"
    local width="${2:-50}"
    
    show_separator "$width" "="
    echo -e "${BLUE}${title}${NC}"
    show_separator "$width" "="
}

# 显示子标题
show_subtitle() {
    local subtitle="$1"
    local width="${2:-30}"
    
    echo ""
    echo -e "${CYAN}${subtitle}${NC}"
    show_separator "$width" "-"
}

# 显示成功消息
# show_success, show_error, show_warning functions moved to ux.sh to avoid duplication

# 显示信息消息
show_info() {
    local message="$1"
    echo -e "ℹ️  ${BLUE}${message}${NC}"
}

# 显示任务列表
show_task_list() {
    local epic_dir="$1"
    local show_completed="${2:-false}"
    
    if [[ ! -d "$epic_dir" ]]; then
        show_error "Epic directory not found: $epic_dir"
        return 1
    fi
    
    local task_count=0
    local completed_count=0
    
    while IFS= read -r -d '' task_file; do
        if [[ -f "$task_file" ]]; then
            local task_name
            task_name=$(basename "$(dirname "$task_file")")
            
            # 检查任务状态
            local status="open"
            if grep -q "Status: closed" "$task_file" 2>/dev/null; then
                status="closed"
                ((completed_count++))
            elif grep -q "Status: in_progress" "$task_file" 2>/dev/null; then
                status="in_progress"
            fi
            
            # 显示任务（根据参数决定是否显示已完成任务）
            if [[ "$show_completed" == "true" ]] || [[ "$status" != "closed" ]]; then
                printf "  %s %s\n" "$(show_status_icon "$status")" "$task_name"
            fi
            
            ((task_count++))
        fi
    done < <(find "$epic_dir" -name "task.md" -print0 2>/dev/null)
    
    echo ""
    show_progress_bar "$completed_count" "$task_count" 20 "Overall Progress"
}

# 显示 epic 摘要
show_epic_summary() {
    local epic_file="$1"
    
    if [[ ! -f "$epic_file" ]]; then
        show_error "Epic file not found: $epic_file"
        return 1
    fi
    
    # 提取基本信息
    local title
    title=$(grep "^# " "$epic_file" | head -1 | sed 's/^# //' | xargs)
    
    local description
    description=$(sed -n '/^## Description/,/^## /p' "$epic_file" | grep -v "^##" | head -3 | xargs)
    
    echo -e "${BLUE}Title:${NC} $title"
    echo -e "${BLUE}Description:${NC} $description"
}

# 显示帮助提示
show_help_hint() {
    local command="$1"
    echo ""
    echo -e "💡 ${YELLOW}Need help?${NC} Run: ${BLUE}$command --help${NC}"
}

# Export all functions
export -f show_status_header
export -f show_progress_bar
export -f show_status_icon
export -f format_status_text
export -f show_table_header
export -f show_table_row
export -f show_separator
export -f show_title
export -f show_subtitle
# show_success, show_error, show_warning exported from ux.sh
export -f show_info
export -f show_task_list
export -f show_epic_summary
export -f show_help_hint