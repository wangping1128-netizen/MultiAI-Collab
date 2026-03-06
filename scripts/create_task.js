#!/usr/bin/env node

const fs = require("fs");
const path = require("path");
const inquirer = require("inquirer");

const ROOT_DIR = path.resolve(__dirname, "..");
const TASKS_DIR = path.join(ROOT_DIR, "tasks");
const TASK_DIRECTORIES = ["pending", "in-progress", "done"].map((name) =>
  path.join(TASKS_DIR, name),
);
const PENDING_DIR = path.join(TASKS_DIR, "pending");

function ensureDirectory(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function getNextTaskNumber() {
  let maxTaskNumber = 0;
  const taskFilePattern = /^task-(\d+)(?:-result)?\.md$/i;

  for (const dir of TASK_DIRECTORIES) {
    if (!fs.existsSync(dir)) {
      continue;
    }

    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isFile()) {
        continue;
      }

      const match = entry.name.match(taskFilePattern);
      if (!match) {
        continue;
      }

      const taskNumber = Number.parseInt(match[1], 10);
      if (Number.isFinite(taskNumber) && taskNumber > maxTaskNumber) {
        maxTaskNumber = taskNumber;
      }
    }
  }

  return String(maxTaskNumber + 1).padStart(3, "0");
}

async function collectTechnicalRequirements() {
  const lines = [];
  let promptLabel =
    "Technical requirements (multi-line, press Enter on empty line to finish)";

  while (true) {
    const { requirementLine } = await inquirer.prompt([
      {
        type: "input",
        name: "requirementLine",
        message: promptLabel,
      },
    ]);

    const trimmedLine = requirementLine.trim();
    if (trimmedLine === "") {
      if (lines.length === 0) {
        promptLabel = "At least one requirement is required";
        continue;
      }

      break;
    }

    lines.push(requirementLine);
    promptLabel = "Technical requirement (next line, empty to finish)";
  }

  return lines.join("\n");
}

function parseFileScopeList(fileScopeInput) {
  return fileScopeInput
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function buildAdditionalCriteriaSection(additionalAcceptanceCriteria) {
  const trimmed = additionalAcceptanceCriteria.trim();
  if (!trimmed) {
    return "";
  }

  return `\n- [ ] ${trimmed}`;
}

function buildTaskContent({
  taskId,
  title,
  objective,
  requirements,
  fileScopeList,
  additionalCriteria,
  assignee,
}) {
  const fileScopeLines = fileScopeList.map((filePath) => `- ${filePath}`).join("\n");

  return `# ${taskId}: ${title}

## Objective
${objective}

## Technical Requirements
${requirements}

## File Scope (only these files may be modified)
${fileScopeLines}
DO NOT modify: package.json, .env, database schemas (unless explicitly stated)

## Acceptance Criteria
- [ ] All technical requirements implemented
- [ ] Code is clean and follows project conventions
- [ ] Unit test coverage > 80%${additionalCriteria}

## Assignee
${assignee}

## On Completion
Write result to tasks/done/${taskId}-result.md
`;
}

function isPromptCancellation(error) {
  if (!error) {
    return false;
  }

  if (error.name === "ExitPromptError") {
    return true;
  }

  const message = typeof error.message === "string" ? error.message : "";
  return message.toLowerCase().includes("force closed the prompt");
}

async function promptTaskData() {
  const { title } = await inquirer.prompt([
    {
      type: "input",
      name: "title",
      message: "Task title",
      validate(value) {
        return value.trim() ? true : "Task title is required";
      },
    },
  ]);

  const { assignee } = await inquirer.prompt([
    {
      type: "list",
      name: "assignee",
      message: "Assignee",
      choices: ["backend (Codex)", "frontend (Gemini)"],
    },
  ]);

  const { objective } = await inquirer.prompt([
    {
      type: "input",
      name: "objective",
      message: "Objective",
      default: () => title,
      filter: (value) => value.trim(),
    },
  ]);

  const requirements = await collectTechnicalRequirements();

  const { fileScopeInput } = await inquirer.prompt([
    {
      type: "input",
      name: "fileScopeInput",
      message: "File scope (comma-separated paths)",
      validate(value) {
        return parseFileScopeList(value).length > 0
          ? true
          : "Provide at least one file path";
      },
    },
  ]);

  const { additionalAcceptanceCriteria } = await inquirer.prompt([
    {
      type: "input",
      name: "additionalAcceptanceCriteria",
      message: "Additional acceptance criteria (optional)",
      default: "",
    },
  ]);

  return {
    title: title.trim(),
    assignee,
    objective: objective.trim() || title.trim(),
    requirements,
    fileScopeList: parseFileScopeList(fileScopeInput),
    additionalCriteria: buildAdditionalCriteriaSection(additionalAcceptanceCriteria),
  };
}

async function main() {
  ensureDirectory(PENDING_DIR);
  const taskNumber = getNextTaskNumber();
  const taskId = `task-${taskNumber}`;
  const taskFilePath = path.join(PENDING_DIR, `${taskId}.md`);
  const taskData = await promptTaskData();

  const taskContent = buildTaskContent({
    taskId,
    title: taskData.title,
    objective: taskData.objective,
    requirements: taskData.requirements,
    fileScopeList: taskData.fileScopeList,
    additionalCriteria: taskData.additionalCriteria,
    assignee: taskData.assignee,
  });

  fs.writeFileSync(taskFilePath, taskContent, "utf8");

  const relativeTaskFilePath = path.relative(ROOT_DIR, taskFilePath).replace(/\\/g, "/");
  console.log(`Created: ${relativeTaskFilePath}`);
  console.log("Summary:");
  console.log(`- Task ID: ${taskId}`);
  console.log(`- Title: ${taskData.title}`);
  console.log(`- Assignee: ${taskData.assignee}`);
  console.log(`- Files in scope: ${taskData.fileScopeList.length}`);
}

main().catch((error) => {
  if (isPromptCancellation(error)) {
    console.log("\nTask creation canceled.");
    process.exit(1);
  }

  console.error("Failed to create task:", error.message || error);
  process.exit(1);
});
