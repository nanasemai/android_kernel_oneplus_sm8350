########################################################################
# OnePlus 9 (SM8350 / lemonade) - Kernel settings
# 基于 droidian-oneplus6/config/kernel-info.mk 改写
# 依据: ../oneplus9-lineageos/SD_BOOTFLOW_COMPARISON.md §7 +
#       ../oneplus9-lineageos/ONEPLUS9_LINEAGEOS_BUILD.md §16-17
#
# ⚠️ 关键架构变化 (vs 传统单 SoC 设备):
#   - 内核 Linux 4.9 -> 5.4.191 (或 5.10.x，需实测确认)
#   - SD 单 dtb -> SM8350 dtb + dtbo overlay（三星 AMB655X 面板）
#   - boot.img header v0 (legacy) -> v3 (Android 11)
#   - **DTB 在 vendor_boot.img，不在 boot.img** (v3 分离结构)
#   - **dtbo.img 独立分区** (需单独刷入)
#   - 单 vendor -> vendor + odm + system_ext 三分区
#   - **Virtual A/B** (不是传统 A/B，需 snapuserd)
#   - HIDL -> HIDL + AIDL 混合 (composer/camera/audio/sensors 用 AIDL)
########################################################################

VARIANT = android
# TODO 阶段 1: 实测确认内核版本 (5.4.191 或 5.10.x)
#   grep -E "^(VERSION|PATCHLEVEL|SUBLEVEL)" src/kernel-fork/Makefile
KERNEL_BASE_VERSION = 5.4-191

DEVICE_VENDOR = oneplus
DEVICE_MODEL = oneplus9
DEVICE_FULL_NAME = OnePlus 9
# OnePlus 9 = lemonade (9 Pro = lemonadep)
DEVICE_CODENAME = lemonade
# TARGET_BOARD_PLATFORM = lahaina
DEVICE_BOARD = lahaina
DEVICE_BOARD_PLATFORM = lahaina
# variant1 = 中国/全球零售版 (T-Mobile variant2 不在范围)
DEVICE_VARIANT = 1

# defconfig 来自上游 dev-sm8350/kernel_oneplus_sm8350
# (fork 的 lineage-19.1 分支缺此 defconfig, 需阶段 1 第一步同步)
KERNEL_DEFCONFIG = lahaina-qgki_defconfig

# 启用配置片段合并（droidian/common_fragments/*.config + droidian/oneplus9.config）
KERNEL_CONFIG_USE_FRAGMENTS = 1

# ⚠️ SM8350 用 boot header v3 分离结构:
#   boot.img 只装 kernel + ramdisk
#   vendor_boot.img 装 vendor ramdisk + DTB
#   dtbo.img 装 DTB overlays (独立分区)
# ⚠️ 必须为 1：上游 snippet 只在 KERNEL_IMAGE_WITH_DTB=1 时生成 dtb-merged，
#    而 vendor_boot.img 的 --dtb 固定取 dtb-merged（否则 DTB 为空）。
KERNEL_IMAGE_WITH_DTB = 1
# 生成 vendor_boot.img（上游 snippet 变量名，旧写法 KERNEL_VENDOR_BOOT 不被识别）
KERNEL_BOOTIMAGE_GENERATE_VENDOR_BOOT = 1
# SM8350 用 dtbo 独立分区
KERNEL_IMAGE_WITH_DTB_OVERLAY = 1
KERNEL_IMAGE_DTB_OVERLAY_CONFIGURATION = debian/dtbo_config.cfg
KERNEL_IMAGE_DTB_OVERLAY_DTB_DIRECTORY = arch/arm64/boot/dts/vendor

