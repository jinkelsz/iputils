#
# Configuration
#

# CC
CC=gcc
#指定到gcc编译程序
# Path to parent kernel include files directory
#包含文件目录的父路径
LIBC_INCLUDE=/usr/include
# Libraries
#添加库
ADDLIB=
# Linker flags
#wlz作用是将之后的参数传给编译器
LDFLAG_STATIC=-Wl,-Bstatic
#-Wl,-Bstatic告诉链接器使用-Bstatic选项，该选项是告诉链接器，对接下来的-l选项使用静态链接
LDFLAG_DYNAMIC=-Wl,-Bdynamic
#告诉链接器对接下来的-l选项使用动态链接
#加载库
#加载载cap函数库、TLS加密函数库、crypto加密解密函数库、idn恒等函数库、resolv函数库、sysfs接口函数库
LDFLAG_CAP=-lcap
LDFLAG_GNUTLS=-lgnutls-openssl
LDFLAG_CRYPTO=-lcrypto
LDFLAG_IDN=-lidn
LDFLAG_RESOLV=-lresolv
LDFLAG_SYSFS=-lsysfs

#
# Options
#
#变量定义，设置开关
# Capability support (with libcap) [yes|static|no]
#用libcap表示cap函数的支持
USE_CAP=yes
#初始化文件系统
#函数库的支持、表示方式及状态
# sysfs support (with libsysfs - deprecated) [no|yes|static]
USE_SYSFS=no
# IDN support (experimental) [no|yes|static]
USE_IDN=no
#第一个为默认状态
#并且默认不使用函数gentifaddrs获得接口信息
# Do not use getifaddrs [no|yes|static]
WITHOUT_IFADDRS=no
#默认的设备：无线、网卡等
# arping default device (e.g. eth0) []
ARPING_DEFAULT_DEVICE=
#GNU TLS库ping6的默认状态为：是
# GNU TLS library for ping6 [yes|no|static]
USE_GNUTLS=yes
# Crypto library for ping6 [shared|static]
#加密解密库为默认共享
USE_CRYPTO=shared
# Resolv library for ping6 [yes|static]
USE_RESOLV=yes
# ping6 source routing (deprecated by RFC5095) [no|yes|RFC3542]
#ping6源不使用REC5095 状态：无
ENABLE_PING6_RTHDR=no

# rdisc server (-r option) support [no|yes]
#rdisc服务器默认不支持 -r 选项
ENABLE_RDISC_SERVER=no

# -------------------------------------
# What a pity, all new gccs are buggy and -Werror does not work. Sigh.
# CCOPT=-fno-strict-aliasing -Wstrict-prototypes -Wall -Werror -g
CCOPT=-fno-strict-aliasing -Wstrict-prototypes -Wall -g
#-Wstrict-prototypes: 如果函数的声明或定义没有指出参数类型，编译器报警告
CCOPTOPT=-O3
#优化等级 ——3
#assert（）所有信息关闭
GLIBCFIX=-D_GNU_SOURCE
DEFINES=
LDLIB=

FUNC_LIB = $(if $(filter static,$(1)),$(LDFLAG_STATIC) $(2) $(LDFLAG_DYNAMIC),$(2))

#确定每个函数库中是否有重复函数
# USE_GNUTLS: DEF_GNUTLS, LIB_GNUTLS
# USE_CRYPTO: LIB_CRYPTO
#确定crypto加密解密函数库的函数是否重复
ifneq ($(USE_GNUTLS),no)
	LIB_CRYPTO = $(call FUNC_LIB,$(USE_GNUTLS),$(LDFLAG_GNUTLS))
	DEF_CRYPTO = -DUSE_GNUTLS
else
	LIB_CRYPTO = $(call FUNC_LIB,$(USE_CRYPTO),$(LDFLAG_CRYPTO))
endif

# USE_RESOLV: LIB_RESOLV
#确定resolv加密解密函数库的函数是否重复
LIB_RESOLV = $(call FUNC_LIB,$(USE_RESOLV),$(LDFLAG_RESOLV))

