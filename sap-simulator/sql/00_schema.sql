CREATE TABLE IF NOT EXISTS sap_mara (
    mandt CHAR(3) NOT NULL,
    matnr VARCHAR(18) NOT NULL,
    mtart VARCHAR(4) NOT NULL,
    matkl VARCHAR(9) NOT NULL,
    meins VARCHAR(3) NOT NULL,
    erdat DATE NOT NULL,
    aedat DATE NOT NULL,
    PRIMARY KEY (mandt, matnr)
);

CREATE TABLE IF NOT EXISTS sap_kna1 (
    mandt CHAR(3) NOT NULL,
    kunnr VARCHAR(10) NOT NULL,
    name1 VARCHAR(80) NOT NULL,
    land1 CHAR(2) NOT NULL,
    ort01 VARCHAR(40) NOT NULL,
    erdat DATE NOT NULL,
    aedat DATE NOT NULL,
    PRIMARY KEY (mandt, kunnr)
);

CREATE TABLE IF NOT EXISTS sap_vbak (
    mandt CHAR(3) NOT NULL,
    vbeln VARCHAR(10) NOT NULL,
    kunnr VARCHAR(10) NOT NULL,
    erdat DATE NOT NULL,
    aedat DATE NOT NULL,
    waers CHAR(3) NOT NULL,
    netwr NUMERIC(15, 2) NOT NULL,
    PRIMARY KEY (mandt, vbeln)
);

CREATE TABLE IF NOT EXISTS sap_vbap (
    mandt CHAR(3) NOT NULL,
    vbeln VARCHAR(10) NOT NULL,
    posnr VARCHAR(6) NOT NULL,
    matnr VARCHAR(18) NOT NULL,
    kwmeng NUMERIC(13, 3) NOT NULL,
    netwr NUMERIC(15, 2) NOT NULL,
    erdat DATE NOT NULL,
    aedat DATE NOT NULL,
    PRIMARY KEY (mandt, vbeln, posnr)
);
