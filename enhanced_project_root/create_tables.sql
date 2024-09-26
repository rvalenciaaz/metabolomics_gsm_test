-- create_tables.sql

-- Switch to the metabolic_db database
\c metabolic_db

-- Table to store exometabolomic data
CREATE TABLE exometabolomic_data (
    id SERIAL PRIMARY KEY,
    metabolite VARCHAR(255),
    concentration_start FLOAT,
    concentration_end FLOAT,
    time FLOAT,
    cell_density FLOAT,
    rate FLOAT,
    model_metabolite_id VARCHAR(255),
    batch_id INT
);

-- Table to store transcriptomic data
CREATE TABLE transcriptomic_data (
    id SERIAL PRIMARY KEY,
    gene_id VARCHAR(255),
    expression_value FLOAT,
    batch_id INT
);

-- Table to store metabolite mappings
CREATE TABLE metabolite_mappings (
    id SERIAL PRIMARY KEY,
    metabolite_name VARCHAR(255),
    smiles VARCHAR(255),
    model_metabolite_id VARCHAR(255)
);

-- Table to store gene mappings
CREATE TABLE gene_mappings (
    id SERIAL PRIMARY KEY,
    gene_id VARCHAR(255),
    go_terms TEXT
);

-- Table to store analysis results
CREATE TABLE analysis_results (
    id SERIAL PRIMARY KEY,
    objective_value FLOAT,
    fluxes JSONB,
    fva_results JSONB
);

-- Table to store phenotype data
CREATE TABLE phenotype_data (
    id SERIAL PRIMARY KEY,
    condition VARCHAR(255),
    growth_rate FLOAT,
    batch_id INT
);

-- Table to store cross-validation results
CREATE TABLE cross_validation_results (
    id SERIAL PRIMARY KEY,
    fold INT,
    accuracy FLOAT
);
