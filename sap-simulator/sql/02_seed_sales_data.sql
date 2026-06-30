INSERT INTO sap_vbak (mandt, vbeln, kunnr, audat, auart, vkorg, erdat, aedat, waers, waerk, netwr) VALUES
('100', '5000000001', 'CUST000001', DATE '2026-02-01', 'OR', '1000', DATE '2026-02-01', DATE '2026-02-01', 'EUR', 'EUR', 1200.00),
('100', '5000000002', 'CUST000002', DATE '2026-02-02', 'OR', '2000', DATE '2026-02-02', DATE '2026-02-02', 'EUR', 'EUR', 850.50)
ON CONFLICT (mandt, vbeln) DO UPDATE SET
    kunnr = EXCLUDED.kunnr,
    audat = EXCLUDED.audat,
    auart = EXCLUDED.auart,
    vkorg = EXCLUDED.vkorg,
    erdat = EXCLUDED.erdat,
    aedat = EXCLUDED.aedat,
    waers = EXCLUDED.waers,
    waerk = EXCLUDED.waerk,
    netwr = EXCLUDED.netwr;

INSERT INTO sap_vbap (mandt, vbeln, posnr, matnr, kwmeng, vrkme, waerk, netwr, erdat, aedat) VALUES
('100', '5000000001', '000010', 'MAT-000000000001', 10.000, 'EA', 'EUR', 700.00, DATE '2026-02-01', DATE '2026-02-01'),
('100', '5000000001', '000020', 'MAT-000000000002', 5.000, 'EA', 'EUR', 500.00, DATE '2026-02-01', DATE '2026-02-01'),
('100', '5000000002', '000010', 'MAT-000000000003', 25.000, 'KG', 'EUR', 850.50, DATE '2026-02-02', DATE '2026-02-02')
ON CONFLICT (mandt, vbeln, posnr) DO UPDATE SET
    matnr = EXCLUDED.matnr,
    kwmeng = EXCLUDED.kwmeng,
    vrkme = EXCLUDED.vrkme,
    waerk = EXCLUDED.waerk,
    netwr = EXCLUDED.netwr,
    erdat = EXCLUDED.erdat,
    aedat = EXCLUDED.aedat;
