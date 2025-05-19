-- Update all budget entries to have amount of 0
UPDATE ZBUDGET SET ZAMOUNT = 0 WHERE ZID IS NOT NULL;

-- Verify the update
SELECT ZMONTH, ZYEAR, ZAMOUNT FROM ZBUDGET;

