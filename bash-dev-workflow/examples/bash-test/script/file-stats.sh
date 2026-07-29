#!/bin/bash
#===============================================================================
# file-stats.sh — 目录文件统计器
# 依赖: find, du, sort, wc（均为系统自带）
#===============================================================================
set -Eeuo pipefail

#===============================================================================
# 配置
#===============================================================================
TOP_N="${TOP_N:-5}"
DRY_RUN="${DRY_RUN:-false}"
VERBOSE="${VERBOSE:-false}"

#===============================================================================
# 日志
#===============================================================================
log_info()  { printf "[%(%H:%M:%S)T] INFO: %s\n" -1 "$*" >&2; }
log_warn()  { printf "[%(%H:%M:%S)T] WARN: %s\n" -1 "$*" >&2; }
log_error() { printf "[%(%H:%M:%S)T] ERROR: %s\n" -1 "$*" >&2; }
log_debug() { [[ "${VERBOSE}" == "true" ]] && printf "[%(%H:%M:%S)T] DEBUG: %s\n" -1 "$*" >&2; }

#===============================================================================
# 清理
#===============================================================================
TMPDIR=""
cleanup() {
    if [[ -n "${TMPDIR}" && -d "${TMPDIR}" ]]; then
        rm -rf "${TMPDIR}"
        log_debug "清理临时目录: ${TMPDIR}"
    fi
}
trap cleanup EXIT
trap 'log_error "脚本在第 ${LINENO} 行出错"; exit 1' ERR

#===============================================================================
# 帮助
#===============================================================================
usage() {
    cat <<'EOF'
用法: file-stats.sh <目录> [选项]

统计指定目录的文件信息。

参数:
    目录          要扫描的目录路径（必填）

选项:
    -n, --top N   显示前 N 个最大文件（默认: 5）
    -d, --dry-run 预览模式
    -v, --verbose 详细输出
    -h, --help    显示帮助

示例:
    file-stats.sh ./project
    file-stats.sh ./project -n 10
    file-stats.sh ./project -d
EOF
    exit "${1:-0}"
}

#===============================================================================
# 输入校验
#===============================================================================
validate_target_dir() {
    local -r dir="$1"
    [[ -n "${dir}" ]]  || { log_error "目录路径不能为空"; return 1; }
    [[ -d "${dir}" ]]  || { log_error "目录不存在: ${dir}"; return 1; }
    [[ -r "${dir}" ]]  || { log_error "目录不可读: ${dir}"; return 1; }
}

run_cmd() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        printf "[DRY RUN] %s\n" "$*" >&2
        return 0
    fi
    "$@"
}

#===============================================================================
# 主逻辑
#===============================================================================
main() {
    local target_dir=""
    local top_n="${TOP_N}"

    # 参数解析
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--top)
                top_n="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -h|--help)
                usage 0
                ;;
            -*)
                log_error "未知选项: $1"
                usage 1
                ;;
            *)
                target_dir="$1"
                shift
                ;;
        esac
    done

    # 必填校验
    [[ -n "${target_dir}" ]] || { log_error "缺少目标目录"; usage 1; }
    validate_target_dir "${target_dir}" || exit 1

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY RUN] 扫描目录: ${target_dir}"
        log_info "[DRY RUN] Top N: ${top_n}"
        return 0
    fi

    log_info "扫描目录: ${target_dir}"

    # 创建临时目录（NUL 安全文件列表）
    TMPDIR="$(mktemp -d)" || { log_error "无法创建临时目录"; exit 1; }
    local file_list="${TMPDIR}/files.txt"

    # 收集所有文件（排除目录、排除隐藏文件）
    find "${target_dir}" -type f -not -path '*/\.*' -print0 > "${file_list}" 2>/dev/null || true

    local total_files
    total_files=$(tr '\0' '\n' < "${file_list}" | wc -l)
    total_files=$((total_files + 0))  # 去掉 wc 的前导空格

    if [[ ${total_files} -eq 0 ]]; then
        log_warn "目录中没有文件"
        return 0
    fi

    # ── 按扩展名统计 ──
    printf '\n══════════════════════════════════════\n'
    printf '  按扩展名统计\n'
    printf '══════════════════════════════════════\n'
    printf '%-12s %8s\n' '扩展名' '文件数'
    printf '%-12s %8s\n' '------' '------'

    tr '\0' '\n' < "${file_list}" \
        | awk -F. '{if(NF>1) print $NF; else print "(无扩展名)"}' \
        | sort | uniq -c | sort -rn \
        | while read -r count ext; do
            printf '%-12s %8d\n' ".${ext}" "${count}"
        done

    # ── 总大小 ──
    local total_size
    total_size=$(tr '\0' '\n' < "${file_list}" | xargs du -ch 2>/dev/null | tail -1 | cut -f1)
    printf '\n总大小: %s  |  总文件: %d\n' "${total_size:-N/A}" "${total_files}"

    # ── Top N 大文件 ──
    printf '\n══════════════════════════════════════\n'
    printf '  Top %d 大文件\n' "${top_n}"
    printf '══════════════════════════════════════\n'
    printf '%-8s %s\n' '大小' '文件'
    printf '%-8s %s\n' '----' '----'

    tr '\0' '\n' < "${file_list}" \
        | xargs du -h 2>/dev/null \
        | sort -rh \
        | head -n "${top_n}" \
        | while read -r size filepath; do
            local rel="${filepath#${target_dir}/}"
            printf '%-8s %s\n' "${size}" "${rel}"
        done

    printf '\n'
    log_info "统计完成"
}

main "$@"
