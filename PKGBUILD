# vim:set ft=sh:
# Maintainer: BlackEagle < ike DOT devolder AT gmail DOT com >
# Contributor: Tobias Powalowski <tpowa@archlinux.org>
# Contributor: Thomas Baechler <thomas@archlinux.org>

_kernelname=-grsrv
pkgbase="linux$_kernelname"
pkgname=("linux$_kernelname" "linux$_kernelname-headers")
_basekernel=4.2
_patchver=3
pkgver=$_basekernel
pkgrel=2
arch=('i686' 'x86_64')
license=('GPL2')
makedepends=('bc' 'kmod')
url="http://www.kernel.org"
options=(!strip)

validpgpkeys=(
	'ABAF11C65A2970B130ABE3C479BE3E4300411886'
	'647F28654894E3BD457199BE38DBBDC86092693E'
	'DE9452CE46F42094907F108B44D1C0F82525FE49'
)

source=(
	"https://www.kernel.org/pub/linux/kernel/v4.x/linux-${_basekernel}.tar.xz"
	"https://www.kernel.org/pub/linux/kernel/v4.x/linux-${_basekernel}.tar.sign"
	# the main kernel config files
	"config-server.i686"
	"config-server.x86_64"
	# standard config files for mkinitcpio ramdisk
	"linux$_kernelname.preset"
)
sha256sums=(
	'cf20e044f17588d2a42c8f2a450b0fd84dfdbd579b489d93e9ab7d0e8b45dbeb'
	'SKIP'
    '7f30918ab93836e6c6d0694119763f73ec6755f0aacb0d6eee4c27845b16cb9e'
    '94e8bdb8b1d530e9f795f7e12e59164f33f23fefe61ff3c527dc13baab69b80e'
	'64b2cf77834533ae7bac0c71936087857d8787d0e2a349037795eb7e42d23dde'
)

# revision patches
if [ ${_patchver} -ne 0 ]; then
	pkgver=$_basekernel.$_patchver
	_patchname="patch-$pkgver"
	source=( "${source[@]}"
		"https://www.kernel.org/pub/linux/kernel/v4.x/${_patchname}.xz"
		"https://www.kernel.org/pub/linux/kernel/v4.x/${_patchname}.sign"
	)
	sha256sums=( "${sha256sums[@]}"
        'e0e066f3fc5f310644e9f3f3ede47db7ac040f44782f0a5cf75ce2c940444972'
		'SKIP'
	)
fi

_grsecver="3.1"
_grsecdate="201510111839"

