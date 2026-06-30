DROP TABLE IF EXISTS sap_vbap;
DROP TABLE IF EXISTS sap_vbak;
DROP TABLE IF EXISTS sap_kna1;
DROP TABLE IF EXISTS sap_mara;

CREATE TABLE sap_mara (
    mandt CHAR(3) NOT NULL,
    matnr VARCHAR(18) NOT NULL,
    mtart VARCHAR(4) NOT NULL,
    matkl VARCHAR(9) NOT NULL,
    meins VARCHAR(3) NOT NULL,
    ersda DATE NOT NULL,
    erdat DATE NOT NULL,
    aedat DATE NOT NULL,
    PRIMARY KEY (mandt, matnr)
);

CREATE TABLE sap_kna1 (
    mandt CHAR(3) NOT NULL,
    kunnr VARCHAR(10) NOT NULL,
    name1 VARCHAR(80) NOT NULL,
    land1 CHAR(2) NOT NULL,
    ort01 VARCHAR(40) NOT NULL,
    erdat DATE NOT NULL,
    aedat DATE NOT NULL,
    PRIMARY KEY (mandt, kunnr)
);

CREATE TABLE sap_vbak (
    mandt CHAR(3) NOT NULL,
    vbeln VARCHAR(10) NOT NULL,
    kunnr VARCHAR(10) NOT NULL,
    audat DATE NOT NULL,
    auart VARCHAR(4) NOT NULL,
    vkorg VARCHAR(4) NOT NULL,
    erdat DATE NOT NULL,
    aedat DATE NOT NULL,
    waers CHAR(3) NOT NULL,
    waerk CHAR(3) NOT NULL,
    netwr NUMERIC(15, 2) NOT NULL,
    PRIMARY KEY (mandt, vbeln)
);

CREATE TABLE sap_vbap (
    mandt CHAR(3) NOT NULL,
    vbeln VARCHAR(10) NOT NULL,
    posnr VARCHAR(6) NOT NULL,
    matnr VARCHAR(18) NOT NULL,
    kwmeng NUMERIC(13, 3) NOT NULL,
    vrkme VARCHAR(3) NOT NULL,
    waerk CHAR(3) NOT NULL,
    netwr NUMERIC(15, 2) NOT NULL,
    erdat DATE NOT NULL,
    aedat DATE NOT NULL,
    PRIMARY KEY (mandt, vbeln, posnr)
);
