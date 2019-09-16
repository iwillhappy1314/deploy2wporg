# Automated deploy to wordpress.org plugin repository from Travis CI

## How to setup

### 添加以下配置到 `.travis.yml`.

Deployment should be executed only `after_success`.

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

This script runs `svn propset -R` automatically  when there is a `.svnignore`.

### 如果设置了 `bin/build.sh`， 部署时会自动运行

If you are using `gulp`, `composer` or so, please place the `bin/build.sh`.

`bin/build.sh` will be executed automatically.

## 提交方式

如果需要提交的 wordpress.org 时，添加 tag 即可，需要注意的是，svn 的 tag 是 readme.txt 中的版本号，而不是 github 中的 tag，建议两个 tag 保持一致。

```
$ git tag 1.0.0
$ git push origin 1.0.0
```

assets 目录中的文件和 readme.txt 这两个文件总是会提交。

## Integration Checklist

You can use following checklist to integrate this project in your plugin.

* [ ]  Add `after_success: curl -L https://raw.githubusercontent.com/miya0001/travis2wpplugin/master/deploy.sh | bash` into `.travis.yml` like [this](https://github.com/tarosky/logbook/blob/master/.travis.yml#L57).
* [ ] Define the `WP_PULUGIN_DEPLOY=1` in the `.travis.yml` like [this](https://github.com/tarosky/logbook/blob/master/.travis.yml#L14).
* [ ] Run `travis encrypt SVN_USER=<your-account> SVN_PASS=<your-password>` and paste the output into `.travis.yml` like [this](https://github.com/tarosky/logbook/blob/master/.travis.yml#L43-L46).
* [ ] Place the `.distignore` that are list of files to exclude to commit SVN. It is an [example](https://github.com/tarosky/logbook/blob/master/.distignore).
* [ ] If you need to run `npm install` or `composer install` or so, place the `build.sh` that will be executed automatically. This is an [example](https://github.com/tarosky/logbook/blob/master/bin/build.sh).

Finnaly, you can release your plugin like following.

```
$ git tag 1.0.0
$ git push origin 1.0.0
```

## Example project

We are using this project in following plugins.

Please check logs of Travis CI.

* https://github.com/miya0001/simple-map
* https://github.com/miya0001/oembed-gist
* https://github.com/miya0001/content-template-engine
* https://github.com/miya0001/wp-total-hacks
* https://github.com/torounit/hello-kushimoto/