# extra patches
_extrapatches=(
	"http://grsecurity.net/test/grsecurity-$_grsecver-$pkgver-$_grsecdate.patch"
	"http://grsecurity.net/test/grsecurity-$_grsecver-$pkgver-$_grsecdate.patch.sig"
)
_extrapatchessums=(
    'ee6863df516814d7422d5dc16115a019bf9fdf338338acdd1a9e10f4b9fbf043'
	'SKIP'
)
if [ ${#_extrapatches[@]} -ne 0 ]; then
	source=( "${source[@]}"
		"${_extrapatches[@]}"
	)
	sha256sums=( "${sha256sums[@]}"
		"${_extrapatchessums[@]}"
	)
fi

prepare() {
	cd "$srcdir/linux-$_basekernel"
	# Add revision patches
	if [ $_patchver -ne 0 ]; then
		msg2 "apply $_patchname"
		patch -Np1 -i "$srcdir/$_patchname"
	fi

	# extra patches
	for patch in ${_extrapatches[@]}; do
		patch="$(basename "$patch" | sed -e 's/\.\(gz\|bz2\|xz\)//')"
		pext=${patch##*.}
		if [[ "$pext" == 'patch' ]] || [[ "$pext" == 'diff' ]]; then
			msg2 "apply $patch"
			patch -Np1 -i "$srcdir/$patch"
		fi
	done

	# set configuration
	msg2 "copy configuration"
	if [ "$CARCH" = "x86_64" ]; then
		cat "$srcdir/config-server.x86_64" >./.config
	else
		cat "$srcdir/config-server.i686" >./.config
	fi
	if [ "$_kernelname" != "" ]; then
		sed -i "s|CONFIG_LOCALVERSION=.*|CONFIG_LOCALVERSION=\"\U$_kernelname\"|g" ./.config
	fi

	# remove sublevel, this is a server version, needs to be updateable
	# without rebooting all the time
	#msg2 "remove sublevel"
	#sed -e "s|SUBLEVEL = .*|SUBLEVEL = |g" -i Makefile

	# set extraversion to pkgrel
	msg2 "set extraversion to $pkgrel"
	sed -ri "s|^(EXTRAVERSION =).*|\1 -$pkgrel|" Makefile

	# don't run depmod on 'make install'. We'll do this ourselves in packaging
	sed -i '2iexit 0' scripts/depmod.sh

	# hack to prevent output kernel from being marked as dirty or git
	msg2 "apply hack to prevent kernel tree being marked dirty"
	echo "" > "$srcdir/linux-$_basekernel/.scmversion"

	msg2 "empty -grsec localversion"
	echo "" > "$srcdir/linux-$_basekernel/localversion-grsec"

}

build() {
	cd "$srcdir/linux-$_basekernel"

	# get kernel version
	msg2 "prepare"
	make prepare
	# load configuration
	# Configure the kernel. Replace the line below with one of your choice.
    #make menuconfig # CLI menu for configuration
	#make xconfig # X-based configuration
	#make oldconfig # using old config from previous kernel version
	# ... or manually edit .config
	####################
	# stop here
	# this is useful to configure the kernel
    #msg "Stopping build"
    #return 1
	####################
	# yes "" | make config
	# build!
	msg2 "build"
	make $MAKEFLAGS bzImage modules
}

package_linux-grsrv() {
	pkgdesc="The Linux Kernel and modules, Grsecurity Server Edition"
	provides=('linux')
	backup=(
		"etc/mkinitcpio.d/$pkgname.preset"
	)
	depends=('coreutils' 'kmod>=10' 'mkinitcpio>=0.9')
	optdepends=(
		'crda: to set the correct wireless channels of your country'
		'linux-firmware: when having some hardware needing special firmware'
		'paxd: automatically configure PAX exceptions'
	)
	install=$pkgname.install

	KARCH=x86
	cd "$srcdir/linux-$_basekernel"

	mkdir -p "$pkgdir"/{lib/modules,lib/firmware,boot,usr}

	# get kernel version
	_kernver=$(make kernelrelease)

	# install modules
	make INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH="$pkgdir" modules_install

	# copy System.map and bzImage
	install -m644 System.map "$pkgdir/boot/System.map$_kernelname"
	install -m644 arch/$KARCH/boot/bzImage "$pkgdir/boot/vmlinuz$_kernelname"

	# install fallback mkinitcpio.conf file and preset file for kernel
	install -m644 -D "$srcdir/$pkgname.preset" "$pkgdir/etc/mkinitcpio.d/$pkgname.preset"

	# set correct depmod command for install
	sed \
		-e  "s/KERNEL_NAME=.*/KERNEL_NAME=$_kernelname/g" \
		-e  "s/KERNEL_VERSION=.*/KERNEL_VERSION=$_kernver/g" \
		-i "$startdir/$pkgname.install"
	sed \
		-e "s|source .*|source /etc/mkinitcpio.d/$pkgname.kver|g" \
		-e "s|default_image=.*|default_image=\"/boot/initramfs$_kernelname.img\"|g" \
		-e "s|fallback_image=.*|fallback_image=\"/boot/initramfs$_kernelname-fallback.img\"|g" \
		-i "$pkgdir/etc/mkinitcpio.d/$pkgname.preset"

	echo -e "# DO NOT EDIT THIS FILE\nALL_kver='$_kernver'" > "$pkgdir/etc/mkinitcpio.d/$pkgname.kver"

	# remove build and source links
	rm -f "$pkgdir/lib/modules/$_kernver"/{source,build}

	# remove the firmware
	rm -rf "$pkgdir/lib/firmware"

	_fldkernelname=$(echo $_kernelname | tr "[:lower:]" "[:upper:]")
	# make room for external modules
	ln -s "../${_basekernel}$_fldkernelname-external" "$pkgdir/lib/modules/$_kernver/external"
	# add real version for building modules and running depmod from post_install/upgrade
	mkdir -p "$pkgdir/lib/modules/$_basekernel$_fldkernelname-external"
	echo "$_kernver" > "$pkgdir/lib/modules/${_basekernel}$_fldkernelname-external/version"

	# gzip all modules
	find "$pkgdir" -name '*.ko' -exec gzip -9 {}  \;

	# Now we call depmod...
	depmod -b "$pkgdir" -F System.map "$_kernver"

	# move module tree /lib -> /usr/lib
	mv "$pkgdir/lib" "$pkgdir/usr/"
}

package_linux-grsrv-headers() {
	pkgdesc="Header files and scripts for building modules for linux$_kernelname"
	provides=('linux-headers')
	install -dm755 "$pkgdir/usr/lib/modules/$_kernver"
	cd "$pkgdir/usr/lib/modules/$_kernver"
	ln -sf ../../../src/linux-$_kernver build
	cd "$srcdir/linux-$_basekernel"
	install -D -m644 Makefile \
		"$pkgdir/usr/src/linux-$_kernver/Makefile"
	install -D -m644 kernel/Makefile \
		"$pkgdir/usr/src/linux-$_kernver/kernel/Makefile"
	install -D -m644 .config \
		"$pkgdir/usr/src/linux-$_kernver/.config"

	# copy files necessary for later builds, like nvidia and vmware
	cp Module.symvers "$pkgdir/usr/src/linux-$_kernver"
	cp -a scripts "$pkgdir/usr/src/linux-$_kernver"
	# fix permissions on scripts dir
	chmod og-w -R "$pkgdir/usr/src/linux-$_kernver/scripts"
	mkdir -p "$pkgdir/usr/src/linux-$_kernver/.tmp_versions"

	mkdir -p "$pkgdir/usr/src/linux-$_kernver/arch/$KARCH/kernel"

	cp arch/$KARCH/Makefile "$pkgdir/usr/src/linux-$_kernver/arch/$KARCH/"
	if [ "$CARCH" = "i686" ]; then
		cp arch/$KARCH/Makefile_32.cpu "$pkgdir/usr/src/linux-$_kernver/arch/$KARCH/"
	fi
	cp arch/$KARCH/kernel/asm-offsets.s "$pkgdir/usr/src/linux-$_kernver/arch/$KARCH/kernel/"

	# add docbook makefile
	install -D -m644 Documentation/DocBook/Makefile \
		"$pkgdir/usr/src/linux-$_kernver/Documentation/DocBook/Makefile"

	# add config
	for config in `find ./include/config -size +1c -type f`; do
		mkdir -p "$pkgdir/usr/src/linux-$_kernver/$(dirname $config)"
		cp -a $config "$pkgdir/usr/src/linux-$_kernver/$(dirname $config)"
	done

	# add headers
	for header in `find -size +1c -name '*.h'`; do
		mkdir -p "$pkgdir/usr/src/linux-$_kernver/$(dirname $header)"
		cp -a $header "$pkgdir/usr/src/linux-$_kernver/$(dirname $header)"
	done

	# copy in Kconfig files
	for i in `find . -name "Kconfig*"`; do
		mkdir -p "$pkgdir/usr/src/linux-$_kernver/$(echo $i | sed 's|/Kconfig.*||')"
		cp $i "$pkgdir/usr/src/linux-$_kernver/$i"
	done

	# strip scripts directory
	find "$pkgdir/usr/src/linux-$_kernver/scripts" -type f -perm -u+w 2>/dev/null | while read binary ; do
		case "$(file -bi "$binary")" in
			*application/x-sharedlib*) # Libraries (.so)
				/usr/bin/strip $STRIP_SHARED "$binary"
			;;
			*application/x-archive*) # Libraries (.a)
				/usr/bin/strip $STRIP_STATIC "$binary"
			;;
			*application/x-executable*) # Binaries
				/usr/bin/strip $STRIP_BINARIES "$binary"
			;;
		esac
	done

	chown -R root:root "$pkgdir/usr/src/linux-$_kernver"
	find "$pkgdir/usr/src/linux-$_kernver" -type d -exec chmod 755 {} \;
	# remove unneeded architectures
	rm -rf "$pkgdir/usr/src/linux-$_kernver/arch"/{alpha,arm,arm26,avr32,blackfin,cris,frv,h8300,ia64,m32r,m68k,m68knommu,mips,microblaze,mn10300,parisc,powerpc,ppc,s390,score,sh,sh64,sparc,sparc64,tile,um,v850,xtensa}
}
