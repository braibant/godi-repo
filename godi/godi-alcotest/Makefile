.include "../../mk/bsd.prefs.mk"

VERSION=	0.2.0
ONAME=		alcotest
PKG=		godi-${ONAME}
PKGNAME=	${PKG}-${VERSION}
PKGREVISION=	0
DISTNAME=	alcotest-0.2.0
DISTFILES=	alcotest-0.2.0.tar.gz
CATEGORIES=	godi
MASTER_SITES=	${MASTER_SITE_BACKUP}
HOMEPAGE=	https://github.com/samoht/alcotest/
COMMENT=	Alcotest is a lightweight and colourful test framework

DEPENDS+=  godi-cmdliner-*:../../godi/godi-cmdliner
DEPENDS+=  godi-re-*:../../godi/godi-re
DEPENDS+=  godi-ounit>=1.1.2:../../godi/godi-ounit
DEPENDS+=	godi-ocaml>=4.00.1:../../godi/godi-ocaml
BUILD_DEPENDS+= godi-findlib-*:../../godi/godi-findlib


WINOASIS=		yes



.include "../../mk/bsd.pkg.mk"
