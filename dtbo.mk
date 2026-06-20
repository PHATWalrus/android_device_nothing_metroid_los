# Custom DTBO image build rules for metroid (nothing phone 3)
MKDTBOIMG := $(HOST_OUT_EXECUTABLES)/mkdtboimg$(HOST_EXECUTABLE_SUFFIX)

$(BOARD_PREBUILT_DTBOIMAGE): $(INSTALLED_DTBIMAGE_TARGET) $(MKDTBOIMG)
	@echo "Building custom dtbo.img from DTB_OBJ"
	$(hide) mkdir -p $(dir $@)
	$(MKDTBOIMG) create $@ --page_size=$(BOARD_KERNEL_PAGESIZE) $(shell find out/target/product/metroid/obj/DTB_OBJ/arch/$(KERNEL_ARCH)/boot/dts/ -type f -name "tuna*.dtbo" | sort)