# USE_CAP:  DEF_CAP, LIB_CAP
#判断CAP函数库中的函数是否重复
ifneq ($(USE_CAP),no)
	DEF_CAP = -DCAPABILITIES
	LIB_CAP = $(call FUNC_LIB,$(USE_CAP),$(LDFLAG_CAP))
endif

# USE_SYSFS: DEF_SYSFS, LIB_SYSFS
#判断接口函数库SYSFS是否重复
ifneq ($(USE_SYSFS),no)
	DEF_SYSFS = -DUSE_SYSFS
	LIB_SYSFS = $(call FUNC_LIB,$(USE_SYSFS),$(LDFLAG_SYSFS))
endif

# USE_IDN: DEF_IDN, LIB_IDN
#判断IDN恒等函数库中的函数是否重复
ifneq ($(USE_IDN),no)
	DEF_IDN = -DUSE_IDN
	LIB_IDN = $(call FUNC_LIB,$(USE_IDN),$(LDFLAG_IDN))
endif

# WITHOUT_IFADDRS: DEF_WITHOUT_IFADDRS
#观察是否使用IFADDRS。若使用禁用
ifneq ($(WITHOUT_IFADDRS),no)
	DEF_WITHOUT_IFADDRS = -DWITHOUT_IFADDRS
endif

# ENABLE_RDISC_SERVER: DEF_ENABLE_RDISC_SERVER
ifneq ($(ENABLE_RDISC_SERVER),no)
	DEF_ENABLE_RDISC_SERVER = -DRDISC_SERVER
endif

# ENABLE_PING6_RTHDR: DEF_ENABLE_PING6_RTHDR
#ping6失能原路由
ifneq ($(ENABLE_PING6_RTHDR),no)
	DEF_ENABLE_PING6_RTHDR = -DPING6_ENABLE_RTHDR
#禁止使用rfc3542
ifeq ($(ENABLE_PING6_RTHDR),RFC3542)
	DEF_ENABLE_PING6_RTHDR += -DPINR6_ENABLE_RTHDR_RFC3542
endif
endif

# -------------------------------------
IPV4_TARGETS=tracepath ping clockdiff rdisc arping tftpd rarpd
IPV6_TARGETS=tracepath6 traceroute6 ping6
TARGETS=$(IPV4_TARGETS) $(IPV6_TARGETS)

CFLAGS=$(CCOPTOPT) $(CCOPT) $(GLIBCFIX) $(DEFINES)
LDLIBS=$(LDLIB) $(ADDLIB)

UNAME_N:=$(shell uname -n)
LASTTAG:=$(shell git describe HEAD | sed -e 's/-.*//')
#日期、使用时间  年/月/日
TODAY=$(shell date +%Y/%m/%d)
DATE=$(shell date --date $(TODAY) +%Y%m%d)
TAG:=$(shell date --date=$(TODAY) +s%Y%m%d)


# -------------------------------------
#查内核模块在编译过程中产生的中间文件并加以清除
.PHONY: all ninfod clean distclean man html check-kernel modules snapshot
#伪代码 使用 make +名称
all: $(TARGETS)

%.s: %.c
	$(COMPILE.c) $< $(DEF_$(patsubst %.o,%,$@)) -S -o $@
#生成目标文件  $< 依赖目标中的第一个目标名字  $@ 表示目标
%.o: %.c
	$(COMPILE.c) $< $(DEF_$(patsubst %.o,%,$@)) -o $@
$(TARGETS): %: %.o
	$(LINK.o) $^ $(LIB_$@) $(LDLIBS) -o $@
#$^ 所有的依赖目标的集合 

## 在$(patsubst %.o,%,$@ )中，patsubst把目标中的变量符合后缀是.o的全部删除,  DEF_ping
# LINK.o把.o文件链接在一起的命令行,缺省值是$(CC) $(LDFLAGS) $(TARGET_ARCH)
# -------------------------------------
# arping
#给相邻主机发ARP请求
DEF_arping = $(DEF_SYSFS) $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS)
LIB_arping = $(LIB_SYSFS) $(LIB_CAP) $(LIB_IDN)

