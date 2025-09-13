#!/bin/bash

# CLAUDE.md Generator - Intelligent project-specific documentation generator
# Generates customized CLAUDE.md files based on project type and structure

set -euo pipefail

# Source core library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/core.sh" ]]; then
    source "$SCRIPT_DIR/core.sh"
fi

# =============================================================================
# PROJECT ANALYSIS
# =============================================================================

analyze_project_features() {
    local project_type="$1"
    local features=()
    
    # Common features based on files
    [[ -f "package.json" ]] && features+=("npm")
    [[ -f "Dockerfile" ]] && features+=("docker")
    [[ -f "docker-compose.yml" ]] && features+=("docker-compose")
    [[ -f ".github/workflows" ]] && features+=("github-actions")
    [[ -d "tests" || -d "test" ]] && features+=("testing")
    [[ -f "README.md" ]] && features+=("documentation")
    [[ -d ".git" ]] && features+=("git")
    [[ -f "Makefile" ]] && features+=("makefile")
    
    # Project-specific features
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs")
            [[ -f "public/index.html" ]] && features+=("spa")
            [[ -d "src/components" ]] && features+=("components")
            [[ -f "tailwind.config.js" ]] && features+=("tailwind")
            [[ -f "vite.config.js" ]] && features+=("vite")
            [[ -f "webpack.config.js" ]] && features+=("webpack")
            ;;
        "python"|"django"|"flask")
            [[ -f "requirements.txt" ]] && features+=("pip")
            [[ -f "Pipfile" ]] && features+=("pipenv")
            [[ -f "pyproject.toml" ]] && features+=("poetry")
            [[ -f "setup.py" ]] && features+=("setuptools")
            [[ -d "migrations" ]] && features+=("database-migrations")
            ;;
        "golang")
            [[ -f "go.mod" ]] && features+=("go-modules")
            [[ -f "go.sum" ]] && features+=("go-dependencies")
            ;;
        "rust")
            [[ -f "Cargo.toml" ]] && features+=("cargo")
            [[ -f "Cargo.lock" ]] && features+=("cargo-lock")
            ;;
    esac
    
    # Join array elements with commas
    local IFS=','
    echo "${features[*]}"
}

detect_testing_tools() {
    local project_type="$1"
    local tools=()
    
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs"|"nodejs")
            grep -q "jest" package.json 2>/dev/null && tools+=("jest")
            grep -q "vitest" package.json 2>/dev/null && tools+=("vitest")
            grep -q "cypress" package.json 2>/dev/null && tools+=("cypress")
            grep -q "playwright" package.json 2>/dev/null && tools+=("playwright")
            grep -q "mocha" package.json 2>/dev/null && tools+=("mocha")
            grep -q "chai" package.json 2>/dev/null && tools+=("chai")
            ;;
        "python"|"django"|"flask")
            [[ -f "pytest.ini" || -f "pyproject.toml" ]] && tools+=("pytest")
            [[ -f "tox.ini" ]] && tools+=("tox")
            grep -q "unittest" **/*.py 2>/dev/null && tools+=("unittest")
            ;;
        "golang")
            tools+=("go-test")
            ;;
        "rust")
            tools+=("cargo-test")
            ;;
    esac
    
    local IFS=','
    echo "${tools[*]}"
}

detect_build_tools() {
    local project_type="$1"
    local tools=()
    
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs"|"nodejs")
            [[ -f "vite.config.js" ]] && tools+=("vite")
            [[ -f "webpack.config.js" ]] && tools+=("webpack")
            [[ -f "rollup.config.js" ]] && tools+=("rollup")
            [[ -f "esbuild.config.js" ]] && tools+=("esbuild")
            ;;
        "python")
            [[ -f "setup.py" ]] && tools+=("setuptools")
            [[ -f "pyproject.toml" ]] && tools+=("poetry")
            ;;
        "golang")
            tools+=("go-build")
            ;;
        "rust")
            tools+=("cargo")
            ;;
        "maven")
            tools+=("maven")
            ;;
        "gradle")
            tools+=("gradle")
            ;;
    esac
    
    local IFS=','
    echo "${tools[*]}"
}

get_project_name() {
    basename "$(pwd)"
}

get_project_description() {
    local project_type="$1"
    local project_name="$(get_project_name)"
    
    # Try to extract description from package.json or other files
    if [[ -f "package.json" ]] && command -v jq >/dev/null 2>&1; then
        local desc
        desc=$(jq -r '.description // empty' package.json 2>/dev/null)
        if [[ -n "$desc" && "$desc" != "null" ]]; then
            echo "$desc"
            return
        fi
    fi
    
    # Try to extract from README.md
    if [[ -f "README.md" ]]; then
        local desc
        desc=$(head -10 README.md | grep -E "^[A-Z].*" | head -1 | sed 's/^#* *//')
        if [[ -n "$desc" ]]; then
            echo "$desc"
            return
        fi
    fi
    
    # Generate generic description based on project type
    case "$project_type" in
        "react") echo "A React application for modern web development" ;;
        "vue") echo "A Vue.js application for interactive web interfaces" ;;
        "angular") echo "An Angular application for enterprise web development" ;;
        "nextjs") echo "A Next.js application for full-stack React development" ;;
        "nodejs") echo "A Node.js application for server-side JavaScript" ;;
        "python") echo "A Python application for scalable backend development" ;;
        "django") echo "A Django web application for rapid development" ;;
        "flask") echo "A Flask web application for lightweight development" ;;
        "golang") echo "A Go application for high-performance backend services" ;;
        "rust") echo "A Rust application for system-level programming" ;;
        "maven"|"gradle") echo "A Java application for enterprise development" ;;
        *) echo "A $project_type project for software development" ;;
    esac
}

