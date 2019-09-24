#!/usr/bin/env bash

set -e

#####################################################
# 部署检查
#####################################################

# pull request 时不部署
if [ "false" != "$TRAVIS_PULL_REQUEST" ]; then
  echo "Not deploying pull requests."
  exit
fi

# 只部署一次
if [ ! "$WP_PULUGIN_DEPLOY" ]; then
  echo "Not deploying."
  exit
fi

# SVN 仓库未定义，发出提醒
if [ ! "$SVN_REPO" ]; then
  echo "SVN repo is not specified."
  exit
fi

#####################################################
# 拉取代码，开始构建
#####################################################

# 创建部署所使用的目录
mkdir build

cd build
BUILT_DIR=$(pwd)

# 检出 SVN
echo "从 svn 仓库检出 $SVN_REPO ..."
svn co -q "$SVN_REPO" ./svn

# 检出 Git，已经有了，是不是不需要再来一遍了，或者直接 checkout?
echo "从 git 仓库克隆 $GIT_REPO ..."
git clone -q "$GIT_REPO" ./git

# 如果设置了构建脚本，开始构建
cd "$BUILT_DIR"/git

if [ -e "bin/build.sh" ]; then
  echo "开始执行 bin/build.sh."
  bash bin/build.sh
fi

#####################################################
# 获取 Git 中的插件版本
#####################################################
READMEVERSION=$(grep "Stable tag" "$BUILT_DIR"/git/readme.txt | awk '{ print $NF}')
PLUGINVERSION=$(grep "Version:" "$BUILT_DIR"/git/"$MAINFILE" | awk '{ print $NF}')
# shellcheck disable=SC2046
LATEST_TAG=$(git describe --tags $(git rev-list --tags --max-count=1))

#####################################################
# 同步文件
#####################################################
# 同步 git 仓库到 SVN
cd "$BUILT_DIR"
echo "同步 Git 仓库到 SVN"

echo "$LATEST_TAG"

if [ "$TRAVIS_TAG" ]; then
  # 发布标签时，同步所有文件，然后删除 .git 文件
  echo "同步 git 文件到 svg trunk 中"
  rsync -a --exclude=".svn" --checksum --delete ./git/ ./svn/trunk/
else
  # 非标签发布时，同步 readme.txt 和 assets 文件
  # 只有最新 Git Tag 和 readme.txt 中的 Tag 相同时，才更新 readme.txt，以免触发 wordpress.org 的自动版本发布
  if [ "$LATEST_TAG" = "$READMEVERSION" ]; then
    echo "同步 readme.text 和 assets"
    cp ./git/readme.txt ./svn/trunk/ -f
    cp ./git/wordpress.org/. ./svn/assets/ -fa
  else
    echo "git 版本和插件版本不一致，跳过更新"
  fi
fi

# 同步完成后、移除 svn trunk 中的 .git 和 wordpress.org 目录
echo "移除 svn trunk 中的 .git 和 wordpress.org 目录"
rm "$BUILT_DIR"/svn/trunk/.git -Rf
rm "$BUILT_DIR"/svn/trunk/wordpress.org -Rf

#####################################################
# 设置忽略文件、删除忽略的文件
#####################################################
cd "$BUILT_DIR"/svn/trunk

# 设置 svn 忽略
if [ -e ".svnignore" ]; then
  echo "根据 .svnignore 忽略文件"
  svn propset -q -R svn:ignore -F .svnignore .
fi

# 删除忽略的文件
echo "删除忽略文件"
# shellcheck disable=SC2013
for file in $(cat ".svnignore" 2>/dev/null); do
  rm "$file" -Rf
done

#####################################################
# 执行 SVN 操作
#####################################################
cd "$BUILT_DIR"/svn

echo "运行 svn add"
svn st | grep '^!' | sed -e 's/\![ ]*/svn del -q /g' | sh
echo "运行 svn del"
svn st | grep '^?' | sed -e 's/\?[ ]*/svn add -q /g' | sh

#####################################################
# 如果设置了用户名密码，提交到仓库，必须是 Tag 才能提交
#####################################################
cd "$BUILT_DIR"/svn
svn stat

if [ "$TRAVIS_TAG" ] && [ "$LATEST_TAG" = "$READMEVERSION" ]; then

  #####################################################
  # 比较版本，如果两个版本不一样，退出
  #####################################################

  if [ "$READMEVERSION" != "$PLUGINVERSION" ]; then
    echo "插件主文件和 readme.txt 中的版本不一致，退出..."
    exit 1
  fi

  # 发布到 wordpress.org
  echo "发布到 wordpress.org"
  svn ci --no-auth-cache --username "$SVN_USER" --password "$SVN_PASS" -m "Deploy version $READMEVERSION"

  # 打标签
  echo "打标签"
  svn copy --no-auth-cache --username "$SVN_USER" --password "$SVN_PASS" "$SVN_REPO"/trunk "$SVN_REPO"/tags/"$READMEVERSION" -m "Add tag $READMEVERSION"
  echo "发布新版本完成"

else

  svn ci --no-auth-cache --username "$SVN_USER" --password "$SVN_PASS" -m "Update readme.txt"
  echo "更新 assets 和 readme.txt 完成"

fi
