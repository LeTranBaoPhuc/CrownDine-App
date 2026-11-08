-- Production only: disable unchanged public demo credentials from V1.
-- Accounts whose passwords have been changed are preserved. Development uses
-- a separate migration location and keeps the demo accounts for local testing.
UPDATE users SET status = 'INACTIVE'
WHERE (username = 'johndoe' AND password = '$2a$10$s3go5e.GYivSMmrJXG6jceddjfSAbg6O832Sip8XIVNRRLIjXNP6G')
 OR (username = 'alice' AND password = '$2a$10$EeSehs49igNMz6Vuk69cDuaAGHFrWSjeOvMmNkaAr6ZwyZtltKStS')
 OR (username = 'johncena' AND password = '$2a$10$llGgE5VlZzM0.pCzbOLGWev.cqdovrjSsq0lGM87wo0FVgATXsh12')
 OR (username = 'minhanh' AND password = '$2a$10$f8K0p/rAvE9SrsZcahthQuKA79pIAqGt9APO14f3.czxnCPp9q6Iu')
 OR (username = 'thutrang' AND password = '$2a$10$OEYH9he8BWJRnCytYVcmB.W4lk6WlwAHnAgVf9aQHZch5gJ.HUiAu')
 OR (username = 'quochuy' AND password = '$2a$10$2XGuYngpcuowaqhZbvTLGuhlNg5n3sn9GdbzQGyWcMvKm3G/FOZbS')
 OR (username = 'ngocmai' AND password = '$2a$10$gYToj5teNH/bDuMaboswr.RCWyw3mnhxVw7fXYTRDVoeh/qy5eVdm')
 OR (username = 'thanhtung' AND password = '$2a$10$XDav3qdVlNkr58OGZZVm7uGdQs4D9kAeqw555rq0lo6q6NG7EB87C')
 OR (username = 'baovy' AND password = '$2a$10$2/BYSYBiyru0TusrcILpHejPJXShhDUbLe4AhvAvX2Loy28hZuZzq')
 OR (username = 'hoangyen' AND password = '$2a$10$k0Pe70Q6Ng7btefKDxPI9.g6dS5L/078.eb9ykojULQHrhj6QrEaG')
 OR (username = 'ductri' AND password = '$2a$10$RQhy/.FDwnIHKS7vUx6gBeFviqoEEfPe8dAQowIlwhBwUoanbtKJ.')
 OR (username = 'kimngan' AND password = '$2a$10$/lnvxAHZOhbb0wjfK40LYeEyd.crr3ikTYemydilZW6JlTyDdOp9e')
 OR (username = 'annhi' AND password = '$2a$10$V53.Yc2EmYI0byjNWMYgoOAHUCRSQrQ0D5gbwu8Kau.E8j9ajjBGG')
 OR (username = 'nguyenkhoa' AND password = '$2a$10$n8Pl2zirf/Gca5l8aTKQbuEGfol/MzgtbtXXInKkINtYbn37OX0v6')
 OR (username = 'thuyduong' AND password = '$2a$10$qPuhubmfya.dzZPjN7n8C.e7XkwhZEIs2NWc9duaRhJehMeJxbyT2')
 OR (username = 'hoanglong' AND password = '$2a$10$xU6pg09xUTnIaiUY3EAGAO7DArkh0gGi7VXFIH7jomraEsOo4fp5q')
 OR (username = 'mylinh' AND password = '$2a$10$ER.uoSiYqEtSX.QmliHXHOMBFrCIGwYp6cgUxcgdAq7kSVgfZPohW')
 OR (username = 'quanghuy' AND password = '$2a$10$sCOOYR47CI8tKPz0hGRceusjfeNYVcxnRnTcKsWikFPmLPy0rYWXG')
 OR (username = 'diemmy' AND password = '$2a$10$ymkp.wkR2qE8V9nlgYNKQe6xfFEpvlNhO3hwhryYnsqii0pqAaMpC')
 OR (username = 'phuocan' AND password = '$2a$10$DFYEE5OIHU3QWgGaiWXt7OTV6zRtY.GDeq4zTnx3HtZdAeCK0KsCe')
 OR (username = 'tramlam' AND password = '$2a$10$YAuhlJBlUbowaD.GhtuG3u962klwTxWWcKLthL5Xk868LXyHPepty')
 OR (username = 'anhkiet' AND password = '$2a$10$1g8VX1G3WNLT.iei7k2.IeWfAQcajgeWqfL95.4Y4KO8AXMONbzW2')
 OR (username = 'thanhha' AND password = '$2a$10$dZr/DYrilsusmew//sI45OQp0/CS.M10j82gkgVa8TdHMFTGhoKqq');
UPDATE tokens t JOIN users u ON u.username = t.username SET t.is_revoked = TRUE WHERE u.status = 'INACTIVE';