# =============================================================================
# CLAUDE.MD TEMPLATE GENERATION
# =============================================================================

generate_header() {
    local project_name="$1"
    local project_type="$2"
    local project_description="$3"
    
    cat << EOF
# $project_name

🚀 **$project_description** - 基于CCPM框架的智能AI辅助开发项目

> **项目类型**: $project_type | **生成时间**: $(get_timestamp) | **CCPM版本**: 2.0

## 🎯 项目概述

这是一个使用 **$project_type** 技术栈开发的项目，集成了CCPM (Claude Code Project Manager) 框架，为您提供：

- ✅ **智能AI代理支持** - 15个专业AI代理协助开发
- ✅ **自定义命令集** - 24个项目管理和开发工具命令  
- ✅ **最佳实践集成** - 基于Claude Code官方最佳实践
- ✅ **跨平台兼容** - 支持macOS, Linux, Windows/WSL
- ✅ **自动化工作流** - 测试、构建、部署自动化

EOF
}

generate_quick_start() {
    local project_type="$1"
    local features="$2"
    
    cat << EOF
## 🚀 Quick Start

### 开发环境启动
\`\`\`bash
EOF

    # Generate project-specific setup commands
    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs"|"nodejs")
            cat << 'EOF'
npm install                        # 安装依赖
npm run dev                        # 启动开发服务器
EOF
            ;;
        "python"|"django"|"flask")
            cat << 'EOF'
python -m venv venv                # 创建虚拟环境
source venv/bin/activate           # 激活虚拟环境
pip install -r requirements.txt    # 安装依赖
EOF
            if [[ "$project_type" == "django" ]]; then
                echo "python manage.py runserver         # 启动Django服务器"
            elif [[ "$project_type" == "flask" ]]; then
                echo "flask run                          # 启动Flask服务器"
            else
                echo "python main.py                     # 运行Python应用"
            fi
            ;;
        "golang")
            cat << 'EOF'
go mod tidy                        # 整理依赖
go run .                           # 运行应用
EOF
            ;;
        "rust")
            cat << 'EOF'
cargo build                        # 构建项目
cargo run                          # 运行应用
EOF
            ;;
        "maven")
            cat << 'EOF'
mvn clean install                  # 清理并构建
mvn spring-boot:run               # 运行Spring Boot应用
EOF
            ;;
        "gradle")
            cat << 'EOF'
./gradlew build                    # 构建项目
./gradlew bootRun                  # 运行Spring Boot应用
EOF
            ;;
        *)
            cat << 'EOF'
# 请根据您的项目类型添加启动命令
make install                       # 安装依赖
make run                          # 运行应用
EOF
            ;;
    esac

    cat << EOF
\`\`\`

### CCPM框架使用
\`\`\`bash
/validate --quick                  # 验证框架完整性
/pm:init                          # 初始化项目管理
/testing:prime                     # 配置测试环境
/context create                    # 生成项目上下文
\`\`\`

EOF
}

generate_bash_commands() {
    local project_type="$1"
    local testing_tools="$2"
    local build_tools="$3"
    
    cat << EOF
## 开发命令速查

### 项目构建与运行
\`\`\`bash
EOF

    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs"|"nodejs")
            cat << 'EOF'
# 开发环境
npm run dev                        # 启动开发服务器
npm run build                      # 构建生产版本
npm run preview                    # 预览构建结果
npm run lint                       # 代码检查
npm run format                     # 代码格式化

# 测试
npm test                           # 运行测试
npm run test:watch                 # 监视模式测试
npm run test:coverage              # 覆盖率测试
EOF
            if [[ "$testing_tools" == *"cypress"* ]]; then
                echo "npx cypress open                   # 打开Cypress测试"
            fi
            if [[ "$testing_tools" == *"playwright"* ]]; then
                echo "npx playwright test                # 运行Playwright测试"
            fi
            ;;
        "python"|"django"|"flask")
            cat << 'EOF'
# Python开发
python -m venv venv                # 创建虚拟环境
source venv/bin/activate           # 激活虚拟环境 (Unix)
# venv\Scripts\activate            # 激活虚拟环境 (Windows)
pip install -r requirements.txt    # 安装依赖
pip freeze > requirements.txt      # 更新依赖列表

# 代码质量
ruff check .                       # 代码检查
ruff format .                      # 代码格式化
mypy .                            # 类型检查

# 测试
python -m pytest                  # 运行测试
python -m pytest --cov           # 覆盖率测试
python -m pytest -v              # 详细测试输出
EOF
            if [[ "$project_type" == "django" ]]; then
                cat << 'EOF'

# Django特定
python manage.py makemigrations    # 创建数据库迁移
python manage.py migrate           # 执行数据库迁移
python manage.py runserver         # 启动开发服务器
python manage.py shell             # Django Shell
python manage.py collectstatic     # 收集静态文件
EOF
            fi
            ;;
        "golang")
            cat << 'EOF'
# Go开发
go mod tidy                        # 整理依赖
go build                           # 构建项目
go run .                           # 运行应用
go install                         # 安装到GOPATH

# 代码质量
go fmt ./...                       # 格式化代码
go vet ./...                       # 静态分析
golangci-lint run                  # 综合检查

# 测试
go test ./...                      # 运行所有测试
go test -v ./...                   # 详细测试输出
go test -cover ./...               # 覆盖率测试
go test -bench=.                   # 基准测试
EOF
            ;;
        "rust")
            cat << 'EOF'
# Rust开发
cargo build                        # 构建项目
cargo run                          # 运行应用
cargo build --release             # 发布构建
cargo install --path .             # 安装到系统

# 代码质量
cargo fmt                          # 格式化代码
cargo clippy                       # 代码检查
cargo check                        # 快速检查

# 测试
cargo test                         # 运行测试
cargo test --release              # 发布模式测试
cargo doc --open                   # 生成并打开文档
cargo bench                        # 基准测试
EOF
            ;;
        "maven")
            cat << 'EOF'
# Maven Java开发
mvn clean                          # 清理构建
mvn compile                        # 编译源码
mvn test                           # 运行测试
mvn package                        # 打包应用
mvn install                        # 安装到本地仓库
mvn spring-boot:run               # 运行Spring Boot应用

# 依赖管理
mvn dependency:tree               # 显示依赖树
mvn dependency:resolve            # 解析依赖
mvn versions:display-dependency-updates  # 检查依赖更新
EOF
            ;;
        "gradle")
            cat << 'EOF'
# Gradle开发
./gradlew build                    # 构建项目
./gradlew test                     # 运行测试
./gradlew run                      # 运行应用
./gradlew clean                    # 清理构建
./gradlew bootRun                  # 运行Spring Boot应用

# 依赖管理
./gradlew dependencies             # 显示依赖
./gradlew dependencyUpdates        # 检查依赖更新
EOF
            ;;
    esac

    cat << 'EOF'
```

### CCPM框架命令
```bash
# 框架管理
bash .claude/bootstrap.sh          # 重新初始化框架
/validate --full                   # 完整验证
/context refresh                   # 刷新项目上下文

# 项目管理
/pm:prd-parse <name>               # 解析PRD文档
/pm:epic <epic_name>               # 创建Epic
/pm:issue <title>                  # 创建GitHub Issue

# 测试管理
/testing:run                       # 运行所有测试
/testing:coverage                  # 生成覆盖率报告
/testing:e2e                       # 运行E2E测试

# 开发工具
shellcheck *.sh                    # Shell脚本检查
tree .claude                       # 显示框架结构
```

EOF
}

