#!/usr/bin/env bash
# Thin Bash invocation adapter for scripts/review-run.ps1.
#
# This is NOT a reimplementation. The .ps1 stays the canonical implementation;
# this adapter only translates a Bash-shell invocation into a PowerShell -File
# call so that AI / operator invocations from Bash do not have to author
# `powershell -File "$env:USERPROFILE\..."` strings themselves. ToolRoot and
# ProjectRoot resolution remain inside the .ps1 (Get-ToolRoot channel chain),
# as do Codex CLI invocation, atomic result.md write, and verdict shape gate.
#
# Forwards PowerShell-style parameters unchanged (e.g. -ReviewTaskId, -Pass,
# -Reviewer, -Model). Performs minimal path normalization only for
# -ProjectRoot and -ToolRoot values so that CWD-relative or POSIX-rooted
# Bash inputs reach the .ps1 as absolute Windows-native paths.

set -e

# Ensure the Git for Windows / MSYS utility paths are visible even when the
# parent shell (e.g. Windows PowerShell) launched bash with a Windows-only
# PATH. We only prepend if /usr/bin is not already present so we do not
# disturb interactive Bash setups that already have it.
case ":$PATH:" in
    *:/usr/bin:*) ;;
    *) PATH="/usr/bin:/bin:$PATH" ;;
esac

# Derive the script directory using bash parameter expansion so we do not
# depend on the external `dirname` resolving on PATH. $0 may arrive with
# either forward (Bash) or backslash (Windows) separators when the launcher
# is PowerShell or cmd; normalize both to forward slash before splitting.
# When $0 has no slash at all (rare: bash invoked from the same directory
# without a path), fall back to the current working directory.
arg0_norm="${0//\\//}"
case "$arg0_norm" in
    */*) script_dir="$(cd "${arg0_norm%/*}" && pwd)" ;;
    *)   script_dir="$(pwd)" ;;
esac
target_ps1="$script_dir/review-run.ps1"

if [ ! -f "$target_ps1" ]; then
    printf 'review-run.sh: FAIL canonical script not found: %s\n' "$target_ps1" 1>&2
    exit 1
fi

if command -v cygpath >/dev/null 2>&1; then
    target_ps1_native="$(cygpath -w "$target_ps1")"
else
    target_ps1_native="$target_ps1"
fi

forwarded=()
while [ $# -gt 0 ]; do
    case "$1" in
        -ProjectRoot|-ToolRoot)
            flag="$1"
            shift
            if [ $# -eq 0 ]; then
                forwarded+=("$flag")
                break
            fi
            value="$1"
            shift
            if [ -e "$value" ]; then
                if [ -d "$value" ]; then
                    abs="$(cd "$value" && pwd)"
                else
                    # Split parent / leaf without invoking external dirname/basename.
                    case "$value" in
                        */*)
                            value_parent="${value%/*}"
                            value_leaf="${value##*/}"
                            ;;
                        *)
                            value_parent="."
                            value_leaf="$value"
                            ;;
                    esac
                    abs="$(cd "$value_parent" && pwd)/$value_leaf"
                fi
            else
                abs="$value"
            fi
            if command -v cygpath >/dev/null 2>&1 && [ "${abs#/}" != "$abs" ]; then
                abs="$(cygpath -w "$abs")"
            fi
            forwarded+=("$flag" "$abs")
            ;;
        *)
            forwarded+=("$1")
            shift
            ;;
    esac
done

exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$target_ps1_native" "${forwarded[@]}"
