-- Migration: Fix Account Types to match AccountType enum
-- Version: 004
-- Date: 2026-08-21
-- Fix C1: Align account types with lib/core/enums/account_type.dart
-- assets=0, liabilities=1, equity=2, revenue=3, expenses=4

-- Fix assets: type 1 -> 0 (where c_id 1000..1150, 1170,1180)
UPDATE accounts SET type = 0 WHERE c_id IN (1000, 1110, 1120, 1130, 1140, 1150, 1170, 1180) AND type = 1;

-- Fix liabilities+equity master: ensure correct split
-- liabilities should be 1, equity 2
UPDATE accounts SET type = 1 WHERE c_id IN (2000, 2110, 2130, 2140, 2160, 2170) AND type = 2;
-- Keep capital (2120) as equity type 2 - no change needed (already 2)
-- But if previously liabilities master was 2, set to 1
UPDATE accounts SET type = 2 WHERE c_id = 2120 AND type != 2;

-- Fix expenses: type 3 -> 4
UPDATE accounts SET type = 4 WHERE c_id IN (3000, 3110, 3120, 3130, 3140, 3150, 3160, 3170, 3180, 3190, 5200) AND type = 3;

-- Fix revenues: type 4 -> 3
UPDATE accounts SET type = 3 WHERE c_id IN (4000, 4110, 4120, 4130, 4140, 4150, 4160, 4200) AND type = 4;

-- Safety: ensure any remaining mismatched by code prefix
-- Code starting with 1 should be asset type 0
UPDATE accounts SET type = 0 WHERE code LIKE '1%' AND type NOT IN (0) AND is_master = 0 AND type IN (1,2,3,4) AND c_id NOT IN (1170,1180);
-- Code starting with 2 liabilities should be 1, equity-like (rأس المال) stays 2
-- We don't auto-migrate all code 2% to avoid overriding equity; handle via c_id already

-- Code 3% should be expenses type 4
UPDATE accounts SET type = 4 WHERE (code LIKE '3%' OR code LIKE '30%' OR code LIKE '31%') AND type = 3;
-- Code 4% should be revenue type 3
UPDATE accounts SET type = 3 WHERE code LIKE '4%' AND type = 4;

-- Verification log
-- SELECT c_id, code, name, type FROM accounts ORDER BY c_id;