generate_ai_agents_section() {
    local project_type="$1"
    
    cat << EOF
## 🤖 AI代理推荐

根据您的项目类型 ($project_type)，推荐使用以下AI代理：

### 核心代理
EOF

    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs")
            cat << 'EOF'
- **system-architect** - 系统架构设计，组件结构规划
- **frontend-engineer** - UI组件开发，状态管理，性能优化
- **ui-expert** - 用户界面设计，交互体验优化
- **test-runner** - 单元测试，集成测试，E2E测试

### 使用场景
```bash
/agent:architect           # 架构设计和技术选型
/agent:frontend           # 组件开发和前端优化  
/agent:ui                 # 界面设计和用户体验
/agent:testing            # 测试策略和执行
```
EOF
            ;;
        "nodejs"|"python"|"django"|"flask"|"golang"|"rust")
            cat << 'EOF'
- **system-architect** - 系统架构设计，技术选型
- **backend-engineer** - API开发，数据库设计，服务架构
- **test-engineer** - 测试策略，自动化测试
- **devops-engineer** - 部署配置，CI/CD，监控

### 使用场景
```bash
/agent:architect           # 架构设计和技术选型
/agent:backend            # 后端开发和API设计
/agent:testing            # 测试策略和执行
/agent:devops             # 部署和运维
```
EOF
            ;;
        *)
            cat << 'EOF'
