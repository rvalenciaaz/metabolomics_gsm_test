#!/bin/bash

# Set the project root directory
PROJECT_ROOT="enhanced_project_root"

# Create the directory structure
mkdir -p $PROJECT_ROOT/{airflow/{dags,tasks},data,output,logs}

# Navigate to the project root directory
cd $PROJECT_ROOT

# Create empty data files (replace these with your actual data files)
touch data/{exometabolomic_data.csv,transcriptomic_counts.csv,your_model.xml,thermo_data.tsv,phenotype_data.csv}

# Create the database scripts
cat <<EOL > create_tables.sql
-- create_tables.sql

-- Switch to the metabolic_db database
\\c metabolic_db

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
EOL

cat <<EOL > create_tables.py
# create_tables.py

from db import engine
from models import Base

Base.metadata.create_all(engine)
EOL

# Create the database connection script (db.py)
cat <<EOL > db.py
# db.py

import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URI = os.getenv('DATABASE_URI', 'postgresql+psycopg2://metabolic_user:your_password@localhost:5432/metabolic_db')

engine = create_engine(DATABASE_URI)
Session = sessionmaker(bind=engine)
session = Session()
EOL

# Create the ORM models script (models.py)
cat <<EOL > models.py
# models.py

from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, Integer, String, Float, Text
from sqlalchemy.dialects.postgresql import JSONB

Base = declarative_base()

class ExometabolomicData(Base):
    __tablename__ = 'exometabolomic_data'
    id = Column(Integer, primary_key=True)
    metabolite = Column(String)
    concentration_start = Column(Float)
    concentration_end = Column(Float)
    time = Column(Float)
    cell_density = Column(Float)
    rate = Column(Float)
    model_metabolite_id = Column(String)
    batch_id = Column(Integer)

class TranscriptomicData(Base):
    __tablename__ = 'transcriptomic_data'
    id = Column(Integer, primary_key=True)
    gene_id = Column(String)
    expression_value = Column(Float)
    batch_id = Column(Integer)

class MetaboliteMapping(Base):
    __tablename__ = 'metabolite_mappings'
    id = Column(Integer, primary_key=True)
    metabolite_name = Column(String)
    smiles = Column(String)
    model_metabolite_id = Column(String)

class GeneMapping(Base):
    __tablename__ = 'gene_mappings'
    id = Column(Integer, primary_key=True)
    gene_id = Column(String)
    go_terms = Column(Text)

class AnalysisResults(Base):
    __tablename__ = 'analysis_results'
    id = Column(Integer, primary_key=True)
    objective_value = Column(Float)
    fluxes = Column(JSONB)
    fva_results = Column(JSONB)

class PhenotypeData(Base):
    __tablename__ = 'phenotype_data'
    id = Column(Integer, primary_key=True)
    condition = Column(String)
    growth_rate = Column(Float)
    batch_id = Column(Integer)

class CrossValidationResults(Base):
    __tablename__ = 'cross_validation_results'
    id = Column(Integer, primary_key=True)
    fold = Column(Integer)
    accuracy = Column(Float)
EOL

# Create the utility functions script (utils.py)
cat <<EOL > utils.py
# utils.py

import requests

def map_metabolite(metabolite_name):
    """
    Map metabolite names to model metabolite IDs using external databases.
    """
    # Implement actual mapping logic using APIs like HMDB, KEGG, or MetaNetX
    # Placeholder implementation
    model_metabolite_id = 'MNXM' + metabolite_name.replace(' ', '_')
    return model_metabolite_id

def get_go_terms(gene_id):
    """
    Retrieve GO terms for a given gene ID using UniProt API.
    """
    # Implement actual retrieval logic using UniProt or BioMart APIs
    # Placeholder implementation
    go_terms = ['GO:0008150']  # Biological Process
    return go_terms

def correct_metabolite_leakage(concentration_series):
    """
    Correct metabolite leakage in exometabolomic data.
    """
    # Implement leakage correction algorithm
    corrected_concentration = concentration_series  # Placeholder
    return corrected_concentration
EOL

# Create the Airflow DAG script
mkdir -p airflow/dags
cat <<EOL > airflow/dags/metabolic_workflow_dag.py
# metabolic_workflow_dag.py

from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from datetime import datetime, timedelta

