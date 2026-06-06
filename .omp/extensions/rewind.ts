// omp /rewind extension — Cursor/Claude-Code 式文件级撤销
//
// 机制：每次会改文件的工具(edit/write/ast_edit/bash)执行前，把当前工作树
// 固化成一个 git 影子 commit，存到 refs/omp/rewind/*。
// - 用临时 index(GIT_INDEX_FILE)，绝不动你的暂存区 / HEAD / 分支。
// - 工作树无变化则跳过重复快照。
// - /undo  : 回到最近一次改动之前。
// - /rewind: 列出历史快照点，选一个回退。
// 全程纯代码 + git，不经过模型 → 零 token。

import { execFileSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { rmSync } from "node:fs";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

const MUTATORS: Record<string, true> = { edit: true, write: true, ast_edit: true, bash: true };
const REF_PREFIX = "refs/omp/rewind";
const MAX_SNAPSHOTS = 80;
const GIT_IDENT = {
  GIT_AUTHOR_NAME: "omp",
  GIT_AUTHOR_EMAIL: "omp@local",
  GIT_COMMITTER_NAME: "omp",
  GIT_COMMITTER_EMAIL: "omp@local",
};

type Snap = { ref: string; sha: string; date: string; label: string };

function git(cwd: string, args: string[], env?: NodeJS.ProcessEnv): string {
  return execFileSync("git", ["-C", cwd, ...args], {
    encoding: "utf8",
    env: env ?? process.env,
    stdio: ["ignore", "pipe", "pipe"],
    windowsHide: true,
  }).trim();
}

function tryGit(cwd: string, args: string[], env?: NodeJS.ProcessEnv): string | null {
  try {
    return git(cwd, args, env);
  } catch {
    return null;
  }
}

function isRepo(cwd: string): boolean {
  return tryGit(cwd, ["rev-parse", "--is-inside-work-tree"]) === "true";
}

function labelFor(toolName: string, input: Record<string, unknown>): string {
  const raw =
    (input?.path as string) ||
    (Array.isArray(input?.paths) ? (input.paths as string[])[0] : "") ||
    (input?.command as string) ||
    toolName;
  const one = String(raw).replace(/\s+/g, " ").trim();
  return `${toolName}: ${one.length > 60 ? one.slice(0, 57) + "..." : one}`;
}

function listSnaps(cwd: string): Snap[] {
  const out = tryGit(cwd, [
    "for-each-ref",
    "--sort=-committerdate",
    `--format=%(refname)%09%(objectname)%09%(committerdate:iso8601)%09%(contents:subject)`,
    REF_PREFIX,
  ]);
  if (!out) return [];
  return out
    .split("\n")
    .filter(Boolean)
    .map((line) => {
      const [ref, sha, date, subject = ""] = line.split("\t");
      return { ref, sha, date, label: subject.replace(/^omp-snapshot: /, "") };
    });
}

// 把当前工作树固化为影子 commit，返回 sha；无变化或失败返回 null。
function snapshot(cwd: string, label: string): string | null {
  if (!isRepo(cwd)) return null;
  const idx = join(tmpdir(), `omp-rewind-${process.pid}-${Date.now()}.idx`);
  const env = { ...process.env, GIT_INDEX_FILE: idx };
  try {
    git(cwd, ["add", "-A"], env); // 临时 index，含未跟踪、排除 .gitignore
    const tree = git(cwd, ["write-tree"], env);

    // 工作树与上一快照相同则跳过
    const last = listSnaps(cwd)[0];
    if (last) {
      const lastTree = tryGit(cwd, ["rev-parse", `${last.sha}^{tree}`]);
      if (lastTree === tree) return null;
    }

    const head = tryGit(cwd, ["rev-parse", "HEAD"]);
    const commitArgs = ["commit-tree", tree, "-m", `omp-snapshot: ${label}`];
    if (head) commitArgs.push("-p", head);
    const commit = git(cwd, commitArgs, { ...process.env, ...GIT_IDENT });

    const ref = `${REF_PREFIX}/${Date.now()}`;
    git(cwd, ["update-ref", ref, commit]);
    prune(cwd);
    return commit;
  } catch {
    return null;
  } finally {
    try {
      rmSync(idx, { force: true });
      rmSync(`${idx}.lock`, { force: true });
    } catch {
      /* ignore */
    }
  }
}

function prune(cwd: string): void {
  const snaps = listSnaps(cwd);
  for (const s of snaps.slice(MAX_SNAPSHOTS)) {
    tryGit(cwd, ["update-ref", "-d", s.ref]);
  }
}

// 精确回退：让工作树与暂存区都等于该快照，并删除快照之后新建的文件。
// 用 read-tree+checkout-index 而非 restore，避免快照内未跟踪文件被随后的 clean 误删。
// 末尾 reset 把 index 重新对齐到 HEAD，保持暂存区干净。HEAD/分支始终不动。
function restore(cwd: string, sha: string): boolean {
  if (tryGit(cwd, ["read-tree", sha]) === null) return false;
  if (tryGit(cwd, ["checkout-index", "-a", "-f"]) === null) {
    tryGit(cwd, ["reset", "-q"]); // 尽力恢复 index
    return false;
  }
  tryGit(cwd, ["clean", "-fd"]); // 删除快照后新建文件(尊重 .gitignore)
  tryGit(cwd, ["reset", "-q"]); // index 对齐回 HEAD，worktree 不变
  return true;
}

function fmt(s: Snap): string {
  const t = s.date.slice(0, 19).replace("T", " ");
  return `${t}  ${s.label}`;
}

export default function rewind(pi: ExtensionAPI): void {
  pi.setLabel?.("rewind (file undo)");

  // —— 改文件前自动快照 ——
  pi.on("tool_call", async (event, ctx) => {
    if (!MUTATORS[event.toolName]) return;
    try {
      snapshot(ctx.cwd, labelFor(event.toolName, (event.input ?? {}) as Record<string, unknown>));
    } catch {
      /* 永不阻塞工具执行 */
    }
    return; // 不返回 block
  });

  // —— /undo：回到最近一次改动之前 ——
  pi.registerCommand("undo", {
    description: "回退文件到最近一次改动之前",
    handler: async (_args, ctx) => {
      const cwd = ctx.cwd;
      if (!isRepo(cwd)) return void ctx.ui.notify("当前不是 git 仓库，无法撤销", "error");
      const snaps = listSnaps(cwd);
      if (!snaps.length) return void ctx.ui.notify("没有可回退的快照", "error");
      const s = snaps[0];
      const ok = await ctx.ui.confirm(
        "撤销最近改动",
        `回退到此快照：\n${fmt(s)}\n\n工作树与暂存区将完全恢复到该时刻，此后的所有改动(含你手动改的、以及之后新建的文件)都会丢失。HEAD/分支不变。继续？`,
      );
      if (!ok) return;
      snapshot(cwd, "回退前(可再次撤销)"); // 先存现状，回退过头也能找回
      const done = restore(cwd, s.sha);
      ctx.ui.notify(done ? `已回退到：${s.label}` : "回退失败", done ? "info" : "error");
    },
  });

  // —— /rewind：列出快照选点回退 ——
  pi.registerCommand("rewind", {
    description: "选择一个历史快照点回退文件",
    handler: async (_args, ctx) => {
      const cwd = ctx.cwd;
      if (!isRepo(cwd)) return void ctx.ui.notify("当前不是 git 仓库，无法回退", "error");
      const snaps = listSnaps(cwd);
      if (!snaps.length) return void ctx.ui.notify("没有可回退的快照", "error");

      let picked: Snap | undefined;
      try {
        const value = await ctx.ui.select(
          "回退到哪个快照",
          snaps.map((s) => ({ label: fmt(s), value: s.sha })),
        );
        picked = snaps.find((s) => s.sha === value);
      } catch {
        picked = snaps[0]; // select 不可用时退化为最近一次
      }
      if (!picked) return;

      const ok = await ctx.ui.confirm(
        "回退文件",
        `回退到此快照：\n${fmt(picked)}\n\n工作树与暂存区将完全恢复到该时刻，此后的改动与新建文件都会丢失。HEAD/分支不变。继续？`,
      );
      if (!ok) return;
      snapshot(cwd, "回退前(可再次撤销)");
      const done = restore(cwd, picked.sha);
      ctx.ui.notify(done ? `已回退到：${picked.label}` : "回退失败", done ? "info" : "error");
    },
  });

  // —— /snapshots：查看已存快照 ——
  pi.registerCommand("snapshots", {
    description: "列出当前所有 rewind 快照",
    handler: async (_args, ctx) => {
      const snaps = listSnaps(ctx.cwd);
      if (!snaps.length) return void ctx.ui.notify("没有快照", "info");
      ctx.ui.notify(snaps.slice(0, 20).map(fmt).join("\n"), "info");
    },
  });
}
