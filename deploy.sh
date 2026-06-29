#!/usr/bin/env bash
# ============================================================================
#  Bohao Li — One-Click Deploy to GitHub Pages
#
#  Usage:
#    bash deploy.sh                          # 默认一键部署
#    bash deploy.sh --clean                  # 同时清理无用大文件
#    bash deploy.sh --msg="..."              # 自定义 commit 信息
#    bash deploy.sh --clean --msg="..."      # 组合
#
#  退出码：
#    0 = 成功
#    1 = git 配置失败
#    2 = push 失败（多半是认证问题）
# ============================================================================

set -e

# ---- 定位脚本所在目录 = 项目根 ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
cd "$SCRIPT_DIR"

# ---- ANSI 颜色（Git Bash 支持） ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

section() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n  $1\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }
ok()      { echo -e "${GREEN}✓${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $1"; }
fail()    { echo -e "${RED}❌${NC} $1"; }

# ---- 默认配置（按需改） ----
REMOTE_URL="https://github.com/lbh1044750906/lbh1044750906.github.io.git"
BRANCH="main"
USER_NAME="Bohao Li"
USER_EMAIL="libohao@iie.ac.cn"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
COMMIT_MSG="Deploy updates at $TIMESTAMP"

# ---- 解析参数 ----
CLEAN_DEAD=false
for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN_DEAD=true ;;
    --msg=*) COMMIT_MSG="${arg#*=}" ;;
    --help|-h)
      echo "Usage: bash deploy.sh [--clean] [--msg='commit message']"
      exit 0 ;;
  esac
done

# ============================================================================
# Step 1: 项目目录
# ============================================================================
section "Step 1/8 — 项目目录"
ok "$SCRIPT_DIR"

# ============================================================================
# Step 2: git init（如未初始化）
# ============================================================================
section "Step 2/8 — 初始化 git 仓库"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ok "已经是 git 仓库，跳过 init"
else
  git init
  ok "新建 git 仓库"
fi

# ============================================================================
# Step 3: 身份
# ============================================================================
section "Step 3/8 — 配置 git 身份"
git config user.name "$USER_NAME"
git config user.email "$USER_EMAIL"
ok "user.name  = $USER_NAME"
ok "user.email = $USER_EMAIL"

# ============================================================================
# Step 4: 配置 origin（如未配置）
# ============================================================================
section "Step 4/8 — 配置远程 origin"
if git remote get-url origin >/dev/null 2>&1; then
  ok "origin 已配置"
else
  git remote add origin "$REMOTE_URL"
  ok "已添加 origin → $REMOTE_URL"
fi
git remote -v | head -1

# ============================================================================
# Step 5: 拉取远端
# ============================================================================
section "Step 5/8 — 拉取远端状态"
echo "（如果停在这里，多半是 git 在等 HTTPS 账号密码"
echo "  → 解决方案：上方方案 A（写 .netrc）或 B（SSH key））"
echo ""
# 不再吞错，方便看到 hang 在哪
if GIT_TERMINAL_PROMPT=0 git fetch origin "$BRANCH" 2>&1 | tee /tmp/git-fetch.log | grep -E "fatal|error" >/dev/null; then
  fail "fetch 失败："
  cat /tmp/git-fetch.log
  echo ""
  warn "如果你看到 'could not resolve' 或 'Connection refused' → 网络问题"
  warn "如果你看到 'terminal prompts disabled' 或被踢回来 → 凭证问题"
  warn "继续往下跑，push 时会再次报错"
elif GIT_TERMINAL_PROMPT=0 git fetch origin "$BRANCH" >/dev/null 2>&1; then
  ok "已 fetch origin/$BRANCH"
else
  warn "fetch 异常，请检查上方输出"
fi

# ============================================================================
# Step 6: 合并远端文件（允许不相关历史）
# ============================================================================
section "Step 6/8 — 合并远端（允许不相关历史）"
if git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
  if git pull origin "$BRANCH" --allow-unrelated-histories --no-rebase 2>/dev/null; then
    ok "已合并远端文件（如 README.md）"
  else
    warn "合并出现冲突，放弃合并继续"
    git merge --abort 2>/dev/null || true
    warn "将以本地状态强推。如远端有重要独立文件请 Ctrl+C 中断"
    sleep 3
  fi
else
  ok "远端 main 不存在或为空，无需 pull"
fi

# ============================================================================
# Step 6.5 (可选): 清理 dead 文件
# ============================================================================
if $CLEAN_DEAD; then
  section "Step 6.5/8 — 清理无用大文件 (--clean)"
  DEAD_FILES=(
    "static/js/tex-svg.js"
    "static/js/bootstrap.bundle.min.js"
    "static/js/bootstrap.bundle.min.js.map"
    "static/css/styles.css"
    "static/assets/img/background.jpg"
    "static/assets/img/photo.png"
  )
  for f in "${DEAD_FILES[@]}"; do
    if [ -f "$f" ]; then
      SIZE=$(du -h "$f" | cut -f1)
      rm -f "$f"
      ok "删除 $f ($SIZE)"
    fi
  done
fi

# ============================================================================
# Step 7: add + commit
# ============================================================================
section "Step 7/8 — git add + commit"
git add -A
TOTAL=$(git status --short | wc -l)
echo "共 $TOTAL 项变化："
git status --short | head -15
[ "$TOTAL" -gt 15 ] && echo "  ... 还有 $(($TOTAL - 15)) 项"

if git diff --cached --quiet; then
  ok "没有需要提交的内容"
else
  git commit -m "$COMMIT_MSG"
  ok "已 commit：$COMMIT_MSG"
fi

# ============================================================================
# Step 8: push
# ============================================================================
section "Step 8/8 — git push"
echo "如果弹出认证窗口："
echo "  Username:  lbh1044750906"
echo "  Password:  贴入你的 GitHub Personal Access Token (PAT)"
echo "               (https://github.com/settings/tokens)"
echo ""

if git push -u origin "$BRANCH" 2>&1; then
  ok "已 push 到 origin/$BRANCH"
else
  fail "push 失败（exit code 见下）"
  echo ""
  echo "╔════════════════════════════════════════════════════════╗"
  echo "║  常见原因 & 排查                                       ║"
  echo "╠════════════════════════════════════════════════════════╣"
  echo "║  1. 用了密码而非 PAT                                   ║"
  echo "║     → https://github.com/settings/tokens              ║"
  echo "║     → Generate new token (classic)                    ║"
  echo "║     → 勾选 repo 权限                                  ║"
  echo "║                                                        ║"
  echo "║  2. SSH key 未配置（如果 remote URL 用 git@）           ║"
  echo "║     → 改 HTTPS：git remote set-url origin $REMOTE_URL ║"
  echo "║                                                        ║"
  echo "║  3. 网络/VPN 问题                                      ║"
  echo "║     → 试着关闭代理或换 VPN                              ║"
  echo "╚════════════════════════════════════════════════════════╝"
  exit 2
fi

# ============================================================================
# 完成
# ============================================================================
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✓ 部署完成！                                          ${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  GitHub Pages 正在 rebuild（1-2 分钟）。"
echo "  之后访问："
echo ""
echo -e "    ${BLUE}https://lbh1044750906.github.io/${NC}"
echo ""
echo "  强刷：Ctrl + Shift + R  （Chrome / Firefox / Edge）"
echo ""
