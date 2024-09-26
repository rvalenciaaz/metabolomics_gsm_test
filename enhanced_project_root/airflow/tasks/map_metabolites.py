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
