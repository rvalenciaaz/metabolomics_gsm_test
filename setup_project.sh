#!/bin/bash

# Set the project root directory
PROJECT_ROOT="project_root"

# Create the directory structure
mkdir -p $PROJECT_ROOT/{airflow/{dags,tasks},data,output,logs}

# Navigate to the project root directory
cd $PROJECT_ROOT

# Create empty data files (you can replace these with your actual data files)
touch data/exometabolomic_data.csv
touch data/transcriptomic_counts.csv
touch data/your_model.xml

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
EOL

# Create the utility functions script (utils.py)
cat <<EOL > utils.py
# utils.py

def map_metabolite(metabolite_name):
    """
    Map metabolite names to model metabolite IDs using external databases.
    Placeholder implementation.
    """
    # Implement actual mapping logic here
    model_metabolite_id = 'MNXM' + metabolite_name  # Simplified example
    return model_metabolite_id

def get_go_terms(gene_id):
    """
    Retrieve GO terms for a given gene ID using external databases.
    Placeholder implementation.
    """
    # Implement actual retrieval logic here
    go_terms = ['GO:0008150']  # Biological Process
    return go_terms
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
from tasks.validate_and_analyze_model import validate_and_analyze_model
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
    description='Workflow for metabolic model integration using Airflow',
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
    dag=dag,
)

validate_analyze_task = PythonOperator(
    task_id='validate_and_analyze_model',
    python_callable=validate_and_analyze_model,
    dag=dag,
)

visualize_report_task = PythonOperator(
    task_id='visualize_and_report',
    python_callable=visualize_and_report,
    dag=dag,
)

# Set task dependencies
preprocess_exo_task >> preprocess_transcript_task >> map_metabolites_task >> map_genes_task >> integrate_data_task >> validate_analyze_task >> visualize_report_task
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

    # Load raw data from a source (e.g., CSV file)
    exo_data = pd.read_csv('data/exometabolomic_data.csv')

    # Normalize concentrations
    exo_data['Normalized_Concentration_Start'] = exo_data['Concentration_Start'] / exo_data['Cell_Density']
    exo_data['Normalized_Concentration_End'] = exo_data['Concentration_End'] / exo_data['Cell_Density']

    # Calculate uptake/secretion rates
    exo_data['Rate'] = (exo_data['Normalized_Concentration_End'] - exo_data['Normalized_Concentration_Start']) / exo_data['Time']

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

    # Load raw count data
    transcript_data = pd.read_csv('data/transcriptomic_counts.csv')

    # Insert processed data into the database
    for _, row in transcript_data.iterrows():
        data_entry = TranscriptomicData(
            gene_id=row['Gene_ID'],
            expression_value=row['Expression_Value'],
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

    # Fetch exometabolomic data from the database
    exo_data = session.query(ExometabolomicData).all()

    for data_entry in exo_data:
        # Perform mapping
        model_metabolite_id = map_metabolite(data_entry.metabolite)
        data_entry.model_metabolite_id = model_metabolite_id

        # Update or insert into metabolite mappings table
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

    # Fetch transcriptomic data from the database
    transcript_data = session.query(TranscriptomicData).all()

    for data_entry in transcript_data:
        # Perform mapping
        go_terms = get_go_terms(data_entry.gene_id)

        # Update or insert into gene mappings table
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

    # Use the INIT algorithm
    from cobra.flux_analysis import create_tissue_specific_model

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

    # Create context-specific model
    tissue_model = create_tissue_specific_model(model, high_confidence_reactions, algorithm='init')

    # Save the context-specific model
    cobra.io.write_sbml_model(tissue_model, 'output/context_specific_model.xml')
EOL

# Task 6: Validate and Analyze the Model
cat <<EOL > airflow/tasks/validate_and_analyze_model.py
# tasks/validate_and_analyze_model.py

def validate_and_analyze_model(**kwargs):
    import cobra
    from db import session
    from models import AnalysisResults

    # Load the context-specific model
    model = cobra.io.read_sbml_model('output/context_specific_model.xml')

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

# Task 7: Visualize and Report
cat <<EOL > airflow/tasks/visualize_and_report.py
# tasks/visualize_and_report.py

def visualize_and_report(**kwargs):
    from db import session
    from models import AnalysisResults
    import pandas as pd
    import plotly.express as px

    # Fetch the latest analysis result
    result = session.query(AnalysisResults).order_by(AnalysisResults.id.desc()).first()

    # Load fluxes into a DataFrame
    fluxes = pd.DataFrame(list(result.fluxes.items()), columns=['Reaction_ID', 'Flux'])

    # Generate a bar chart of flux distributions
    fig = px.bar(fluxes.nlargest(20, 'Flux'), x='Reaction_ID', y='Flux', title='Top 20 Flux-Carrying Reactions')
    fig.write_html('output/flux_distribution.html')
EOL

# Create empty logs directory
mkdir -p logs

echo "Project setup complete."
