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
#开始条件语句
DEF_arping += -DDEFAULT_DEVICE=\"$(ARPING_DEFAULT_DEVICE)\"
#继续进行追加
#$(ARPING_DEFAULT_DEVICE)后存在结尾空格，会被作为makefile需要执行的一部分。
endif

#iputtils软件包是网络工具的集合；内含工具clockdiff ping  ping6
# clockdiff
#计算目的主机和本地主机的时差
DEF_clockdiff = $(DEF_CAP)
LIB_clockdiff = $(LIB_CAP)

# ping / ping6
#测试计算机名称、IP 并检验与远程PC的连接
DEF_ping_common = $(DEF_CAP) $(DEF_IDN)
DEF_ping  = $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS)
LIB_ping  = $(LIB_CAP) $(LIB_IDN)
DEF_ping6 = $(DEF_CAP) $(DEF_IDN) $(DEF_WITHOUT_IFADDRS) $(DEF_ENABLE_PING6_RTHDR) $(DEF_CRYPTO)
LIB_ping6 = $(LIB_CAP) $(LIB_IDN) $(LIB_RESOLV) $(LIB_CRYPTO)
#ping程序由ping.c ping6.cping_common.c ping.h 文件构成 
ping: ping_common.o
ping6: ping_common.o
ping.o ping_common.o: ping_common.h
ping6.o: ping_common.h in6_flowlabel.h

# rarpd
#rdisc.c文件组成rdisc   为逆地址解析协议的服务端程序
DEF_rarpd =
LIB_rarpd =

# rdisc
DEF_rdisc = $(DEF_ENABLE_RDISC_SERVER)
LIB_rdisc =
#搜索守护程序

# tracepath
#测试IP数据报文从源主机传道目的主机的路由
DEF_tracepath = $(DEF_IDN)
LIB_tracepath = $(LIB_IDN)

# tracepath6
DEF_tracepath6 = $(DEF_IDN)
LIB_tracepath6 =

# traceroute6
DEF_traceroute6 = $(DEF_CAP) $(DEF_IDN)
LIB_traceroute6 = $(LIB_CAP) $(LIB_IDN)

# tftpd
#tftp协议的服务端程序可简单文件传送
DEF_tftpd =
DEF_tftpsubs =
LIB_tftpd =

tftpd: tftpsubs.o
tftpd.o tftpsubs.o: tftp.h
#tftpd.o tftpsubs.o文件   依赖于tftp.h头文件


# -------------------------------------
# ninfod
#可执行文件ninfod生成
ninfod:
	@set -e; \
	#确保目录下存在Makefile，若无创建一个
		if [ ! -f ninfod/Makefile ]; then \
		#压缩与解压缩
			cd ninfod; \
			./configure; \
			cd ..; \
		fi; \
		#fi为if语句的结束
		$(MAKE) -C ninfod  
		#else 为ninfod读取Makefile的路径

# -------------------------------------
#内核检查
# modules / check-kernel are only for ancient kernels; obsolete
#标记不再使用的实体，并提示警告
check-kernel:
ifeq ($(KERNEL_INCLUDE),)
	@echo "Please, set correct KERNEL_INCLUDE"; false
	#取消echo显示
else
	@set -e; \    
	#特殊处理以下字符
	if [ ! -r $(KERNEL_INCLUDE)/linux/autoconf.h ]; then \
	#autoconf.h为一般文件，否则报错
		echo "Please, set correct KERNEL_INCLUDE"; false; fi
endif

modules: check-kernel
	$(MAKE) KERNEL_INCLUDE=$(KERNEL_INCLUDE) -C Modules
	#用modules中的makefile文件编译文档

# -------------------------------------
man:
	$(MAKE) -C doc man
	#man帮助文档生成

html:
	$(MAKE) -C doc html

clean:
	@rm -f *.o $(TARGETS)
	#删除生成的所有的目标二进制文件
	@$(MAKE) -C Modules clean
	#执行clean 删除指定文件
	@$(MAKE) -C doc clean
	@set -e; \
		if [ -f ninfod/Makefile ]; then \
		#在ninfod下有makefile文件进行读取
			$(MAKE) -C ninfod clean; \
			#清除编译的执行文件和配置文件
		fi

distclean: clean
	@set -e; \
		if [ -f ninfod/Makefile ]; then \
			$(MAKE) -C ninfod distclean; \
		fi

# -------------------------------------
snapshot:
	@if [ x"$(UNAME_N)" != x"pleiades" ]; then echo "Not authorized to advance snapshot"; exit 1; fi
	#如果两文件的十六进制不同，提示并退出
	@echo "[$(TAG)]" > RELNOTES.NEW
	#变量的内容覆盖定向
	@echo >>RELNOTES.NEW
	#重定向
	@git log --no-merges $(LASTTAG).. | git shortlog >> RELNOTES.NEW
	@echo >> RELNOTES.NEW
	@cat RELNOTES >> RELNOTES.NEW
	@mv RELNOTES.NEW RELNOTES
	@sed -e "s/^%define ssdate .*/%define ssdate $(DATE)/" iputils.spec > iputils.spec.tmp
	@mv iputils.spec.tmp iputils.spec
	@echo "static char SNAPSHOT[] = \"$(TAG)\";" > SNAPSHOT.h
	#将TAG变量中的内容以"static char SNAPSHOT[] = \"$(TAG)\"的形式重定向到SNAPSHOT.h文档中
	@$(MAKE) -C doc snapshot
	#doc文档生成
	@$(MAKE) man
	@git commit -a -m "iputils-$(TAG)"
	#提交修改
	@git tag -s -m "iputils-$(TAG)" $(TAG)
	#利用私钥进行署名
	@git archive --format=tar --prefix=iputils-$(TAG)/ $(TAG) | bzip2 -9 > ../iputils-$(TAG).tar.bz2
	

