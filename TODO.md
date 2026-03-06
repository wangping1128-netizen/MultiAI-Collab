# MultiAI-Collab TODO List

> 按阶段推进，每个阶段完成后提交并推送到 GitHub / Gitee。

---

## Phase 1: 框架核心完善

### 1.1 任务管道 (Task Pipeline)
- [x] **任务自动编号**: 编写 `scripts/new_task.sh`，扫描已有 task 文件自动分配下一个 3 位编号
- [x] **任务模板生成**: `new_task.sh` 交互式创建任务文件（标题、assignee、file scope）
- [x] **Prompt 传递优化**: assign 脚本改用 stdin pipe / temp file 传递 prompt，避免参数长度限制
- [x] **并行任务调度**: orchestrator 支持同时 dispatch 多个独立任务（后台执行 + PID 追踪）

### 1.2 Review 自动化
- [x] **Claude 自动 review 脚本**: `scripts/review.sh` 一次性 + `--watch` 轮询模式，调用 Claude CLI (-p) 审查
- [x] **Review 报告格式**: 在 `tasks/done/` 生成 `task-XXX-review.md`（verdict/score/feedback/action）
- [x] **失败自动重派**: review fail/revise 时自动生成修复任务到 `tasks/pending/`

### 1.3 配置管理
- [x] **统一配置文件**: 创建 `config.json`，集中管理 poll interval、timeout、model、sandbox、review 等参数
- [x] **脚本读取配置**: 所有脚本通过 `scripts/lib/config.sh` 的 `cfg()` 函数读取配置，零硬编码

### 1.4 日志与监控
- [x] **结构化日志**: orchestrator 输出写入 `logs/orchestrator.log`（带时间戳 + 任务名）
- [x] **任务统计面板**: `scripts/status.sh` 汇总当前各目录任务数量、成功/失败率、平均耗时

---

## Phase 2: 端到端验证

### 2.1 冒烟测试
- [x] **E2E 测试脚本**: `scripts/test_e2e.sh` 8项测试全通过（config/new_task/codex/gemini/status）
- [x] **Mock 模式**: config.json `dry_run: true` 开关，assign 脚本生成模拟结果文件

### 2.2 用真实任务验证
- [x] **测试任务 1 (Codex)**: Codex (gpt-5.3-codex) 创建 Express /health endpoint，1/1 测试通过
- [x] **测试任务 2 (Gemini -> Codex 降级)**: Gemini 配额耗尽，自动降级到 Codex 完成 StatusCard，2/2 测试通过
- [x] **测试降级路径**: Gemini 429 quota -> 降级到 Codex fallback 成功验证

---

## Phase 3: 开发体验优化

### 3.1 Git 工作流
- [x] **双仓库推送脚本**: `scripts/push_all.sh` 配置驱动 + `--force` 确认（Codex task-003）
- [x] **pre-commit hook**: `.githooks/pre-commit` 非阻塞警告 + `scripts/setup_hooks.sh`（Codex task-003）
- [x] **分支策略**: `main` (稳定) + `master` (开发) 已建立并推送到双仓库

### 3.2 CLI 快捷命令
- [x] **npm scripts 扩展**: 在 package.json 添加常用命令
  - `npm run new-task` -> 创建任务
  - `npm run status` -> 查看任务状态
  - `npm run start` -> 启动 orchestrator
  - `npm run push` -> 推送到双仓库
- [x] **交互式任务创建器**: `scripts/create_task.js` Inquirer.js 交互式创建（Codex task-005）

### 3.3 Agent 上下文注入
- [x] **项目上下文文件**: `AGENTS.md` 已创建，包含技术栈、项目结构、编码规范
- [x] **assign 脚本注入上下文**: 在 prompt 前自动附加 AGENTS.md 内容（已预埋，AGENTS.md 存在时自动注入）

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
| Phase 1 | **已完成** | 任务管道 + Review 自动化 + 配置管理 + 日志监控 |
| Phase 2 | **已完成** | E2E 冒烟测试 + Codex/Gemini 真实任务 + 降级验证 |
| Phase 3 | **已完成** | Git 工作流 + CLI 快捷命令 + Agent 上下文注入 |
| Phase 4 | 未开始 | 需用户确定业务方向 |
| Phase 5 | 未开始 | 依赖 Phase 4 |
