UPDATE sap_vbak
SET netwr = 1299.00,
    aedat = DATE '2026-03-01'
WHERE mandt = '100'
  AND vbeln = '5000000001';

UPDATE sap_vbap
SET netwr = 599.00,
    aedat = DATE '2026-03-01'
WHERE mandt = '100'
  AND vbeln = '5000000001'
  AND posnr = '000020';

INSERT INTO sap_vbak (mandt, vbeln, kunnr, audat, auart, vkorg, erdat, aedat, waers, waerk, netwr) VALUES
('100', '5000000003', 'CUST000001', DATE '2026-03-02', 'OR', '1000', DATE '2026-03-02', DATE '2026-03-02', 'EUR', 'EUR', 420.00)
ON CONFLICT (mandt, vbeln) DO NOTHING;

INSERT INTO sap_vbap (mandt, vbeln, posnr, matnr, kwmeng, vrkme, waerk, netwr, erdat, aedat) VALUES
('100', '5000000003', '000010', 'MAT-000000000001', 6.000, 'EA', 'EUR', 420.00, DATE '2026-03-02', DATE '2026-03-02')
ON CONFLICT (mandt, vbeln, posnr) DO NOTHING;
