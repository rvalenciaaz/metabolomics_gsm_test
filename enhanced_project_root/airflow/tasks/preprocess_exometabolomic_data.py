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
