# MultiAI-Collab TODO List

> 按阶段推进，每个阶段完成后提交并推送到 GitHub / Gitee。

---

## Phase 1: 框架核心完善

### 1.1 任务管道 (Task Pipeline)
- [ ] **任务自动编号**: 编写 `scripts/new_task.sh`，扫描已有 task 文件自动分配下一个 3 位编号
- [ ] **任务模板生成**: `new_task.sh` 交互式创建任务文件（标题、assignee、file scope）
- [ ] **Prompt 传递优化**: assign 脚本改用 stdin pipe 传递 prompt，避免参数长度限制
- [ ] **并行任务调度**: orchestrator 支持同时 dispatch 多个独立任务（后台执行 + PID 追踪）

### 1.2 Review 自动化
- [ ] **Claude 自动 review 脚本**: `scripts/review.sh` 监听 `tasks/done/`，调用 Claude CLI 审查结果文件
- [ ] **Review 报告格式**: 在 `tasks/done/` 生成 `task-XXX-review.md`（pass/fail + 反馈）
- [ ] **失败自动重派**: review 失败时自动生成修复任务到 `tasks/pending/`

### 1.3 配置管理
- [ ] **统一配置文件**: 创建 `config.toml`，集中管理 poll interval、timeout、model 选择、sandbox 模式等
- [ ] **脚本读取配置**: orchestrator 和 assign 脚本从 `config.toml` 读取参数，而非硬编码

### 1.4 日志与监控
- [ ] **结构化日志**: orchestrator 输出写入 `logs/orchestrator.log`（带时间戳 + 任务名）
- [ ] **任务统计面板**: `scripts/status.sh` 汇总当前各目录任务数量、成功/失败率、平均耗时

---

## Phase 2: 端到端验证

### 2.1 冒烟测试
- [ ] **E2E 测试脚本**: `scripts/test_e2e.sh` 创建一个简单任务，走完 pending -> dispatch -> done -> review 全流程
- [ ] **Mock 模式**: assign 脚本支持 `--dry-run`，不实际调用 CLI，而是生成模拟结果文件（用于 CI）

### 2.2 用真实任务验证
- [ ] **测试任务 1 (Codex)**: 让 Codex 创建一个简单的 Express.js hello world endpoint
- [ ] **测试任务 2 (Gemini)**: 让 Gemini 创建一个简单的 React 组件
- [ ] **测试降级路径**: 故意触发超时，验证降级 + failed result 文件生成

---

## Phase 3: 开发体验优化

### 3.1 Git 工作流
- [ ] **双仓库推送脚本**: `scripts/push_all.sh` 一键推送到 github + gitee
- [ ] **pre-commit hook**: 检查不允许直接修改 `src/` 目录（必须通过任务流程）
- [ ] **分支策略**: 建立 `main` (稳定) + `master` (开发) 分支模型

### 3.2 CLI 快捷命令
- [ ] **npm scripts 扩展**: 在 package.json 添加常用命令
  - `npm run new-task` -> 创建任务
  - `npm run status` -> 查看任务状态
  - `npm run start` -> 启动 orchestrator
  - `npm run push` -> 推送到双仓库
- [ ] **交互式任务创建器**: Node.js 脚本，用 Inquirer.js 引导创建任务

### 3.3 Agent 上下文注入
- [ ] **项目上下文文件**: 生成 `AGENTS.md`，为 Codex/Gemini 提供项目结构、技术栈、编码规范
- [ ] **assign 脚本注入上下文**: 在 prompt 前自动附加 AGENTS.md 内容

---

## Phase 4: 选择并构建业务应用

### 4.1 确定应用方向
- [ ] **与用户讨论需求**: 确定用这个框架构建什么应用（API 服务、Web App、CLI 工具等）
- [ ] **技术栈确认**: 前后端技术选型、数据库、部署方案
- [ ] **架构设计文档**: `docs/architecture.md`

### 4.2 任务拆分与执行
- [ ] **创建第一批业务任务**: 基于架构设计拆分为 task-001 ~ task-00N
- [ ] **走完整协作流程**: Claude 拆任务 -> Codex/Gemini 实现 -> Claude review -> git commit
- [ ] **迭代优化**: 根据实际执行反馈调整框架和流程

---

## Phase 5: CI/CD 与文档

### 5.1 持续集成
- [ ] **GitHub Actions**: 自动运行测试、lint
- [ ] **Gitee CI**: 同步配置（如需要）
- [ ] **任务执行报告**: CI 中生成任务执行统计

### 5.2 项目文档
- [ ] **架构图**: 绘制 orchestrator 调度流程图（Mermaid）
- [ ] **贡献指南**: `CONTRIBUTING.md`，说明如何添加新 agent、新任务类型
- [ ] **演示视频/GIF**: 录制端到端工作流演示

---

## 当前进度

| Phase | 状态 | 备注 |
|-------|------|------|
| Phase 1 | **进行中** | 核心脚本已接入真实 CLI，待完善自动化 |
| Phase 2 | 未开始 | 依赖 Phase 1 |
| Phase 3 | 未开始 | 依赖 Phase 2 |
| Phase 4 | 未开始 | 需用户确定业务方向 |
| Phase 5 | 未开始 | 依赖 Phase 4 |
