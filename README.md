# 自动从 Travis CI 发布插件到 wordpress.org

## 设置方法

### 添加以下配置到 `.travis.yml`.

只有在 `after_success` 后才执行发布操作

```
after_success: curl -L https://raw.githubusercontent.com/iwillhappy1314/deploy2wporg/master/deploy.sh
```

此脚本只在 `WP_PULUGIN_DEPLOY` 为 `true` 时运行.

```
matrix:
  include:
    - php: 7.0
      env: WP_VERSION=latest WP_MULTISITE=0 WP_PULUGIN_DEPLOY=1
```

添加全局环境变量

```
env:
  matrix:
    - WP_VERSION=latest WP_MULTISITE=0
  global:
    - PLUGIN_SLUG=wenprise-pinyin-slug
    - SVN_REPO=https://plugins.svn.wordpress.org/$PLUGIN_SLUG/
    - GIT_REPO=https://github.com/iwillhappy1314/$PLUGIN_SLUG.git
    - MAINFILE="$PLUGIN_SLUG.php"
    - secure: "*****"
```

`secure` 获取方式：

```
travis encrypt SVN_USER=<your-account> SVN_PASS=<your-password>
```

http://docs.travis-ci.com/user/encryption-keys/

### `.svnignore` 示例

````
.svnignore
.phpcs.xml.dist
.travis.yml
phpunit.xml.dist
bin/
tests/
````

有 `.svnignore`时，次脚本自动执行 `svn propset -R`

### 如果设置了 `bin/build.sh`， 部署时会自动运行

如果使用了 `gulp`, `composer` 等，请放在 `bin/build.sh` 中，`bin/build.sh` 将自动执行

## 提交方式

如果需要提交的 wordpress.org 时，添加 tag 即可，需要注意的是，svn 的 tag 是 readme.txt 中的版本号，而不是 github 中的 tag，建议两个 tag 保持一致。

```
$ git tag 1.0.0
$ git push origin 1.0.0
```

assets 目录中的文件和 readme.txt 这两个文件总是会提交。

## 集成步骤

按照下面的代办事项，集成到需要发布的插件项目中。

* [ ]  添加 `after_success: curl -L https://raw.githubusercontent.com/miya0001/travis2wpplugin/master/deploy.sh | bash` 到 `.travis.yml`，如[示例](https://github.com/tarosky/logbook/blob/master/.travis.yml#L57).
* [ ] 在  `.travis.yml` 中定义 `WP_PULUGIN_DEPLOY=1`，如[示例](https://github.com/tarosky/logbook/blob/master/.travis.yml#L14).
* [ ] 运行 `travis encrypt SVN_USER=<your-account> SVN_PASS=<your-password>` 然后粘贴输出到 `.travis.yml`， 如[示例](https://github.com/tarosky/logbook/blob/master/.travis.yml#L43-L46).
* [ ] 如果需要排除文件，添加文件列表到 `.svnignore` 中，如[示例](https://github.com/tarosky/logbook/blob/master/.distignore).
* [ ] 如果需要 `npm install` 或 `composer install` 添加他们到 `build.sh` 中，[示例](https://github.com/tarosky/logbook/blob/master/bin/build.sh).

发布插件时，打标签即可触发自动发布流程。

```
$ git tag 1.0.0
$ git push origin 1.0.0
```

## 示例项目

我们在以下插件中使用了此项目，请参考。


* https://github.com/iwillhappy1314/wenprise-pinyin-slug