- **system-architect** - 系统架构设计，技术选型
- **code-analyzer** - 代码分析，逻辑跟踪，Bug排查
- **test-runner** - 测试执行，故障分析

### 使用场景
```bash
/agent:architect           # 架构设计和技术选型
/agent:analyzer           # 代码分析和问题诊断
/agent:testing            # 测试策略和执行
```
EOF
            ;;
    esac

    cat << 'EOF'

### 协调代理
- **workflow-orchestrator** - 多任务协调，并行开发管理
- **github-specialist** - Issue管理，PR工作流，代码审查
- **pm-specialist** - 项目管理，需求分析，进度跟踪

EOF
}

generate_testing_section() {
    local project_type="$1"
    local testing_tools="$2"
    
    cat << EOF
## 🧪 测试策略

### 测试框架配置
EOF

    if [[ -n "$testing_tools" ]]; then
        cat << EOF
当前项目检测到的测试工具：**$testing_tools**

EOF
    fi

    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs"|"nodejs")
            cat << 'EOF'
```bash
# 单元测试
npm test                           # 运行Jest/Vitest测试
npm run test:watch                 # 监视模式
npm run test:coverage              # 覆盖率报告

# 集成测试
npm run test:integration           # 集成测试

# E2E测试
npx cypress open                   # Cypress可视化测试
npx playwright test                # Playwright测试
```

### 测试最佳实践
- ✅ **组件测试** - 独立测试每个组件
- ✅ **用户交互测试** - 模拟真实用户操作
- ✅ **API集成测试** - 测试前后端集成
- ✅ **性能测试** - 检查渲染性能和内存使用
EOF
            ;;
        "python"|"django"|"flask")
            cat << 'EOF'
```bash
# 单元测试
python -m pytest                  # 运行pytest测试
python -m pytest -v              # 详细输出
python -m pytest --cov           # 覆盖率测试
python -m pytest --cov-report=html  # HTML覆盖率报告

# 特定测试
python -m pytest tests/unit/      # 单元测试
python -m pytest tests/integration/  # 集成测试
python -m pytest -k "test_name"   # 运行特定测试
```

### 测试最佳实践
- ✅ **单元测试** - 测试函数和类的独立功能
- ✅ **API测试** - 测试REST API端点
- ✅ **数据库测试** - 测试数据模型和查询
- ✅ **集成测试** - 测试组件之间的交互
EOF
            ;;
        "golang")
            cat << 'EOF'
```bash
# Go测试
go test ./...                      # 运行所有测试
go test -v ./...                   # 详细输出
go test -cover ./...               # 覆盖率测试
go test -bench=.                   # 基准测试
go test -race ./...                # 竞态检测
```

### 测试最佳实践
- ✅ **Table-driven测试** - 使用测试数据表
- ✅ **基准测试** - 性能测试和优化
- ✅ **竞态检测** - 并发安全测试
- ✅ **集成测试** - 测试组件交互
EOF
            ;;
        "rust")
            cat << 'EOF'
```bash
# Rust测试
cargo test                         # 运行测试
cargo test --release             # 发布模式测试
cargo test -- --nocapture        # 显示打印输出
cargo bench                        # 基准测试
```

### 测试最佳实践
- ✅ **单元测试** - 测试函数和模块
- ✅ **集成测试** - 测试crate间交互
- ✅ **文档测试** - 测试文档中的代码示例
- ✅ **基准测试** - 性能测试和优化
EOF
            ;;
        *)
            cat << 'EOF'
```bash
# 通用测试命令
# 请根据您的项目配置具体的测试命令
make test                          # 运行测试
make test-coverage                 # 覆盖率测试
```

### 测试最佳实践
- ✅ **单元测试** - 测试独立功能模块
- ✅ **集成测试** - 测试组件间交互
- ✅ **系统测试** - 端到端功能测试
- ✅ **性能测试** - 验证性能指标
EOF
            ;;
    esac

    cat << 'EOF'

### CCPM测试工具
```bash
/testing:prime                     # 初始化测试环境
/testing:run                       # 执行所有测试
/testing:coverage                  # 生成覆盖率报告
/testing:analyze                   # 测试结果分析
```

EOF
}

generate_project_structure() {
    local project_type="$1"
    
    cat << EOF
## 📁 项目结构

\`\`\`
EOF

    # Generate project-specific structure
    echo "$(get_project_name)/"
    echo "├── .claude/                   # CCPM框架核心"
    echo "│   ├── agents/               # AI代理配置"
    echo "│   ├── commands/             # 自定义命令"
    echo "│   ├── config/               # 项目配置"
    echo "│   └── scripts/              # 自动化脚本"

    case "$project_type" in
        "react"|"vue"|"angular"|"nextjs")
            cat << 'EOF'
├── src/                           # 源代码目录
│   ├── components/               # 组件目录
│   ├── pages/                    # 页面目录
│   ├── hooks/                    # 自定义Hook
│   ├── utils/                    # 工具函数
│   └── assets/                   # 静态资源
├── public/                       # 公共资源
├── tests/                        # 测试文件
├── package.json                  # 项目配置
└── README.md                     # 项目说明
EOF
            ;;
        "python"|"django"|"flask")
            if [[ "$project_type" == "django" ]]; then
                cat << 'EOF'
├── apps/                         # Django应用
├── config/                       # 配置文件
├── static/                       # 静态文件
├── templates/                    # 模板文件
├── tests/                        # 测试文件
├── manage.py                     # Django管理脚本
├── requirements.txt              # Python依赖
└── README.md                     # 项目说明
EOF
            else
                cat << 'EOF'
├── src/                          # 源代码目录
├── tests/                        # 测试文件
├── docs/                         # 文档
├── requirements.txt              # Python依赖
├── setup.py                      # 安装配置
└── README.md                     # 项目说明
EOF
            fi
            ;;
        "golang")
            cat << 'EOF'
├── cmd/                          # 可执行文件
├── internal/                     # 内部包
├── pkg/                          # 公共包
├── api/                          # API定义
├── web/                          # Web资源
├── configs/                      # 配置文件
├── docs/                         # 文档
├── test/                         # 测试文件
├── go.mod                        # Go模块
└── README.md                     # 项目说明
EOF
            ;;
        "rust")
            cat << 'EOF'
├── src/                          # 源代码目录
│   ├── lib.rs                   # 库入口
│   └── main.rs                  # 可执行入口
├── tests/                        # 集成测试
├── benches/                      # 基准测试
├── examples/                     # 示例代码
├── docs/                         # 文档
├── Cargo.toml                    # 项目配置
└── README.md                     # 项目说明
EOF
            ;;
        *)
            cat << 'EOF'
├── src/                          # 源代码目录
├── tests/                        # 测试文件
├── docs/                         # 文档
├── config/                       # 配置文件
└── README.md                     # 项目说明
EOF
            ;;
    esac

    cat << 'EOF'
```

### 关键文件说明
- **.claude/CLAUDE.md** - 本项目指令文档（当前文件）
- **.claude/settings.local.json** - 工具权限和本地设置
- **.mcp.json** - MCP服务器配置
- **.claude/config/project.json** - 项目特定配置

EOF
}

generate_workflow_section() {
    local project_type="$1"
    
    cat << 'EOF'
## 🔄 开发工作流 (EPCC)

### 1. **Explore** - 探索理解
- **简单任务**: 直接读取特定文件路径
- **复杂分析**: 使用 `code-analyzer` 代理进行多文件逻辑跟踪
- **大文件分析**: 使用 `file-analyzer` 代理进行日志分析和摘要

### 2. **Plan** - 规划设计
- 使用 **"think"** 关键字触发扩展思考模式
- 思考级别: "think" < "think hard" < "think harder" < "ultrathink"
- 复杂架构: 使用 `system-architect` 代理
- 重大变更: 创建GitHub Issue保存上下文

### 3. **Code** - 编码实现
- **简单编辑**: 直接使用文件操作工具 (Edit, Write)
- **复杂功能**: 使用专业代理
- **真实测试**: 针对实际服务测试，避免mock

### 4. **Commit** - 提交管理
- 自动生成commit消息，包含diff和历史上下文
- 使用 `github-specialist` 代理创建PR和管理

## 🎯 最佳实践

### 使用代理的时机
**直接交互** (简单任务优选):
- 单文件编辑
- 运行测试或构建
- 基础git操作
- 读取特定文件
- 简单调试

**使用代理** (复杂任务需要专业知识):
- 多文件代码分析和逻辑跟踪
- 大型日志分析和关键信息提取
- 全面测试执行和故障分析
- 架构设计和技术选型
- 组件架构和状态管理

### 测试策略
```bash
# 测试优先开发 (TDD)
# 测试必须能发现真实缺陷，而非盲目通过
# 使用真实服务，避免mock
# 测试代理提供全面的故障分析
```

### 上下文管理
- 主要任务间使用 `/clear` 保持专注
- 让Claude读取相关文件而非描述它们
- 直接提供图片、截图和URL
- 具体的指令减少迭代次数

EOF
}

