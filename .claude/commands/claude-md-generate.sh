#!/bin/bash

# CCPM Command: Generate Intelligent CLAUDE.md
# Usage: /claude-md:generate [project_type] [output_file]
# Description: Generates a project-specific CLAUDE.md file based on detected or specified project type

set -euo pipefail

# Source core libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

if [[ -f "$LIB_DIR/core.sh" ]]; then
    source "$LIB_DIR/core.sh"
fi

if [[ -f "$LIB_DIR/ui.sh" ]]; then
    source "$LIB_DIR/ui.sh"
fi

if [[ -f "$LIB_DIR/claude-md-generator.sh" ]]; then
    source "$LIB_DIR/claude-md-generator.sh"
fi

# =============================================================================
# COMMAND HELP
# =============================================================================

show_command_help() {
    cat << 'EOF'
🤖 CLAUDE.md智能生成器

用法: /claude-md:generate [project_type] [output_file]

参数:
  project_type    强制指定项目类型 (可选，默认自动检测)
  output_file     输出文件路径 (可选，默认 .claude/CLAUDE.md)

支持的项目类型:
  前端框架: react, vue, angular, nextjs, svelte
  后端语言: python, django, flask, nodejs, golang, rust
  Java生态: maven, gradle, spring-boot
  其他类型: php, rails, docker, kubernetes, generic

功能特性:
  ✅ 智能项目类型检测
  ✅ 项目特定命令生成
  ✅ AI代理推荐配置
  ✅ 测试策略定制
  ✅ 项目结构分析
  ✅ 工作流程优化

使用示例:
  /claude-md:generate                    # 自动检测项目类型并生成
  /claude-md:generate react              # 强制按React项目生成
  /claude-md:generate python docs/CLAUDE.md  # 指定输出文件
  /claude-md:generate --preview          # 预览生成内容
  /claude-md:generate --backup           # 生成前备份现有文件

生成内容包括:
  • 项目概述和快速开始指南
  • 项目特定的开发命令
  • 推荐的AI代理配置
  • 定制化测试策略
  • 项目结构说明
  • 工作流程指导

EOF
}

# =============================================================================
# PROJECT TYPE DETECTION (Similar to bootstrap.sh)
# =============================================================================

detect_project_type() {
    local project_type="generic"
    
    # Frontend frameworks
    if [[ -f "package.json" ]]; then
        if grep -q "react" package.json 2>/dev/null; then
            project_type="react"
        elif grep -q "vue" package.json 2>/dev/null; then
            project_type="vue" 
        elif grep -q "angular" package.json 2>/dev/null; then
            project_type="angular"
        elif grep -q "next" package.json 2>/dev/null; then
            project_type="nextjs"
        elif grep -q "svelte" package.json 2>/dev/null; then
            project_type="svelte"
        else
            project_type="nodejs"
        fi
    # Python projects
    elif [[ -f "requirements.txt" ]] || [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        if [[ -f "manage.py" ]]; then
            project_type="django"
        elif [[ -d "app" ]] && [[ -f "app.py" || -f "main.py" ]]; then
            project_type="flask"
        else
            project_type="python"
        fi
    # Go projects
    elif [[ -f "go.mod" ]]; then
        project_type="golang"
    # Rust projects
    elif [[ -f "Cargo.toml" ]]; then
        project_type="rust"
    # Java projects
    elif [[ -f "pom.xml" ]]; then
        project_type="maven"
    elif [[ -f "build.gradle" ]]; then
        project_type="gradle"
    # .NET projects
    elif [[ -f "*.csproj" ]] || [[ -f "*.sln" ]]; then
        project_type="dotnet"
    # PHP projects
    elif [[ -f "composer.json" ]]; then
        project_type="php"
    # Ruby on Rails
    elif [[ -f "Gemfile" ]] && [[ -f "config/application.rb" ]]; then
        project_type="rails"
    # Docker projects
    elif [[ -f "Dockerfile" ]]; then
        project_type="docker"
    fi
    
    echo "$project_type"
}

# =============================================================================
# PREVIEW FUNCTIONALITY
# =============================================================================

preview_generation() {
    local project_type="$1"
    
    show_title "CLAUDE.md生成预览" 60
    
    echo -e "${BLUE}项目分析结果:${NC}"
    echo "  • 项目名称: $(basename "$(pwd)")"
    echo "  • 检测到的项目类型: $project_type"
    echo ""
    
    # Analyze features (using functions from generator)
    if command -v analyze_project_features >/dev/null 2>&1; then
        local features
        local testing_tools
        local build_tools
        
        features=$(analyze_project_features "$project_type")
        testing_tools=$(detect_testing_tools "$project_type")
        build_tools=$(detect_build_tools "$project_type")
        
        echo -e "${CYAN}将包含的内容:${NC}"
        echo "  ✅ 项目概述和快速启动指南"
        echo "  ✅ $project_type 特定的开发命令"
        echo "  ✅ AI代理推荐配置"
        echo "  ✅ 测试框架集成 ${testing_tools:+($testing_tools)}"
        echo "  ✅ 构建工具配置 ${build_tools:+($build_tools)}"
        echo "  ✅ 项目结构说明"
        echo "  ✅ CCPM工作流程指导"
        echo ""
        
        [[ -n "$features" ]] && echo "  🔍 检测到的功能: $features"
    fi
    
    echo ""
    echo -e "${YELLOW}注意:${NC} 这只是预览，实际生成可能包含更多内容"
}

# =============================================================================
# MAIN COMMAND LOGIC
# =============================================================================

main() {
    local project_type=""
    local output_file=".claude/CLAUDE.md"
    local preview="false"
    local backup="false"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_command_help
                exit 0
                ;;
            --preview)
                preview="true"
                shift
                ;;
            --backup)
                backup="true"
                shift
                ;;
            *)
                if [[ -z "$project_type" ]]; then
                    project_type="$1"
                elif [[ -z "$output_file" || "$output_file" == ".claude/CLAUDE.md" ]]; then
                    output_file="$1"
                else
                    log_error "Unexpected argument: $1"
                    show_command_help
                    exit 1
                fi
                shift
                ;;
        esac
    done
    
    # Auto-detect project type if not specified
    if [[ -z "$project_type" ]]; then
        project_type=$(detect_project_type)
        log_info "Auto-detected project type: $project_type"
    else
        log_info "Using specified project type: $project_type"
    fi
    
    # Handle preview mode
    if [[ "$preview" == "true" ]]; then
        preview_generation "$project_type"
        return 0
    fi
    
    # Check if generator is available
    if ! command -v generate_claude_md >/dev/null 2>&1; then
        log_error "CLAUDE.md generator not available"
        echo "请确保 .claude/lib/claude-md-generator.sh 文件存在"
        exit 1
    fi
    
    # Create backup if requested
    if [[ "$backup" == "true" && -f "$output_file" ]]; then
        local backup_file="${output_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$output_file" "$backup_file"
        log_info "Backup created: $backup_file"
    fi
    
    # Generate the file
    show_info "正在生成项目特定的CLAUDE.md文件..."
    
    if generate_claude_md "$project_type" "$output_file"; then
        log_success "CLAUDE.md文件生成成功: $output_file"
        
        # Show what's next
        echo ""
        show_next_steps "
查看生成的文件: cat $output_file
验证框架配置: /validate --quick
初始化项目管理: /pm:init
配置测试环境: /testing:prime"
        
    else
        log_error "CLAUDE.md文件生成失败"
        exit 1
    fi
}

# =============================================================================
# ENTRY POINT
# =============================================================================

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi