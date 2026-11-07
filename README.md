# kwaf

`kwaf` 是 Kangle Web Server 的防 CC 扩展。

## 编译要求

- Linux 或 Windows
- CMake 3.12 或更高版本（部分发行版中的命令名为 `cmake3`）
- 支持 C++14 的编译器
- 已安装的 Kangle，以及与该安装版本一致的 Kangle 源代码

构建参数：

- `KANGLE_DIR`：Kangle **安装目录**，例如 `/vhs/kangle`。
- `KANGLE_SOURCE_DIR`：Kangle **源代码目录**。若源码位于 `kwaf` 同级的 `kangle` 目录，可省略该参数。

## Windows 编译

先运行相邻 Kangle 项目的 `build-windows.ps1` 生成开发头文件。在 kwaf 工程目录运行 `.\build-windows.ps1`，默认生成 `build/Release/kwaf.dll`。

脚本默认使用 Kangle 源码中 `deps/windows-x64` 的依赖和 Kangle 的 `build/install`。可通过 `-BuildDirectory`、`-DependencyRoot` 或 `-KangleDirectory` 指定对应目录。

## Linux 编译和安装

```sh
git clone https://github.com/netcccyun/kwaf.git
cd kwaf

cmake -S . -B build \
  -DKANGLE_DIR=/vhs/kangle \
  -DKANGLE_SOURCE_DIR=/path/to/kangle-source \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
cmake --build build --target install
```

安装完成后应生成：

- `/vhs/kangle/bin/kwaf.so`
- `/vhs/kangle/ext/kwaf.dso.xml`

最后重启或重载 Kangle，使扩展配置生效。升级 Kangle 后应使用对应版本的源码重新编译本扩展，避免内部接口不一致。

## 图形验证码

扩展内置四位数字图形验证码，请在 Kangle 请求控制中为路径 `/KANGLE_CCIMG.php` 添加 `anti_session` 标记规则。
对应的请求控制链为：

```xml
<chain action="continue">
  <acl module="path" path="/KANGLE_CCIMG.php"/>
  <mark module="anti_session"/>
</chain>
```
