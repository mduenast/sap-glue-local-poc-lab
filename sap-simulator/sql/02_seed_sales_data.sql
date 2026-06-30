INSERT INTO sap_vbak (mandt, vbeln, kunnr, erdat, aedat, waers, netwr) VALUES
('100', '5000000001', 'CUST000001', DATE '2026-02-01', DATE '2026-02-01', 'EUR', 1200.00),
('100', '5000000002', 'CUST000002', DATE '2026-02-02', DATE '2026-02-02', 'EUR', 850.50)
ON CONFLICT (mandt, vbeln) DO UPDATE SET
    kunnr = EXCLUDED.kunnr,
    aedat = EXCLUDED.aedat,
    waers = EXCLUDED.waers,
    netwr = EXCLUDED.netwr;

INSERT INTO sap_vbap (mandt, vbeln, posnr, matnr, kwmeng, netwr, erdat, aedat) VALUES
('100', '5000000001', '000010', 'MAT-000000000001', 10.000, 700.00, DATE '2026-02-01', DATE '2026-02-01'),
('100', '5000000001', '000020', 'MAT-000000000002', 5.000, 500.00, DATE '2026-02-01', DATE '2026-02-01'),
('100', '5000000002', '000010', 'MAT-000000000003', 25.000, 850.50, DATE '2026-02-02', DATE '2026-02-02')
ON CONFLICT (mandt, vbeln, posnr) DO UPDATE SET
    matnr = EXCLUDED.matnr,
    kwmeng = EXCLUDED.kwmeng,
    netwr = EXCLUDED.netwr,
    aedat = EXCLUDED.aedat;
