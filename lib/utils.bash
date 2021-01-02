#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/ajeetdsouza/zoxide"

fail() {
  echo -e "asdf-zoxide: $*"
  exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//'
}

list_all_versions() {
  list_github_tags
}

get_kernel_name() {
  uname -s | tr '[:upper:]' '[:lower:]'
}

get_os() {
  uname -o | awk -F '/' '{print $1}' | tr '[:upper:]' '[:lower:]'
}

get_processor() {
  uname -p
}

download_release() {
  local version filename kernel_name os processor url
  version="$1"
  filename="$2"
  kernel_name="$(get_kernel_name)"
  os="$(get_os)"
  processor="$(get_processor)"

  if [ "${kernel_name}" == "darwin" ]; then
    url="$GH_REPO/releases/download/v${version}/zoxide-${processor}-apple-${kernel_name}"
  else
    url="$GH_REPO/releases/download/v${version}/zoxide-${processor}-unknown-${kernel_name}-${os}"
  fi

  echo "* Downloading zoxide release $version..."
  curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"

  if [ "$install_type" != "version" ]; then
    fail "asdf-zoxide supports release installs only"
  fi

  local binary_path="$install_path/bin/zoxide"
  (
    mkdir -p "$install_path/bin"
    download_release "$version" "$binary_path"
    chmod +x "$binary_path"

    local tool_cmd
    tool_cmd="zoxide"
    test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

    echo "zoxide $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error ocurred while installing zoxide $version."
  )
}
