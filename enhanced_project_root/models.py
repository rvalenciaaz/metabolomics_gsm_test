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
