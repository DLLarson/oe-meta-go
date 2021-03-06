def map_go_arch(a, d):
    import re

    if   re.match('^x86.64$', a):  return 'amd64'
    elif re.match('^i.86$', a):    return '386'
    elif re.match('^arm$', a):     return 'arm'
    elif re.match('^aarch64$', a): return 'arm64'
    else:
        bb.error("cannot map '%s' to a Go architecture" % a)

GOROOT_class-native = "${STAGING_LIBDIR_NATIVE}/go"
GOROOT = "${STAGING_LIBDIR_NATIVE}/${TARGET_SYS}/go"
GOBIN_FINAL_class-native = "${GOROOT_FINAL}/bin"
GOBIN_FINAL = "${GOROOT_FINAL}/bin/${GOOS}_${GOARCH}"

export GOOS = "linux"
export GOARCH = "${@map_go_arch(d.getVar('TARGET_ARCH', True), d)}"
export GOROOT
export GOROOT_FINAL = "${libdir}/${TARGET_SYS}/go"
export GOBIN_FINAL
export GOPKG_FINAL = "${GOROOT_FINAL}/pkg/${GOOS}_${GOARCH}"
export GOSRC_FINAL = "${GOROOT_FINAL}/src"
export GO_GCFLAGS = "${TARGET_CFLAGS}"
export GO_LDFLAGS = "${TARGET_LDFLAGS}"
export CGO_CFLAGS = "${TARGET_CC_ARCH}${TOOLCHAIN_OPTIONS} ${TARGET_CFLAGS}"
export CGO_CPPFLAGS = "${TARGET_CPPFLAGS}"
export CGO_CXXFLAGS = "${TARGET_CC_ARCH}${TOOLCHAIN_OPTIONS} ${TARGET_CXXFLAGS}"
export CGO_LDFLAGS = "${TARGET_CC_ARCH}${TOOLCHAIN_OPTIONS} ${TARGET_LDFLAGS}"

DEPENDS += "go-cross"
DEPENDS_class-native += "go-native"

INHIBIT_PACKAGE_STRIP = "1"

FILES_${PN}-staticdev += "${GOSRC_FINAL}/${GO_IMPORT}"
FILES_${PN}-staticdev += "${GOPKG_FINAL}/${GO_IMPORT}*"

GO_INSTALL ?= "${GO_IMPORT}/..."

do_go_compile() {
	GOPATH=${S}:${STAGING_LIBDIR}/${TARGET_SYS}/go go env
	if test -n "${GO_INSTALL}" ; then
		GOPATH=${S}:${STAGING_LIBDIR}/${TARGET_SYS}/go go install -v ${GO_INSTALL}
	fi
}

do_go_install() {
	rm -rf ${WORKDIR}/staging
	install -d ${WORKDIR}/staging${GOROOT_FINAL} ${D}${GOROOT_FINAL}
	tar -C ${S} -cf - . | tar -C ${WORKDIR}/staging${GOROOT_FINAL} -xpvf -

	find ${WORKDIR}/staging${GOROOT_FINAL} \( \
		-name \*.indirectionsymlink -o \
		-name .git\* -o                \
		-name .hg -o                   \
		-name .svn -o                  \
		-name .pc\* -o                 \
		-name patches\*                \
		\) -print0 | \
	xargs -r0 rm -rf

	tar -C ${WORKDIR}/staging${GOROOT_FINAL} -cf - . | \
	tar -C ${D}${GOROOT_FINAL} -xpvf -

	chown -R root:root "${D}${GOROOT_FINAL}"

	if test -e "${D}${GOBIN_FINAL}" ; then
		install -d -m 0755 "${D}${bindir}"
		find "${D}${GOBIN_FINAL}" ! -type d -print0 | xargs -r0 mv --target-directory="${D}${bindir}"
		rmdir -p "${D}${GOBIN_FINAL}" || true
	fi
}

do_compile() {
	do_go_compile
}

do_install() {
	do_go_install
}