# Import task functions
from tasks.preprocess_exometabolomic_data import preprocess_exometabolomic_data
from tasks.preprocess_transcriptomic_data import preprocess_transcriptomic_data
from tasks.map_metabolites import map_metabolites
from tasks.map_genes_and_reactions import map_genes_and_reactions
from tasks.integrate_data_into_model import integrate_data_into_model
from tasks.integrate_with_PROM import integrate_with_PROM
from tasks.add_thermodynamic_constraints import add_thermodynamic_constraints
from tasks.validate_and_analyze_model import validate_and_analyze_model
from tasks.validate_with_phenotypic_data import validate_with_phenotypic_data
from tasks.perform_cross_validation import perform_cross_validation
from tasks.visualize_and_report import visualize_and_report

# Default arguments for the DAG
default_args = {
    'owner': 'your_name',
    'depends_on_past': False,
    'email': ['your_email@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Define the DAG
dag = DAG(
    'metabolic_workflow',
    default_args=default_args,
    description='Enhanced workflow for metabolic model integration using Airflow',
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
)

# Define tasks
preprocess_exo_task = PythonOperator(
    task_id='preprocess_exometabolomic_data',
    python_callable=preprocess_exometabolomic_data,
    dag=dag,
)

preprocess_transcript_task = PythonOperator(
    task_id='preprocess_transcriptomic_data',
    python_callable=preprocess_transcriptomic_data,
    dag=dag,
)

map_metabolites_task = PythonOperator(
    task_id='map_metabolites',
    python_callable=map_metabolites,
    dag=dag,
)

map_genes_task = PythonOperator(
    task_id='map_genes_and_reactions',
    python_callable=map_genes_and_reactions,
    dag=dag,
)

integrate_data_task = PythonOperator(
    task_id='integrate_data_into_model',
    python_callable=integrate_data_into_model,
    op_kwargs={'algorithm': 'init'},  # You can specify 'fastcore' or other algorithms
    dag=dag,
)

integrate_PROM_task = PythonOperator(
    task_id='integrate_with_PROM',
    python_callable=integrate_with_PROM,
    dag=dag,
)

add_thermo_constraints_task = PythonOperator(
    task_id='add_thermodynamic_constraints',
    python_callable=add_thermodynamic_constraints,
    dag=dag,
)

validate_analyze_task = PythonOperator(
    task_id='validate_and_analyze_model',
    python_callable=validate_and_analyze_model,
    dag=dag,
)

validate_phenotype_task = PythonOperator(
    task_id='validate_with_phenotypic_data',
    python_callable=validate_with_phenotypic_data,
    dag=dag,
)

cross_validation_task = PythonOperator(
    task_id='perform_cross_validation',
    python_callable=perform_cross_validation,
    dag=dag,
)

visualize_report_task = PythonOperator(
    task_id='visualize_and_report',
    python_callable=visualize_and_report,
    dag=dag,
)

# Set task dependencies
preprocess_exo_task >> preprocess_transcript_task >> map_metabolites_task >> map_genes_task >> integrate_data_task >> integrate_PROM_task >> add_thermo_constraints_task >> validate_analyze_task >> [validate_phenotype_task, cross_validation_task] >> visualize_report_task
EOL

# Create the task scripts
mkdir -p airflow/tasks

# Task 1: Preprocess Exometabolomic Data
cat <<EOL > airflow/tasks/preprocess_exometabolomic_data.py
# tasks/preprocess_exometabolomic_data.py

def preprocess_exometabolomic_data(**kwargs):
    import pandas as pd
    from db import session
    from models import ExometabolomicData
    from utils import correct_metabolite_leakage

    # Load raw data
    exo_data = pd.read_csv('data/exometabolomic_data.csv')

    # Normalize concentrations
    exo_data['Normalized_Concentration_Start'] = exo_data['Concentration_Start'] / exo_data['Cell_Density']
    exo_data['Normalized_Concentration_End'] = exo_data['Concentration_End'] / exo_data['Cell_Density']

    # Correct for metabolite leakage
    exo_data['Corrected_Concentration_Start'] = correct_metabolite_leakage(exo_data['Normalized_Concentration_Start'])
    exo_data['Corrected_Concentration_End'] = correct_metabolite_leakage(exo_data['Normalized_Concentration_End'])

    # Recalculate rates using corrected concentrations
    exo_data['Rate'] = (exo_data['Corrected_Concentration_End'] - exo_data['Corrected_Concentration_Start']) / exo_data['Time']

    # Insert processed data into the database
    for _, row in exo_data.iterrows():
        data_entry = ExometabolomicData(
            metabolite=row['Metabolite'],
            concentration_start=row['Concentration_Start'],
            concentration_end=row['Concentration_End'],
            time=row['Time'],
            cell_density=row['Cell_Density'],
            rate=row['Rate'],
            batch_id=row.get('Batch_ID', None)
        )
        session.add(data_entry)
    session.commit()
EOL

# Task 2: Preprocess Transcriptomic Data
cat <<EOL > airflow/tasks/preprocess_transcriptomic_data.py
# tasks/preprocess_transcriptomic_data.py

def preprocess_transcriptomic_data(**kwargs):
    import pandas as pd
    from db import session
    from models import TranscriptomicData
    import rpy2.robjects as ro
    from rpy2.robjects import pandas2ri

    pandas2ri.activate()

    # Load raw count data
    transcript_data = pd.read_csv('data/transcriptomic_counts.csv')

    # Advanced normalization using DESeq2
    ro.r('''
    library(DESeq2)
    normalize_counts <- function(count_data) {
        dds <- DESeqDataSetFromMatrix(countData = count_data, colData = data.frame(row.names=colnames(count_data)), design = ~ 1)
        dds <- estimateSizeFactors(dds)
        normalized_counts <- counts(dds, normalized=TRUE)
        return(normalized_counts)
    }
    ''')

    r_counts = pandas2ri.py2rpy(transcript_data.set_index('Gene_ID'))
    normalized_counts = ro.r['normalize_counts'](r_counts)
    normalized_counts_df = pandas2ri.rpy2py(normalized_counts)

    # Convert back to pandas DataFrame
    normalized_counts_df = pd.DataFrame(normalized_counts_df, index=transcript_data['Gene_ID'])
    normalized_counts_df.reset_index(inplace=True)
    normalized_counts_df.rename(columns={'index': 'Gene_ID'}, inplace=True)

    # Insert processed data into the database
    for _, row in normalized_counts_df.iterrows():
        data_entry = TranscriptomicData(
            gene_id=row['Gene_ID'],
            expression_value=row.iloc[1],  # Adjust index as necessary
            batch_id=row.get('Batch_ID', None)
        )
        session.add(data_entry)
    session.commit()
EOL

# Task 3: Map Metabolites
cat <<EOL > airflow/tasks/map_metabolites.py
# tasks/map_metabolites.py

def map_metabolites(**kwargs):
    from db import session
    from models import ExometabolomicData, MetaboliteMapping
    from utils import map_metabolite

    exo_data = session.query(ExometabolomicData).all()

    for data_entry in exo_data:
        model_metabolite_id = map_metabolite(data_entry.metabolite)
        data_entry.model_metabolite_id = model_metabolite_id

        mapping = session.query(MetaboliteMapping).filter_by(metabolite_name=data_entry.metabolite).first()
        if not mapping:
            mapping = MetaboliteMapping(
                metabolite_name=data_entry.metabolite,
                model_metabolite_id=model_metabolite_id
            )
            session.add(mapping)
    session.commit()
EOL

# Task 4: Map Genes and Reactions
cat <<EOL > airflow/tasks/map_genes_and_reactions.py
# tasks/map_genes_and_reactions.py

def map_genes_and_reactions(**kwargs):
    from db import session
    from models import TranscriptomicData, GeneMapping
    from utils import get_go_terms

    transcript_data = session.query(TranscriptomicData).all()

    for data_entry in transcript_data:
        go_terms = get_go_terms(data_entry.gene_id)

        mapping = session.query(GeneMapping).filter_by(gene_id=data_entry.gene_id).first()
        if not mapping:
            mapping = GeneMapping(
                gene_id=data_entry.gene_id,
                go_terms=','.join(go_terms)
            )
            session.add(mapping)
    session.commit()
EOL

# Task 5: Integrate Data into the Model
cat <<EOL > airflow/tasks/integrate_data_into_model.py
# tasks/integrate_data_into_model.py

def integrate_data_into_model(**kwargs):
    from db import session
    from models import ExometabolomicData, TranscriptomicData
    import cobra
    import pandas as pd
    from cobra.flux_analysis import create_tissue_specific_model

    # Load the metabolic model
    model = cobra.io.read_sbml_model('data/your_model.xml')

    # Fetch data from the database
    exo_data_entries = session.query(ExometabolomicData).all()
    transcript_data_entries = session.query(TranscriptomicData).all()

    # Create DataFrames
    exo_data = pd.DataFrame([{
        'model_metabolite_id': entry.model_metabolite_id,
        'rate': entry.rate
    } for entry in exo_data_entries])

    transcript_data = pd.DataFrame([{
        'gene_id': entry.gene_id,
        'expression_value': entry.expression_value
    } for entry in transcript_data_entries])

    # Constrain exchange reactions
    for _, row in exo_data.iterrows():
        metabolite_id = row['model_metabolite_id']
        rate = row['rate']
        exchange_reaction_id = f'EX_{metabolite_id}'
        if exchange_reaction_id in model.reactions:
            exchange_reaction = model.reactions.get_by_id(exchange_reaction_id)
            if rate < 0:
                exchange_reaction.lower_bound = rate
            else:
                exchange_reaction.upper_bound = rate

    # Map gene expression to reactions
    reaction_expression = {}
    for reaction in model.reactions:
        genes = [gene.id for gene in reaction.genes]
        if genes:
            expr_values = transcript_data.loc[transcript_data['gene_id'].isin(genes), 'expression_value']
            if not expr_values.empty:
                reaction_expression[reaction.id] = expr_values.mean()
            else:
                reaction_expression[reaction.id] = 0.0
        else:
            reaction_expression[reaction.id] = None

    # Prepare reaction confidence scores
    reaction_confidence = {}
    for rxn_id, expr_value in reaction_expression.items():
        if expr_value is not None:
            if expr_value > transcript_data['expression_value'].quantile(0.75):
                score = 3
            elif expr_value > transcript_data['expression_value'].quantile(0.5):
                score = 2
            else:
                score = 1
            reaction_confidence[rxn_id] = score

    high_confidence_reactions = [rxn_id for rxn_id, score in reaction_confidence.items() if score == 3]

    # Choose integration algorithm
    algorithm = kwargs.get('algorithm', 'init')

    if algorithm == 'init':
        tissue_model = create_tissue_specific_model(model, high_confidence_reactions, algorithm='init')
    elif algorithm == 'fastcore':
        from cobra.flux_analysis import fastcore
        tissue_model = fastcore.fastcore(high_confidence_reactions, model)
    else:
        tissue_model = create_tissue_specific_model(model, high_confidence_reactions, algorithm='init')

    # Save the context-specific model
    cobra.io.write_sbml_model(tissue_model, 'output/context_specific_model.xml')
EOL

# New Task: Integrate with PROM
cat <<EOL > airflow/tasks/integrate_with_PROM.py
# tasks/integrate_with_PROM.py

def integrate_with_PROM(**kwargs):
    import cobra
    from db import session
    from models import TranscriptomicData
    # Placeholder for PROM implementation

    # Load the context-specific model
    model = cobra.io.read_sbml_model('output/context_specific_model.xml')

    # Fetch gene expression data
    transcript_data_entries = session.query(TranscriptomicData).all()
    gene_expression = {entry.gene_id: entry.expression_value for entry in transcript_data_entries}

    # Implement PROM integration
    # Note: PROM implementation requires specialized functions not available in COBRApy
    # Placeholder for actual implementation

    # Save the updated model
    cobra.io.write_sbml_model(model, 'output/prom_integrated_model.xml')
EOL

# New Task: Add Thermodynamic Constraints
cat <<EOL > airflow/tasks/add_thermodynamic_constraints.py
# tasks/add_thermodynamic_constraints.py

def add_thermodynamic_constraints(**kwargs):
    import cobra
    from pytfa import ThermodynamicModel
    from pytfa.io import load_thermoDB

    # Load the model
    model = cobra.io.read_sbml_model('output/prom_integrated_model.xml')

    # Load thermodynamic data
    thermo_data = load_thermoDB('data/thermo_data.tsv')

    # Convert to ThermodynamicModel
    tmodel = ThermodynamicModel(thermo_data, model)
    tmodel.prepare()
    tmodel.convert()

    # Optimize the thermodynamically constrained model
    solution = tmodel.optimize()

    # Save the model
    tmodel.solver.update()
    cobra.io.write_sbml_model(tmodel, 'output/thermo_constrained_model.xml')
EOL

# Task 6: Validate and Analyze the Model
cat <<EOL > airflow/tasks/validate_and_analyze_model.py
# tasks/validate_and_analyze_model.py

def validate_and_analyze_model(**kwargs):
    import cobra
    from db import session
    from models import AnalysisResults

    # Load the thermodynamically constrained model
    model = cobra.io.read_sbml_model('output/thermo_constrained_model.xml')

    # Perform FBA
    solution = model.optimize()

    # Perform FVA
    fva_results = cobra.flux_analysis.flux_variability_analysis(model)

    # Convert fluxes and FVA results to dictionaries
    fluxes_dict = solution.fluxes.to_dict()
    fva_dict = fva_results.to_dict()

    # Store results in the database
    analysis_result = AnalysisResults(
        objective_value=solution.objective_value,
        fluxes=fluxes_dict,
        fva_results=fva_dict
    )
    session.add(analysis_result)
    session.commit()
EOL

# New Task: Validate with Phenotypic Data
cat <<EOL > airflow/tasks/validate_with_phenotypic_data.py
# tasks/validate_with_phenotypic_data.py

def validate_with_phenotypic_data(**kwargs):
    import pandas as pd
    from db import session
    from models import PhenotypeData
    import cobra
    from scipy.stats import pearsonr

    # Load the model
    model = cobra.io.read_sbml_model('output/thermo_constrained_model.xml')

    # Fetch phenotype data
    phenotype_entries = session.query(PhenotypeData).all()
    phenotype_data = pd.DataFrame([{
        'condition': entry.condition,
        'growth_rate': entry.growth_rate
    } for entry in phenotype_entries])

    # Simulate conditions and compare
    simulation_results = []
    for _, row in phenotype_data.iterrows():
        condition = row['condition']
        experimental_growth = row['growth_rate']
        # Adjust model for the condition
        # Placeholder for condition adjustments
        solution = model.optimize()
        simulated_growth = solution.objective_value
        simulation_results.append({
            'Condition': condition,
            'Experimental_Growth': experimental_growth,
            'Simulated_Growth': simulated_growth
        })

    # Calculate correlation
    simulation_df = pd.DataFrame(simulation_results)
    corr, _ = pearsonr(simulation_df['Experimental_Growth'], simulation_df['Simulated_Growth'])

    print(f'Correlation between experimental and simulated growth rates: {corr}')
EOL

# New Task: Perform Cross-Validation
cat <<EOL > airflow/tasks/perform_cross_validation.py
# tasks/perform_cross_validation.py

def perform_cross_validation(**kwargs):
    from db import session
    from models import TranscriptomicData, CrossValidationResults
    import numpy as np
    from sklearn.model_selection import KFold

    # Load the model
    # Placeholder: Load your model here

    # Fetch gene expression data
    transcript_data_entries = session.query(TranscriptomicData).all()
    gene_ids = [entry.gene_id for entry in transcript_data_entries]
    expression_values = [entry.expression_value for entry in transcript_data_entries]
    data = np.array(expression_values)

    # Perform k-fold cross-validation
    kf = KFold(n_splits=5)
    fold = 1
    for train_index, test_index in kf.split(data):
        # Build and validate model
        # Placeholder for actual implementation

        # Calculate accuracy
        accuracy = np.random.rand()  # Placeholder for actual accuracy calculation

        # Store results
        cv_result = CrossValidationResults(
            fold=fold,
            accuracy=accuracy
        )
        session.add(cv_result)
        fold += 1

    session.commit()
EOL

# Task 7: Visualize and Report
cat <<EOL > airflow/tasks/visualize_and_report.py
# tasks/visualize_and_report.py

def visualize_and_report(**kwargs):
    from db import session
    from models import AnalysisResults
    import pandas as pd
    import dash
    from dash import html, dcc
    import plotly.express as px

    # Fetch the latest analysis result
    result = session.query(AnalysisResults).order_by(AnalysisResults.id.desc()).first()
    fluxes = pd.DataFrame(list(result.fluxes.items()), columns=['Reaction_ID', 'Flux'])

    # Create interactive dashboard
    app = dash.Dash(__name__)

    app.layout = html.Div([
        html.H1('Metabolic Flux Analysis'),
        dcc.Graph(
            figure=px.bar(fluxes.nlargest(20, 'Flux'), x='Reaction_ID', y='Flux', title='Top 20 Flux-Carrying Reactions')
        )
    ])

    # Run the app (Note: In production, you may want to deploy the app differently)
    app.run_server(debug=False, port=8050)
EOL

# Create empty logs directory
mkdir -p logs

echo "Enhanced project setup complete with all upgrades."
