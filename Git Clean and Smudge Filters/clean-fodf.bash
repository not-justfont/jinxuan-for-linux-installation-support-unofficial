#!/usr/bin/env bash
# 上列為宣告執行 script 程式用的殼程式(shell)的 shebang
# Clean filter for Flat-ODF
# 林博仁 © 2016

######## File scope variable definitions ########
# Defensive Bash Programming - not-overridable primitive definitions
# http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/
declare -r PROGRAM_FILENAME="$(basename "$0")"
declare -r PROGRAM_DIRECTORY="$(realpath --no-symlinks "$(dirname "$0")")"
declare -r PROGRAM_ARGUMENT_ORIGINAL_LIST="$@"
declare -r PROGRAM_ARGUMENT_ORIGINAL_NUMBER=$#

## Unofficial Bash Script Mode
## http://redsymbol.net/articles/unofficial-bash-strict-mode/
# 將未定義的變數的參考視為錯誤
set -u

# Exit immediately if a pipeline, which may consist of a single simple command, a list, or a compound command returns a non-zero status.  The shell does not exit if the command that fails is part of the command list immediately following a `while' or `until' keyword, part of the test in an `if' statement, part of any command executed in a `&&' or `||' list except the command following the final `&&' or `||', any command in a pipeline but the last, or if the command's return status is being inverted with `!'.  If a compound command other than a subshell returns a non-zero status because a command failed while `-e' was being ignored, the shell does not exit.  A trap on `ERR', if set, is executed before the shell exits.
set -e

# If set, the return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status, or zero if all commands in the pipeline exit successfully.
set -o pipefail

######## File scope variable definitions ended ########

######## Included files ########

######## Included files ended ########

######## Program ########
# Defensive Bash Programming - main function, program entry point
# http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/
main() {
	printf "Clean 過濾器：正在移除非必要資訊跟美化 XML 標記代碼……\n" 1>&2

	# Catch the incoming stream to a temp file
	local temp_file_name="$(basename "$PROGRAM_FILENAME").temporary.stdin.xml"
	local temp_file="$PROGRAM_DIRECTORY/$temp_file_name"
	rm --force "$temp_file"
	cat >"$temp_file"

	# 不追蹤存檔當前編輯軟體設定
	xml_delete_node "$temp_file" "/office:document/office:settings"

	# 不追蹤編輯軟體識別名稱
	xml_delete_node "$temp_file" "/office:document/office:meta/meta:generator"

	# 不追蹤編輯次數
	xml_delete_node "$temp_file" "/office:document/office:meta/meta:editing-cycles"

	# 不追蹤總編輯時間
	xml_delete_node "$temp_file" "/office:document/office:meta/meta:editing-duration"

	# 不追蹤文件統計資訊（列數、字數等）
	xml_delete_node "$temp_file" "/office:document/office:meta/meta:document-statistic"

	# 不追蹤從系統取得的預設字型資訊
	xml_delete_node "$temp_file" "/office:document/office:font-face-decls/style:font-face[@style:font-family-generic='system']"

	xml_delete_node "$temp_file" "/office:document/office:meta/dc:date"

	# 不追蹤預設(?)樣式資訊
	xml_delete_node "$temp_file" "/office:document/office:styles/style:default-style"

	# 不追蹤非必要且會變動的 xml:id 屬性
	xml_transform_node "$PROGRAM_DIRECTORY"/clean-fodf.remove-xml-id-attributes.xslt "$temp_file"

	xml_format_node "$temp_file"

	cat "$temp_file"

	rm "$temp_file"

	exit 0
}

xml_delete_node(){
	local xml_file="$1"
	local node_xpath="$2"

	local temp_file="${xml_file}.new"
	xmlstarlet edit --pf --ps --delete "$node_xpath" "$xml_file" >"$temp_file"
	mv --force "$temp_file" "$xml_file"
}

xml_transform_node(){
	local xsl_file="$1"
	local xml_file="$2"

	local temp_file="${xml_file}.new"
	xmlstarlet transform "$xsl_file" "$xml_file" >"${temp_file}"
	mv --force "$temp_file" "$xml_file"
}

xml_format_node(){
	local xml_file="$1"

	local temp_file="${xml_file}.new"
	xmlstarlet format --indent-tab "$xml_file" >"${temp_file}"
	mv --force "$temp_file" "$xml_file"
}

main
