INSERT INTO sap_mara (mandt, matnr, mtart, matkl, meins, ersda, erdat, aedat) VALUES
('100', 'MAT-000000000001', 'FERT', 'LAB-GRP01', 'EA', DATE '2026-01-02', DATE '2026-01-02', DATE '2026-01-02'),
('100', 'MAT-000000000002', 'HALB', 'LAB-GRP01', 'EA', DATE '2026-01-03', DATE '2026-01-03', DATE '2026-01-03'),
('100', 'MAT-000000000003', 'ROH',  'LAB-GRP02', 'KG', DATE '2026-01-04', DATE '2026-01-04', DATE '2026-01-04')
ON CONFLICT (mandt, matnr) DO UPDATE SET
    mtart = EXCLUDED.mtart,
    matkl = EXCLUDED.matkl,
    meins = EXCLUDED.meins,
    ersda = EXCLUDED.ersda,
    erdat = EXCLUDED.erdat,
    aedat = EXCLUDED.aedat;

INSERT INTO sap_kna1 (mandt, kunnr, name1, land1, ort01, erdat, aedat) VALUES
('100', 'CUST000001', 'Example Retail One', 'ES', 'Madrid', DATE '2026-01-05', DATE '2026-01-05'),
('100', 'CUST000002', 'Example Wholesale Two', 'FR', 'Lyon', DATE '2026-01-06', DATE '2026-01-06')
ON CONFLICT (mandt, kunnr) DO UPDATE SET
    name1 = EXCLUDED.name1,
    land1 = EXCLUDED.land1,
    ort01 = EXCLUDED.ort01,
    erdat = EXCLUDED.erdat,
    aedat = EXCLUDED.aedat;