generate_custom_commands() {
    cat << 'EOF'
## 🛠️ 自定义命令

### 项目管理命令
```bash
/pm:init                          # 初始化项目管理工作流
/pm:prd-new <feature-name>        # 创建新的功能需求文档
/pm:prd-parse <name>              # 解析PRD文档生成Epic
/pm:epic <epic_name>              # 创建或查看Epic
/pm:issue <title>                 # 创建GitHub Issue
/pm:status                        # 查看项目状态
```

### 测试管理命令
```bash
/testing:prime                    # 初始化测试环境
/testing:run                      # 运行所有测试
/testing:coverage                 # 生成覆盖率报告
/testing:e2e                      # 运行E2E测试
/testing:analyze                  # 测试结果分析
```

### 核心工具命令
```bash
/validate --quick                 # 快速验证框架
/validate --full                  # 完整验证
/context create                   # 创建项目上下文
/context refresh                  # 刷新上下文
/help agents                      # 查看可用代理
```

EOF
}

generate_footer() {
    local project_type="$1"
    
    cat << EOF
## 🚀 开始使用

### 初始化检查
\`\`\`bash
/validate --quick                  # 验证CCPM框架
/pm:init                          # 初始化项目管理
/testing:prime                     # 配置测试环境
\`\`\`

### 推荐工作流
1. **了解项目**: 使用 \`/context create\` 生成项目概览
2. **创建需求**: 使用 \`/pm:prd-new <feature-name>\` 创建功能需求文档
3. **规划功能**: 使用 \`/pm:prd-parse <name>\` 解析需求文档为Epic
4. **开发功能**: 根据项目类型选择合适的AI代理
5. **测试验证**: 使用 \`/testing:run\` 执行测试
6. **提交代码**: 自动生成commit消息并创建PR

### 技术支持
- **框架文档**: [CCPM官方文档](https://github.com/automazeio/ccpm)
- **最佳实践**: [Claude Code最佳实践](https://anthropic.com/news/claude-code-best-practices)
- **社区支持**: [GitHub Issues](https://github.com/automazeio/ccpm/issues)

---

**生成信息**:
- 项目类型: $project_type
- 生成时间: $(get_timestamp)
- CCPM版本: 2.0
- 框架状态: ✅ 已配置并验证

> 💡 **提示**: 这个CLAUDE.md文件是根据您的项目自动生成的。您可以根据项目需要进行自定义修改。

EOF
}

# =============================================================================
# MAIN GENERATION FUNCTION
# =============================================================================

generate_claude_md() {
    local project_type="$1"
    local output_file="${2:-.claude/CLAUDE.md}"
    
    log_info "生成项目特定的CLAUDE.md文件..."
    
    # Analyze project
    local project_name
    local project_description
    local features
    local testing_tools
    local build_tools
    
    project_name=$(get_project_name)
    project_description=$(get_project_description "$project_type")
    features=$(analyze_project_features "$project_type")
    testing_tools=$(detect_testing_tools "$project_type")
    build_tools=$(detect_build_tools "$project_type")
    
    # Create backup if file exists
    if [[ -f "$output_file" ]]; then
        cp "$output_file" "${output_file}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "已备份现有的CLAUDE.md文件"
    fi
    
    # Generate the file
    {
        generate_header "$project_name" "$project_type" "$project_description"
        generate_quick_start "$project_type" "$features"
        generate_bash_commands "$project_type" "$testing_tools" "$build_tools"
        generate_ai_agents_section "$project_type"
        generate_testing_section "$project_type" "$testing_tools"
        generate_project_structure "$project_type"
        generate_workflow_section "$project_type"
        generate_custom_commands
        generate_footer "$project_type"
    } > "$output_file"
    
    log_success "已生成项目特定的CLAUDE.md文件: $output_file"
    
    # Show summary
    echo ""
    echo "📊 项目分析结果:"
    echo "  • 项目名称: $project_name"
    echo "  • 项目类型: $project_type"
    echo "  • 检测到的功能: ${features:-"无"}"
    echo "  • 测试工具: ${testing_tools:-"待配置"}"
    echo "  • 构建工具: ${build_tools:-"标准工具"}"
    echo ""
    echo "🎯 下一步操作:"
    echo "  1. 查看生成的CLAUDE.md文件"
    echo "  2. 根据需要进行自定义修改"
    echo "  3. 运行 /validate --quick 验证配置"
}

# Export the main function for use in other scripts
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f generate_claude_md
fi