.include "../../mk/bsd.prefs.mk"

VERSION=        1.17
MNODE=		1122
ONAME=		utop
PKG=		godi-${ONAME}
PKGNAME=        ${PKG}-${VERSION}
PKGREVISION=    0
DISTNAME=       utop-1.17
DISTFILES=      utop-1.17.tar.xz
CATEGORIES=     godi
MASTER_SITES=	${MASTER_SITE_BACKUP}
HOMEPAGE=       https://github.com/diml/utop
COMMENT=        improved toplevel for OCaml

DEPENDS+=  godi-react>=1.0.0:../../godi/godi-react
DEPENDS+=	godi-lwt-*:../../godi/godi-lwt
DEPENDS+= godi-ocaml>=3.12:../../godi/godi-ocaml
DEPENDS+= godi-lambda-term>=1.2:../../godi/godi-lambda-term
DEPENDS+= godi-findlib-*:../../godi/godi-findlib
BUILD_DEPENDS+= apps-cppo>=1.0.1:../../apps/apps-cppo

.if defined(W32PORT) && ${W32PORT} == "mingw"
INSTALL_SCRIPT_FILE=files/install
DEINSTALL_SCRIPT_FILE=files/deinstall
ADD_ENV=	${BUILD_ENV} GODI_PREFIX=${LOCALBASE}
DEPENDS+=	apps-console2>=0:../../apps/apps-console2
post-install:
	@${SETENV} ${ADD_ENV} bash files/install --add-links
.endif

CONFIGURE_ARGS+=	--enable-camlp4
WINOASIS=	yes

.include "../../mk/bsd.pkg.mk"