ifneq ($(ARPING_DEFAULT_DEVICE),)
DEF_arping += -DDEFAULT_DEVICE=\"$(ARPING_DEFAULT_DEVICE)\"
endif

# clockdiff
DEF_clockdiff = $(DEF_CAP)
LIB_clockdiff = $(LIB_CAP)

# ping / ping6
DEF_ping_common = $(DEF_CAP) $(DEF_IDN)
DEF_ping  = $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS)
LIB_ping  = $(LIB_CAP) $(LIB_IDN)
DEF_ping6 = $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS) $(DEF_ENABLE_PING6_RTHDR) $(DEF_CRYPTO)
LIB_ping6 = $(LIB_CAP) $(LIB_IDN) $(LIB_RESOLV) $(LIB_CRYPTO)

ping: ping_common.o
ping6: ping_common.o
ping.o ping_common.o: ping_common.h
ping6.o: ping_common.h in6_flowlabel.h

# rarpd
DEF_rarpd =
LIB_rarpd =

# rdisc
DEF_rdisc = $(DEF_ENABLE_RDISC_SERVER)
LIB_rdisc =

# tracepath
DEF_tracepath = $(DEF_IDN)
LIB_tracepath = $(LIB_IDN)

# tracepath6
DEF_tracepath6 = $(DEF_IDN)
LIB_tracepath6 =

# traceroute6
DEF_traceroute6 = $(DEF_CAP) $(DEF_IDN)
LIB_traceroute6 = $(LIB_CAP) $(LIB_IDN)

# tftpd
DEF_tftpd =
DEF_tftpsubs =
LIB_tftpd =

tftpd: tftpsubs.o
tftpd.o tftpsubs.o: tftp.h

# -------------------------------------
# ninfod
ninfod:
	@set -e; \
		if [ ! -f ninfod/Makefile ]; then \
			cd ninfod; \
			./configure; \
			cd ..; \
		fi; \
		$(MAKE) -C ninfod

# -------------------------------------
# modules / check-kernel are only for ancient kernels; obsolete
check-kernel:
ifeq ($(KERNEL_INCLUDE),)
	@echo "Please, set correct KERNEL_INCLUDE"; false
else
	@set -e; \
	if [ ! -r $(KERNEL_INCLUDE)/linux/autoconf.h ]; then \
		echo "Please, set correct KERNEL_INCLUDE"; false; fi
endif

modules: check-kernel
	$(MAKE) KERNEL_INCLUDE=$(KERNEL_INCLUDE) -C Modules

# -------------------------------------
man:
	$(MAKE) -C doc man

html:
	$(MAKE) -C doc html

clean:
	@rm -f *.o $(TARGETS)
	@$(MAKE) -C Modules clean
	@$(MAKE) -C doc clean
	@set -e; \
		if [ -f ninfod/Makefile ]; then \
			$(MAKE) -C ninfod clean; \
		fi

distclean: clean
	@set -e; \
		if [ -f ninfod/Makefile ]; then \
			$(MAKE) -C ninfod distclean; \
		fi

# -------------------------------------
snapshot:
	@if [ x"$(UNAME_N)" != x"pleiades" ]; then echo "Not authorized to advance snapshot"; exit 1; fi
	@echo "[$(TAG)]" > RELNOTES.NEW
	@echo >>RELNOTES.NEW
	@git log --no-merges $(LASTTAG).. | git shortlog >> RELNOTES.NEW
	@echo >> RELNOTES.NEW
	@cat RELNOTES >> RELNOTES.NEW
	@mv RELNOTES.NEW RELNOTES
	@sed -e "s/^%define ssdate .*/%define ssdate $(DATE)/" iputils.spec > iputils.spec.tmp
	@mv iputils.spec.tmp iputils.spec
	@echo "static char SNAPSHOT[] = \"$(TAG)\";" > SNAPSHOT.h
	@$(MAKE) -C doc snapshot
	@$(MAKE) man
	@git commit -a -m "iputils-$(TAG)"
	@git tag -s -m "iputils-$(TAG)" $(TAG)
	@git archive --format=tar --prefix=iputils-$(TAG)/ $(TAG) | bzip2 -9 > ../iputils-$(TAG).tar.bz2

