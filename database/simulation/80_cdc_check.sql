-- Quick check of publications
\c mosip_master 
SELECT pubname, puballtables, pubinsert, pubupdate, pubdelete FROM pg_publication WHERE pubname LIKE 'dbz%';

\c mosip_regprc 
SELECT pubname, puballtables, pubinsert, pubupdate, pubdelete FROM pg_publication WHERE pubname LIKE 'dbz%';

\c mosip_ida 
SELECT pubname, puballtables, pubinsert, pubupdate, pubdelete FROM pg_publication WHERE pubname LIKE 'dbz%';


