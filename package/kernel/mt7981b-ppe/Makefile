include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=mt7981b-ppe
PKG_VERSION:=0.1.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0
PKG_MAINTAINER:=xbyyd

PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define KernelPackage/mt7981b-ppe
  SUBMENU:=Network Support
  TITLE:=MT7981B PPE/WED hook prototype
  DEPENDS:=@TARGET_mediatek_filogic +kmod-nf-conntrack
  FILES:=$(PKG_BUILD_DIR)/mt7981b_ppe.ko
  AUTOLOAD:=$(call AutoLoad,30,mt7981b_ppe)
endef

define KernelPackage/mt7981b-ppe/description
  Out-of-tree prototype that wires the MT7981B packet processing engine
  into the WED path of the filogic target. Work in progress: symbol
  resolution against the kernel image is unfinished.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	+$(KERNEL_MAKE) M=$(PKG_BUILD_DIR) modules
endef

$(eval $(call KernelPackage,mt7981b-ppe))
