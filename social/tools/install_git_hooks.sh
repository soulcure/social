SHELL_FOLDER=$(cd "$(dirname "$0")" || exit;pwd)
cp -rf "$SHELL_FOLDER"/hooks/* "$SHELL_FOLDER"/../../.git/hooks/
echo git hooks installed.