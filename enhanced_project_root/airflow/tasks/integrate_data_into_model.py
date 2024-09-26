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