# TODO 阶段 1: 确认上游 DTB 实际文件名
#   已查：主线树 (nanasemai/sm8350-mainline-linux/for-upstream) 有:
#     - sm8350-oneplus-lemonade.dts (95 行)
#     - sm8350-oneplus-common.dtsi (1323 行)
#     - sm8350.dtsi (4455 行)
#   ⚠️ 主线 DTS 里 MDSS 全部被注释掉，需补 panel 节点 (见 PORTING_PLAN.md §2.4)
# vendor 内核实际产物名（相对 $(KERNEL_OUT)）；主线命名 sm8350-oneplus-lemonade.dtb 不存在
KERNEL_IMAGE_DTB = arch/arm64/boot/dts/vendor/qcom/lahaina.dtb
KERNEL_IMAGE_DTB_NAME = lahaina
KERNEL_DTB_OVERLAY_OUTPUT = arch/arm64/boot/dts/qcom/*.dtbo

# 实测值：从 dist/kernel/boot.img（2026-10-12 构建产物）用 unpack_bootimg 读出，
# 与 stock 一致的 qcom 通用 cmdline。Droidian 需要的 apparmor 参数可按需追加。
KERNEL_BOOTIMAGE_CMDLINE = androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 androidboot.usbcontroller=a600000.dwc3 swiotlb=2048 loop.max_part=7 cgroup.memory=nokmem,nosocket reboot=panic_warm

# boot.img 参数：实测自 dist/kernel/vendor_boot.img 的地址字段反推
#   kernel load 0x10008000 / tags 0x10000100 / ramdisk 0x11000000 / dtb 0x11f00000
KERNEL_BOOTIMAGE_PAGE_SIZE = 4096
KERNEL_BOOTIMAGE_BASE_OFFSET = 0x10000000
KERNEL_BOOTIMAGE_KERNEL_OFFSET = 0x00008000
KERNEL_BOOTIMAGE_INITRAMFS_OFFSET = 0x01000000
KERNEL_BOOTIMAGE_SECONDIMAGE_OFFSET = 0x00f00000
KERNEL_BOOTIMAGE_TAGS_OFFSET = 0x00000100

# vendor_boot.img 的 dtb 地址。上游 snippet 会无条件传 --dtb_offset，留空会导致 mkbootimg 报错。
KERNEL_BOOTIMAGE_DTB_OFFSET = 0x01f00000

# vendor_boot 的 cmdline（实测自 dist/kernel/vendor_boot.img）
KERNEL_BOOTIMAGE_VENDOR_CMDLINE = androidboot.hardware=qcom androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1

# Android 11 = boot.img header v3 (不是 oneplus6 的 v0 legacy)
KERNEL_BOOTIMAGE_VERSION = 3
# stock 镜像 os_patch_level 为空，保持一致（需要时取消注释）
# KERNEL_BOOTIMAGE_PATCH_LEVEL = 2020-12
KERNEL_OS_VERSION = 11.0.0

# vbmeta 签名 (SM8350 有验证链)
DEVICE_VBMETA_REQUIRED = 1
DEVICE_VBMETA_IS_SAMSUNG = 0
DEVICE_AVB_VERSION = 1.0

########################################################################
# Automatic flashing
########################################################################

FLASH_ENABLED = 1
# ⚠️ SM8350 用 Virtual A/B (不是传统 A/B):
#   - 物理分区只有一份
#   - snapuserd 通过 dm-thin 虚拟出 A/B slot
FLASH_IS_AONLY = 0
# ⭐ Virtual A/B 标志
FLASH_IS_VIRTUAL_AB = 1
FLASH_IS_LEGACY_DEVICE = 0
FLASH_IS_EXYNOS = 0

FLASH_INFO_CPU = Qualcomm Technologies, Inc SM8350
FLASH_INFO_DEVICE_IDS = sm8350
FLASH_INFO_PRODUCT = lemonade

# ⚠️ 三个镜像都要刷 (不是 only boot.img):
FLASH_PARTITIONS = boot,vendor_boot,dtbo,vendor,odm,system_ext,userdata

########################################################################
# Build settings (Debian 官方交叉编译器)
########################################################################

BUILD_CROSS = 1
# 使用 Debian 交叉 GCC（不依赖 clang-android 包）
CLANG_CUSTOM = 1
BUILD_TRIPLET = aarch64-linux-gnu-
BUILD_CLANG_TRIPLET = aarch64-linux-gnu-
BUILD_CC = aarch64-linux-gnu-gcc
BUILD_PATH = /usr/local/bin:/usr/bin
DEB_TOOLCHAIN = binutils-aarch64-linux-gnu, gcc-aarch64-linux-gnu, g++-aarch64-linux-gnu
DEB_BUILD_ON = amd64

# ⚠️ 用户态架构: arm64 (Droidian/phosh 官方生态原生架构)
#    依据：
#    - phosh 官方仅发布 arm64 版本（phosh.io/releases）
#    - Droidian 项目基于 Ubuntu phosh，走 arm64 用户态
#    - 与内核 arm64 一致，无兼容层开销
#    - GNOME 生态 64 位性能更优
#    ⚠️ AGNOS agnos-display 是 armhf deb（含闭源 Adreno 660 GL 栈）
#    显示栈方案：走 Weston+GBM+Mesa/freedreno（PORTING_PLAN §4.2 讨论），
#    或把 AGNOS armhf 作为独立层集成（另计预算）。
#    详见：../PORTING_PLAN.md §4.2 + ../HALIUM_UBPORTS_REFERENCE.md §3.6
DEB_BUILD_FOR = arm64

KERNEL_ARCH = arm64
# 5.4 qcom 内核没有 Image.gz-dtb 目标（OP6 的 4.9 才有），实际构建目标为 Image.gz
KERNEL_BUILD_TARGET = Image.gz

# ⚠️ fstab 文件名: fstab.qcom.default (不是 fstab.lahaina)
#    依据真机 DTS bootargs: androidboot.fstab_suffix=default
DEVICE_FSTAB_SUFFIX = default

# ⚠️ HAL 架构: HIDL + AIDL 混合
#   AIDL: composer, camera, audio, sensors
#   HIDL: bluetooth, fingerprint, nfc, wifi, gps
DEVICE_HAL_ARCH = hybrid
DEVICE_HAL_AIDL = composer,camera,audio,sensors
DEVICE_HAL_HIDL = bluetooth,fingerprint,nfc,wifi,gps
