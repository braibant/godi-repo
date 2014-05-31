diff -urN jasper-1.900.1/src/libjasper/jpc/jpc_dec.c jasper-1.900.1-fix/src/libjasper/jpc/jpc_dec.c
--- src/libjasper/jpc/jpc_dec.c	2007-01-19 14:43:07.000000000 -0700
+++ src/libjasper/jpc/jpc_dec.c	2008-03-06 16:51:12.000000000 -0700
@@ -1069,12 +1069,12 @@
 	/* Apply an inverse intercomponent transform if necessary. */
 	switch (tile->cp->mctid) {
 	case JPC_MCT_RCT:
-		assert(dec->numcomps == 3);
+		assert(dec->numcomps >= 3);
 		jpc_irct(tile->tcomps[0].data, tile->tcomps[1].data,
 		  tile->tcomps[2].data);
 		break;
 	case JPC_MCT_ICT:
-		assert(dec->numcomps == 3);
+		assert(dec->numcomps >= 3);
 		jpc_iict(tile->tcomps[0].data, tile->tcomps[1].data,
 		  tile->tcomps[2].data);
 		break;
