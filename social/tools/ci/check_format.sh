#!/bin/bash
# 标准输出流作为提示信息，使用 $? 判断是否通过
# 注意，工作目录必须是 git 根目录
cd ../../..

function isDartFile() {
  if echo "$1" | grep -q -E '\.dart$'
  then
    return 0
  else
    return 1
  fi
}

changedDartFiles=""
for file in $1;
do
  # 文件被删除或者不是普通文件，跳过格式化检查
  if [ ! -f "$file" ]; then
    continue
  fi
  # 非 Dart 文件，跳过格式化检查
  if ! isDartFile "$file"; then
    continue
  fi

  changedDartFiles="$changedDartFiles $file"
done

if [[ -z $changedDartFiles ]]; then
  echo "No file needs to be formatted."
  exit 0
fi

echo "Detecting files need to be formatted..."
# shellcheck disable=SC2086
fvm flutter format -n --suppress-analytics --set-exit-if-changed $changedDartFiles
