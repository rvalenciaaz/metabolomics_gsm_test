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
